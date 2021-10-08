import Flutter
import UIKit
import Vision

public class SwiftFlutterZxingPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_zxing", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterZxingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
     if call.method=="getPlatformVersion" {
       result("iOS " + UIDevice.current.systemVersion)
     } else if call.method=="decodeImagePath" {
       guard let args = call.arguments as? [String: Any] else {
                     result("iOS could not recognize flutter arguments in method: (postMessage)")
                     return
                 }
       if let path = args["data"] as? String,
          let features = self.detectQRCode(UIImage.init(contentsOfFile: path)) {
           if !features.isEmpty{
             let data = features.first as! CIQRCodeFeature
             result(data.messageString);
           }else{
               self.detectBarCode(UIImage.init(contentsOfFile: path), result: result)
           }
       } else {
           result("");
       }
     }else if call.method=="decodeImageByte"{
         // IOS待实现通过Byte解析
         guard let args = call.arguments as? [String: Any] else {
                       result("iOS could not recognize flutter arguments in method: (postMessage)")
                       return
                   }
         
         if let bytes = args["data"] as? FlutterStandardTypedData {
//             let imgStr = bytes.data.base64EncodedString();
//             let imgByte =  NSData(base64Encoded: bytes.data.base64EncodedData(), options: NSData.Base64DecodingOptions.ignoreUnknownCharacters);
//             let rgbaUint8 = [UInt8](bytes.data);
//             let imgByte = NSData(bytes: rgbaUint8, length: rgbaUint8.count);
             guard let image = UIImage(data: bytes.data) else {
               result("IOS 暂不支持扫码服务 2");
               return
             }
             self.detectBarCode(image, result: result)
         } else {
           result("IOS 暂不支持扫码服务 1");
         }
     }
  }
    
    
 private func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
   if let image = image, let ciImage = CIImage.init(image: image){
     var options: [String: Any];
     let context = CIContext();
     options = [CIDetectorAccuracy: CIDetectorAccuracyHigh];
     let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options);
     if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
       options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1];
     } else {
       options = [CIDetectorImageOrientation: 1];
     }
     let features = qrDetector?.features(in: ciImage, options: options);
     return features;
   }
   return nil
 }
 
 private func detectBarCode(_ image: UIImage?, result: @escaping FlutterResult) {
   if let image = image, let ciImage = CIImage.init(image: image), #available(iOS 11.0, *) {
     var requestHandler: VNImageRequestHandler;
     if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)) {
       requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation(rawValue: ciImage.properties[(kCGImagePropertyOrientation as String)] as! UInt32) ?? .up, options: [:])
     } else {
       requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .up, options: [:])
     }
     let request = VNDetectBarcodesRequest { (request,error) in
       var res: String? = nil;
       if let observations = request.results as? [VNBarcodeObservation], !observations.isEmpty {
         let data: VNBarcodeObservation = observations.first!;
         res = data.payloadStringValue;
       }
       DispatchQueue.main.async {
         result(res);
       }
     }
     DispatchQueue.global(qos: .background).async {
       do{
         try requestHandler.perform([request])
       } catch {
         DispatchQueue.main.async {
           result(nil);
         }
       }
     }
   } else {
     result(nil);
   }
 }
    
}
