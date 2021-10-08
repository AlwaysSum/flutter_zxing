import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter_zxing_example/scan_scene.dart';

late final List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (ctx) => const MyApp(),
      '/scan': (ctx) => const ScanScene(),
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin flutter zxing'),
      ),
      body: Center(
        child: InkWell(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(12)),
            child: const Icon(
              Icons.camera,
              size: 120,
              color: Colors.white,
            ),
          ),
          onTap: () => Navigator.pushNamed(context, "/scan"),
        ),
      ),
    );
  }
}
