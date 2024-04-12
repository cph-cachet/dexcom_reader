import 'dart:io';

import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader_example/Components/scan_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanner extends StatefulWidget {
  @override
  _BleScannerState createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  DexcomG7Reader dexService = DexcomG7Reader();

  BluetoothDevice? _dexDevice;
  List<BluetoothDevice> devices = [];
  DexGlucosePacket? latestGlucosePacket;

  PermissionStatus btePermissionStatus = PermissionStatus.denied;
  bool isScanning = false;

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

  //Todo: Clean startScanning code and the Flutter widgets for this page
  Future<BluetoothDevice?> startScanning() async {
    DexcomG7Reader dexReader = DexcomG7Reader(); // Initialise plugin
    BluetoothDevice? dexDevice;
    dexDevice = await dexReader.scanForDexDevice();

    setState(() {
      devices.add(
          dexDevice!); // May not be used depending on if we want to read multiple dexcom devices?'
      _dexDevice = dexDevice;
    });

    _dexDevice != null
        ? await dexReader.connectToDexDevice(_dexDevice!)
        : null; // If a dexcom device is found, connect to it
    DexGlucosePacket? packet = await dexService.getLatestGlucosePacket();
    setState(() {
      if (packet != null) {
        latestGlucosePacket = packet;
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
            Visibility(
                visible: _dexDevice != null && latestGlucosePacket != null,
                replacement: Container(),
                child: dexGlucosePacketTile()),
            scanningBody()
          ],
        ));
  }

  Widget dexGlucosePacketTile() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Add some spacing between the top of the card and the title
          Container(height: 5),
          // Add a title widget

          Text(
              _dexDevice != null ? _dexDevice!.platformName : "No Device Found",
              style: TextStyle(color: Colors.grey.shade100)),
          // Add some spacing between the title and the subtitle
          Container(height: 5),
          // Add a subtitle widget
          Text(
            "Glucose: ${latestGlucosePacket != null ? latestGlucosePacket!.glucose : ""} mmol/L",
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          // Add some spacing between the subtitle and the text
          Container(height: 10),
          // Add a text widget to display some text
          Text(
            latestGlucosePacket != null
                ? "Trend: ${latestGlucosePacket!.trend}"
                : "No trend data",
            maxLines: 2,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          Container(
            height: 10,
          ),
          Text(
            latestGlucosePacket != null
                ? "Timestamp: ${dexService.convertTimeStampToDatetime(latestGlucosePacket!.timestamp)}"
                : "No trend data",
            maxLines: 2,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // This widget contains the Currently scanning or press to scan text with a start/stop scan button
  Widget scanningBody() {
    return Center(
      child: Column(
        children: [
          Visibility(
            visible: isScanning && !btePermissionStatus.isGranted,
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
