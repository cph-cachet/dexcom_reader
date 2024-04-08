
import 'dart:io';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//TODO:
/// Create a clean interface and corresponding API for the DexcomService
/// GetGlucoseData()
/// GetBatteryData()
/// GetOtherData()
class DexScanningService {
  final int opcode = 0x4e; // This is 78 which the first element of the glucose packet should read.
  BluetoothDevice? device;
  Map<String, List<BluetoothCharacteristic>> deviceCharacteristics = {};

  void scanForDexDevice() async {
    await FlutterBluePlus.startScan();
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.platformName.contains("DXC")) {
          device = result.device;
          print("Dexcom Device found:");
          print(result.device.toString());
          print("");
          await connectToDexcomDevice(result.device);
        }
      }
    });
  }

  Future<void> connectToDexcomDevice(BluetoothDevice device) async {
    await device.connect(); // Connect to the device
    try {
      if (Platform.isAndroid) {
        int desiredMtu = 517; // Arbitrary MTU, will be changed when testing for Android
        // Request a specific MTU size (Android only)
        int actualMtu = await device.requestMtu(desiredMtu);
        //print('MTU size set to $actualMtu');
      }

      // Listen for MTU updates
      device.mtu.listen((mtu) {});

      //TODO: Implement a StateStorageService that can fetch the previously saved Dexcom UUID's for subscribing to service and automatically clear old devices when adding a new one after scan
      // Assuming you know the service and characteristic UUIDs
      Guid serviceUuid = Guid("0000180a-0000-1000-8000-00805F9B34FB");
      Guid remoteId = Guid("f8083532-849e-531c-c594-30f1f86a4ea5");
      Guid? secondaryServiceUuid = null;
      Guid characteristicUuid = Guid("00002a29-0000-1000-8000-00805F9B34FB");

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            try {
              await characteristic.setNotifyValue(true);
              characteristic.onValueReceived.listen((data) {
                if (data.length >= 19) {
                  //print('Received data from ${characteristic.uuid}: $data');
                  print('Received data: $data');
                  // Assuming 'data' is already a Uint8List; if not, convert it.
                  Uint8List packet = Uint8List.fromList(data);
                  decodeData(packet);
                  //print("Calling decode constructor:");
                  //EGlucoseRxMessage(packet);
                }
              });
            } catch (e) {
              print('Error setting notify value: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error interacting with device: $e');
    }
  }

  void decodeData(Uint8List packet) {
    EGlucoseRxMessage(packet);
  }
}