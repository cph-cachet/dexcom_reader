import 'package:dexcom_reader_example/Components/scan_button.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DexcomSubscribeToDeviceWidget extends StatelessWidget {
  final bool isScanning;
  final VoidCallback scanButtonFunc;

  const DexcomSubscribeToDeviceWidget({
    Key? key,
    required this.isScanning,
    required this.scanButtonFunc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("scanning widget wussup $isScanning");
    return Center(
      child: Column(
        children: [
          Visibility(
            visible: isScanning,
            replacement: ScanButton(
              isScanning: isScanning,
              func: scanButtonFunc,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const Text("Currently searching for Dexcom Sensor"),
                  const Text("G7 only sends a signal every 5 minutes..."),
                  ScanButton(
                    isScanning: isScanning,
                    func: scanButtonFunc,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
