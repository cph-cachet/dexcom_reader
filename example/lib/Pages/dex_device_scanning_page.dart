import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader_example/Components/dexcom_device_card.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
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
  final StateStorageService stateStorageService = StateStorageService();
  BluetoothDevice? latestDexcomDevice;
  bool isScanning = false;
  List<BluetoothDevice> scannedDevices = [];
  StreamSubscription<List<BluetoothDevice>>? dexDeviceScanningSubscription;

  Future<void> scanAndReadDevices() async {
    print("Scanning for devices");
    if (!isScanning) {
      setState(() => isScanning = true);
      print("Now loading, isScanning: $isScanning");
      bool foundDevices = false;
      while (!foundDevices) {
        try {
          print("Scanning for devices");
          await dexcomReader.scanForAllDexcomDevices();
          print("Setting up listener");
          dexDeviceScanningSubscription =
              dexcomReader.deviceStream.distinct().listen((btDexDevices) {
            setState(() {
              scannedDevices = btDexDevices;
              foundDevices = true;
            });
          });
        } catch (e) {}
      }
    }
    setState(() => isScanning = false);
  }

  Future<void> addAndReadDevice(String deviceIdentifier) async {
    if(!isScanning) {
      setState(() => isScanning = true);
      bool foundDevice = false;
      while (!foundDevice) {
        try {
          dexcomReader.connectWithId(deviceIdentifier);
          dexDeviceScanningSubscription = dexcomReader.deviceStream.listen((devicesStream)  {

          });
        }
        catch (e) {}
      }
    }
    setState(() => isScanning = false);
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
