import 'package:flutter/material.dart';

class ScanButton extends StatelessWidget {
  bool isScanning;
  VoidCallback func;

  ScanButton({super.key, required this.isScanning, required this.func});

  @override
  Widget build(BuildContext context) {
    String buttonTxt = isScanning ? "Stop Scan" : "Scan for Device";
    return Container(
      decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16.0)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: TextButton(
          onPressed: func,
          child: Text(
            buttonTxt,
            style: TextStyle(color: Colors.black, fontSize: 18),
          )),
    );
  }
}
