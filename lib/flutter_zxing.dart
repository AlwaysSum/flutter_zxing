import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

class FlutterZxing {
  static const MethodChannel _channel = MethodChannel('flutter_zxing');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// parse code by bytes
  static Future<String?> decodeImageByte(
      Uint8List data, int width, int height) async {
    //IOS need encode to JPG
    if (Platform.isIOS) {
      imglib.Image img = imglib.Image.fromBytes(width, height, data);
      List<int> imgByte = imglib.encodeJpg(img);
      data = Uint8List.fromList(imgByte);
    }
    final String? code = await _channel.invokeMethod('decodeImageByte', {
      'data': data,
      'width': width,
      'height': height,
    });
    return code;
  }

  ///parse code by image path
  static Future<String?> decodeImagePath(String path) async {
    final String? code =
        await _channel.invokeMethod('decodeImageByte', {'data': path});
    return code;
  }
}
