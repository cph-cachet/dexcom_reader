import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader_example/StateStorage/state_storage_service.dart';
import 'package:dexcom_reader_example/models/dexdevice.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Future<void> scanAndReadDevices() async {
    print("scan for Dexcom devices...");
    if (!isScanning) {
      setState(() => isScanning = true);
      while (autoScan) {
        bool scanning = false;
        while (!scanning) {
          try {
            dexcomReader.scanForAllDexcomDevices();

            // Listen for the next 300 seconds
            await dexDeviceScanningSubscription?.cancel();
            await Future.delayed(Duration(milliseconds: 50));
            dexDeviceScanningSubscription = dexcomReader.deviceStream.listen(
              (btDexDevices) {
                setState(() {
                  print(
                      "deviceStream adding: ${btDexDevices.toList().toString()}");
                  scannedDevices = btDexDevices;
                });
              },
              onError: (error) {
                print("Error listening to device stream: $error");
              },
            );
            await Future.delayed(Duration(seconds: 300));
            await dexcomReader.disconnect();
            scanning = true;
          } catch (e) {
            print("Scanning failed: $e");
          }
        }
      }
      setState(() => isScanning = false);
    }
    setState(() => isScanning = false);
    dexcomReader.disconnect();
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
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: Column(
          children: [
            Container(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Device: ${dexDevice.platformName.isEmpty ? dexDevice.advName : dexDevice.platformName}",
                    style: GoogleFonts.roboto(
                        fontSize: dexDevice.platformName.isEmpty ? 14 : 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4), // Add some spacing between the texts
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Tap to store this device for monitoring and for connecting later",
                    style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.withOpacity(0.7),
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
            Container(
              height: 2,
              color: Colors.grey,
            ),
          ],
        ),
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
