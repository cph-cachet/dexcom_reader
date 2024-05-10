import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionService {
  Future<void> checkBluetoothPermission(PermissionStatus _status) async {
    var status = await Permission.bluetooth.status;
    if (status.isDenied) {
      _status = await Permission.bluetooth.request();
    }
  }
}