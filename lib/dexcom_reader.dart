import 'dart:async';
import 'dart:io';
import 'package:dexcom_reader/plugin/interfaces/dexcom_g7_reader_interface.dart';
import 'package:flutter/services.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

import 'plugin/StateStorage/state_storage_service.dart';
import 'plugin/g7/DexGlucosePacket.dart';

/// Create a clean interface and corresponding API for the DexcomService
/// GetBatteryData()
/// GetOtherData()

class DexcomG7Reader implements IDexcomG7Reader {
  static const MethodChannel _channel = MethodChannel('my_plugin');
  final int opcode =
      0x4e; // This is 78 which the first element of the glucose packet should read.
  BluetoothDevice? device;
  Map<String, List<BluetoothCharacteristic>> deviceCharacteristics = {};

  @override
  Future<String> getPlatformVersion() async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// ScanForDexDevice()
  /// This method returns a BluetoothDevice that corresponds to a Dexcom G7. Once the caller gets a non-null BluetoothDevice, use it to call ConnectToDexDevice()
  @override
  Future<BluetoothDevice?> scanForDexDevice() async {
    BluetoothDevice? foundDevice;
    List<BluetoothDevice> scannedDevices =
        []; // List to keep track of found Dexcom devices
    var completer = Completer<BluetoothDevice?>();

    await FlutterBluePlus.startScan();
    late StreamSubscription subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (!scannedDevices.contains(result.device) &&
            result.device.platformName.contains("DXC")) {
          foundDevice = result.device;
          scannedDevices
              .add(result.device); // Add device to scanned devices list
          await FlutterBluePlus.stopScan();
          subscription.cancel(); // Stop listening to scan results
          completer
              .complete(foundDevice); // Complete the future with found device
          break; // Exit the for loop
        }
      }
    });
    var bteTimeout = const Duration(
        seconds:
            330); // G7 emits a series of MTU packets every 300 seconds or so
    // If the device is not found within a certain timeout, stop the scan and complete the future with null.
    Future.delayed(bteTimeout).then((_) async {
      if (!completer.isCompleted) {
        await FlutterBluePlus.stopScan();
        subscription.cancel();
        completer.complete(null);
      }
    });
    return completer
        .future; // Return the future that completes when the device is found or the timeout occurs
  }
  /// connectToDexDevice()
  /// This method connects to a Dexcom Device when possible and reads the relevant MTU packet
  @override
  Future<void> connectToDexDevice(BluetoothDevice device) async {
    await device.connect(); // Connect to the device
    try {
      if (Platform.isAndroid) {
        // Request a specific MTU size (Android only)
        int desiredMtu =
            517; // Arbitrary MTU size, will be changed when testing for Android
        int actualMtu = await device.requestMtu(desiredMtu);
      }

      // Listen for MTU updates
      device.mtu.listen((mtu) {});

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            try {
              await characteristic.setNotifyValue(true);
              late StreamSubscription subscription;
              subscription = characteristic.onValueReceived.listen((data) async {
                // Check if the length of the packet corresponds with the Glucose MTU Packet (Dexcom G7 sends 4 differently sized packets at a time)
                if (data.length == 19) {
                  Uint8List packet = Uint8List.fromList(data);
                  await decodeGlucosePacket(packet);

                  if(subscription != null){
                    await subscription.cancel();
                  }
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

  /// DecodeGlucosePacket()
  /// This method takes a Dexcom packet with an adequate length and converts it into readable data, for example:
  /// [78, 0, 207, 74, 13, 0, 90, 11, 0, 1, 6, 0, 102, 0, 6, 251, 93, 0, 15] =>
  /// {"statusRaw":0,"glucoseRaw":102,"glucose":5.6,"clock":871119,"timestamp":1712909742781,"unfiltered":0,"filtered":0,"sequence":2906,"glucoseIsDisplayOnly":false,"state":6,"trend":-0.5,"age":6,"valid":true}
  @override
  Future<void> decodeGlucosePacket(Uint8List packet) async {
    EGlucoseRxMessage data = EGlucoseRxMessage(packet);
    StateStorageService storageService = StateStorageService();
    print("Decoding packet: $packet");
    final DexGlucosePacket dexGlucosePacket = DexGlucosePacket(
        data.statusRaw,
        data.glucose, // this is glucoseRaw in constructor
        convertReadValToGlucose(data.glucose), // glucose is the value converted from glucoseRaw
        data.clock,
        data.timestamp,
        data.unfiltered,
        data.filtered,
        data.sequence,
        data.glucoseIsDisplayOnly,
        data.state,
        data.trend,
        data.age,
        data.valid);

    // Save data in various forms. Perhaps it should only be saved as .saveDexGlucosePacket (simplest and most logical flow)
    await storageService.saveDexGlucosePacket(dexGlucosePacket);
    await storageService.addDexGlucosePacket(dexGlucosePacket); // Adds the glucose packet / measurement to a list of all measurements. Can be useful as storing only the latest value is limiting
  }

  @override
  Future<DexGlucosePacket?> getLatestGlucosePacket() async {
    StateStorageService storageService = StateStorageService();
    return await storageService.getLatestDexGlucosePacket();
  }

  /// GetLatestGlucose()
  /// This method calls the service for SharedPreferences and fetches the latest glucose measurement stored in the apps state storage
  @override
  Future<double?> getLatestGlucose() async {
    StateStorageService storageService = StateStorageService();
    return await storageService.getLatestGlucoseLevel();
  }

  /// GetLatestGlucose()
  /// This method calls the service for SharedPreferences and fetches the latest glucose measurement stored in the apps state storage
  @override
  Future<double?> getLatestTrend() async {
    StateStorageService storageService = StateStorageService();
    var latestPacket = await storageService.getLatestDexGlucosePacket();
    return latestPacket!.trend;
  }

  /// ConvertReadValToGlucose
  /// This method converts the raw value for glucose found in the relevant Dexcom MTU packet into mmol/L. It still needs to be optimized and loses accuracy at high and low blood glucose levels
  /// Hypothesis: The value increases by 0.1 for every 2nd step in the raw value. With exception for every 30th raw value. I.e. [99,100] = 5.5, [101] = 5.6, [102,103] = 5.7 .... [129,130]? = 7.2, [131]? = 7.3, [132,133]? = 7.4 ,
  /// [134,135] = 7.5, [136,137] = 7.6, [138,139] = 7.7, [140,141] = 7.8, [142,143] = 7.9, [144,145] = 8
  @override
  double convertReadValToGlucose(int val) {
    double glucose = 5.5; // Starting glucose level at val 100
    int baseline = 100; // Baseline value for glucose calculations

    // Calculate the step difference from the baseline
    int stepDifference = val - baseline;

    // Ensure we count every full 2-step increment only
    int fullSteps = stepDifference ~/
        2; // Using integer division to round down to the nearest even number

    // Glucose increases by 0.1 mmol/L for each full 2-step increment
    double totalGlucoseChange = fullSteps * 0.1;

    // Update the glucose level based on the step difference
    glucose += totalGlucoseChange;
    print("Blood glucose measured is: $glucose mmol/L"); // For debug purposes
    return glucose;
  }

  /// ConvertTimeStampToDatetime()
  /// Converts the timestamp from the Dexcom MTU packet into a DateTime.
  @override
  String convertTimeStampToDatetime(int timestamp) {
    // Convert the timestamp (assumed to be in milliseconds) to a DateTime object
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    // Format the DateTime object to a string in the desired format
    return DateFormat('yyyy-MM-dd kk:mm:ss').format(date);
  }
}
