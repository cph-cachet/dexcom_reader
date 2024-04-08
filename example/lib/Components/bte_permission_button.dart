import 'package:flutter/material.dart';

class BTEPermissionButton extends StatelessWidget {
  VoidCallback func;

  BTEPermissionButton({super.key, required this.func});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16.0)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: TextButton(
          onPressed: func,
          child: Text(
            "Request Bluetooth Permission",
            style: TextStyle(color: Colors.black, fontSize: 18),
          )),
    );
  }
}
