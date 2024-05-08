import 'dart:io';

import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader_example/Components/bte_scanning_widget.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
import 'package:dexcom_reader_example/Components/scan_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanner extends StatefulWidget {
  const BleScanner({super.key});

  @override
  _BleScannerState createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  DexcomReader dexService = DexcomReader();
  DexGlucosePacket? latestGlucosePacket;
  PermissionStatus btePermissionStatus = PermissionStatus.denied;
  bool isScanning = false;
  List<BluetoothDevice> devices = [
    BluetoothDevice(remoteId: DeviceIdentifier("1234567890")),
    BluetoothDevice(remoteId: DeviceIdentifier("0987654321"))
  ];

  @override
  void initState() {
    super.initState();
    // Before using the plugin you must first have given permission to using bluetooth/Flutter blue plus.
    _checkBluetoothPermission();
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.status;
    if (status.isDenied) {
      PermissionStatus status = await Permission.bluetooth.request();
      setState(() {
        btePermissionStatus = status;
      });
    }
  }

  void scanButtonFunc() {
    setState(() {
      isScanning = !isScanning;
    });
    if (isScanning) {
      startScanning();
    } else {
      FlutterBluePlus.stopScan();
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<BluetoothDevice?> startScanning() async {
    List<BluetoothDevice> dexDevices = [];
    var devices = await dexService.getScannedDexcomDevices();

    setState(() {
      dexDevices = devices;
    });

    DexGlucosePacket? packet = null; // TODO: Implement
    setState(() {
      if (packet != null) {
        latestGlucosePacket = packet;
        isScanning = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BLE Scanner'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            deviceListView(),
            BTEScanningWidget(isScanning: isScanning, permissionStatus: btePermissionStatus, scanButtonFunc: scanButtonFunc)
          ],
        ));
  }

  Widget deviceListView(){
    return ListView.builder(
      shrinkWrap: true,
      itemCount: devices.isNotEmpty ? devices.length : 0,
      itemBuilder: (BuildContext context, int index) {
        if (devices.isEmpty) {
          return Container(); // Acts as the replacement when there are no devices
        } else {
          return DexcomDeviceCard(
              latestGlucosePacket: latestGlucosePacket,
              dexDevice: devices[index]); // Builds a tile for each device
        }
      },
    );
  }
}
