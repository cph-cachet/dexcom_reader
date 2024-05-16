import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../Components/bte_scanning_widget.dart';

class DexDeviceScanningPage extends StatefulWidget {
  const DexDeviceScanningPage({super.key});

  @override
  State<DexDeviceScanningPage> createState() => _DexDeviceScanningPageState();
}

class _DexDeviceScanningPageState extends State<DexDeviceScanningPage> {
  final DexcomReader dexcomReader = DexcomReader();
  bool isScanning = false;
  bool autoScan = true;
  List<BluetoothDevice> scannedDevices = [];
  StreamSubscription<List<BluetoothDevice>>? dexDeviceScanningSubscription;

  @override
  void initState() {
    super.initState();
    //subscribeToDevicesStream();
  }

  Future<void> scanAndReadDevices() async {
    print("SubscribeToStream starting connection attempts... $isScanning");
    if (!isScanning) {
      setState(() => isScanning = true);
      while (autoScan) {
        bool connected = false;
        while (!connected) {
          try {
            await dexcomReader.scanForAllDexcomDevices();
            connected = true;
          } catch (e) {
            print("Scanning failed: $e");
          }
        }

        if (connected) {
          dexDeviceScanningSubscription?.cancel();
          dexDeviceScanningSubscription =
              dexcomReader.deviceStream.listen((btDexDevices) {
            setState(() {
              scannedDevices = btDexDevices;
            });
          });
        }
      }
      await dexcomReader.disconnect(); // Important remember to clean the controllers.
    } else {
      setState(() => isScanning = false);
    }
  }

  @override
  void dispose() {
    dexDeviceScanningSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(flex: 4, child: deviceListView()),
        Expanded(
          flex: 2,
          child: DexcomSubscribeToDeviceWidget(
            isScanning: isScanning,
            scanButtonFunc: scanAndReadDevices,
          ),
        ),
      ],
    );
  }

  Widget deviceListView() {
    if (scannedDevices.isEmpty) {
      return Center(child: Text("No devices found"));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: scannedDevices.length,
        itemBuilder: (BuildContext context, int index) {
          return DexcomDeviceCard(
            latestGlucosePacket: null,
            dexDevice: scannedDevices[index],
          );
        },
      );
    }
  }
}

/*
Future<void> addAndReadDevice(String deviceIdentifier) async {
    if (!isScanning) {
      setState(() => isScanning = true);
      bool foundDevice = false;
      while (!foundDevice) {
        try {
          dexcomReader.connectWithId(deviceIdentifier);
          dexDeviceScanningSubscription =
              dexcomReader.deviceStream.listen((devicesStream) {});
        } catch (e) {}
      }
    }
    setState(() => isScanning = false);
  }
 */
