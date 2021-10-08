import 'package:flutter/material.dart';
import 'package:flutter_zxing_example/qrscan_view.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'main.dart';

class ScanScene extends StatefulWidget {
  const ScanScene({Key? key}) : super(key: key);

  @override
  _ScanSceneState createState() => _ScanSceneState();
}

class _ScanSceneState extends State<ScanScene> {
  late QRScanController qrcodeController = QRScanController(
    onQRCode: (code) => Fluttertoast.showToast(msg: "扫码结果:$code"),
    cameraDescription: cameras.first,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRScanView(scanController: qrcodeController),
          Positioned(
              child: OutlinedButton.icon(
            onPressed: () {
              Fluttertoast.showToast(msg: "拍照");
            },
            icon: const Icon(Icons.flash_on,color: Colors.yellow,),
            label: const Text("拍照"),
          ))
        ],
      ),
    );
  }
}
