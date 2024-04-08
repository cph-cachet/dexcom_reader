import 'dart:ffi';
import 'dart:io';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanner extends StatefulWidget {
  @override
  _BleScannerState createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  DexcomG7Reader dexService = DexcomG7Reader();

  List<BluetoothDevice> devices = [];
  Map<String, List<BluetoothCharacteristic>> deviceCharacteristics = {};

  @override
  void initState() {
    super.initState();
    // Before using the plugin you must first have given permission to using bluetooth/Flutter blue plus.
    // This can also be added to the DexcomG7Reader API
    _checkBluetoothPermission();
    startScanning();
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.status;
    if (status.isDenied) {
      await Permission.bluetooth.request();
    }
  }

  Future<BluetoothDevice?> startScanning() async {
    DexcomG7Reader dexReader = DexcomG7Reader(); // Initialise plugin
    BluetoothDevice? dexDevice;
    print("Calling DexComG7Reader plugin method");

    dexDevice = await dexReader.scanForDexDevice();

    setState(() {
      devices.add(dexDevice!);
    });

    dexDevice != null ? await dexReader.connectToDexDevice(dexDevice) : null; // If a dexcom device is found, connect to it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BLE Scanner'),
        ),
        body: Visibility(
          visible: devices.isNotEmpty,
          replacement: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text("Currently searching for Dexcom Sensor"),
                Text("G7 only sends a signal every 5 minutes...")
              ],
            ),
          ),
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              BluetoothDevice device = devices[index];
              return InkWell(
                onTap: () async {},
                child: ListTile(
                  title: Text(device.platformName),
                  subtitle: Text(device.remoteId.toString()),
                ),
              );
            },
          ),
        ));
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
