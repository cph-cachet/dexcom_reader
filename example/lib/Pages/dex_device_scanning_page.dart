import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:dexcom_reader_example/models/dexdevice.dart';
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
  }

  Future<void> scanForDevices() async {
    if (!isScanning) {
      setState(() => isScanning = true);
      while (autoScan) {
        // The device will scan indefinitely for Dexcom devices until the autoScan state is changed by pressing the stop scan button
        try {
          dexcomReader
              .scanForAllDexcomDevices(); // We dont wait for this method, we will just setup a subscription to the device stream in scanForAllDexcomDevices() instead
          await dexDeviceScanningSubscription?.cancel();
          await Future.delayed(Duration(milliseconds: 50));
          dexDeviceScanningSubscription = dexcomReader.deviceStream.listen(
            (btDexDevices) {
              setState(() {
                scannedDevices = btDexDevices;
              });
            },
            onError: (error) {
              print("Error listening to device stream: $error");
            },
          );
        } catch (e) {
          print("Scanning failed: $e");
        } finally {
          dexcomReader.disconnect();
          setState(() => isScanning = false);
        }
      }
    }
  }

  @override
  void dispose() {
    dexDeviceScanningSubscription?.cancel();
    dexcomReader.disconnect();
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
            scanButtonFunc: scanForDevices,
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
          return dexBTDeviceCard(
            scannedDevices[index],
          );
        },
      );
    }
  }

  Widget dexBTDeviceCard(BluetoothDevice dexDevice) {
    return InkWell(
      onTap: () {
        StateStorageService stateStorageService = StateStorageService();
        stateStorageService.saveDexcomDevice(DexDevice(
            remoteId: dexDevice.remoteId,
            platformName: dexDevice.platformName));
        /*
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DexGlucoseListenPage(),
          ),
        );
         */
      },
      child: ListTile(
        title: Text("G7 Device: ${dexDevice.platformName}"),
        subtitle: Text("BTE remoteID: ${dexDevice.remoteId.str}"),
      ),
    );
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
