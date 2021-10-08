import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as imglib;

typedef OnQRCode = Future<void> Function(String qrcode);

class QRScanController {
  final OnQRCode onQRCode;
  final CameraDescription cameraDescription;

  CameraController? controller;

  QRScanController({required this.onQRCode, required this.cameraDescription});

  void setFlashMode(bool isOpen) {
    if (controller != null && controller!.value.isInitialized) {
      if (isOpen) {
        controller!
            .setFlashMode(FlashMode.torch)
            .catchError((e) => Fluttertoast.showToast(msg: "设备不支持闪光灯"));
      } else {
        controller!
            .setFlashMode(FlashMode.off)
            .catchError((e) => Fluttertoast.showToast(msg: "设备不支持闪光灯"));
      }
    }
  }

  Future<void> pause() async {
    if (controller != null && controller!.value.isInitialized) {
      return controller!.pausePreview();
    }
  }

  Future<void> resume() async {
    if (controller != null && controller!.value.isInitialized) {
      return controller!.resumePreview();
    }
  }
}

class QRScanView extends StatefulWidget {
  const QRScanView({Key? key, required this.scanController}) : super(key: key);

  @override
  _ScanViewState createState() => _ScanViewState();

  final QRScanController scanController;
}

class _ScanViewState extends State<QRScanView> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // onNewCameraSelected();
    //初始化
    WidgetsBinding.instance!.addObserver(this); //添加观察者

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.scanController.cameraDescription,
      // Define the resolution to use.
      ResolutionPreset.medium,
      // imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );
    widget.scanController.controller = _controller;
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize().whenComplete(() {
      widget.scanController.setFlashMode(false);
      // if (Platform.isIOS) {
      //   _controller.lockCaptureOrientation(DeviceOrientation.landscapeRight);
      // }
    });
    //---启动流
    startImageStream().catchError((e) {
      print("启动扫码失败:$e");
      Fluttertoast.showToast(msg: "启动扫码失败");
    });
    //---监听流
    _codeStreanSubscription = _codeStream.stream.listen((code) {
      _codeStreanSubscription.pause(Future.delayed(const Duration(seconds: 1)));
      widget.scanController.onQRCode(code);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final cameraController = _controller;
    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected();
    }
  }

  void onNewCameraSelected() async {
    final previousCameraController = _controller;
    // Instantiating the camera controller
    final cameraController = CameraController(
      widget.scanController.cameraDescription,
      ResolutionPreset.medium,
      // imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );
    // Dispose the previous controller
    await previousCameraController.dispose();
    // Replace with the new controller
    if (mounted) {
      setState(() {
        _controller = cameraController;
        widget.scanController.controller = _controller;
        _initializeControllerFuture = _controller.initialize().whenComplete(() {
          widget.scanController.setFlashMode(false);
          // if (Platform.isIOS) {
          //   cameraController
          //       .lockCaptureOrientation(DeviceOrientation.landscapeRight);
          // }
        });
      });
      await startImageStream().catchError((e) {
        print("启动扫码失败:$e");
        Fluttertoast.showToast(msg: "启动扫码失败");
      });
    }
  }

  final StreamController<String> _codeStream = StreamController();
  late StreamSubscription<String> _codeStreanSubscription;

  Future<void> startImageStream() async {
    await _initializeControllerFuture;

    await _controller.startImageStream((image) {
      print('获取到图片:${image.width}  ${image.height}');
      // print('获取到图片:${data}');
      if (_codeStream.hasListener && !_codeStream.isPaused) {
        Uint8List data = image.planes[0].bytes;
        FlutterZxing.decodeImageByte(data, image.width, image.height)
            .then((code) {
          if (code != null && code != "") {
            _codeStream.add(code);
            widget.scanController.onQRCode(code);
          }
        });
      }
    }).onError((error, stackTrace) => _controller.stopImageStream());
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    _codeStream.close();
    WidgetsBinding.instance!.removeObserver(this); //添加观察者
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final size = MediaQuery.of(context).size;
          final deviceRatio = size.width / size.height;
          // If the Future is complete, display the preview.
          return Center(
            child: Transform.scale(
              scale: deviceRatio / _controller.value.aspectRatio,
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller),
              ),
            ),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Container();
        }
      },
    );
  }
}
