// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';

import 'package:dexcom_reader/plugin/interfaces/dexcom_g7_reader_interface.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'plugin/g7/DexGlucosePacket.dart';
import 'plugin/services/state_storage_service.dart';

///
/// Create a clean interface and corresponding API for the DexcomService
/// ScanForDexDevice()
/// connectToDexDevice()
/// GetLatestGlucose()
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
          print("Found Dexcom device!");
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
    var bte_timeout = const Duration(
        seconds: 330); // G7 emits an MTU packet every 300 seconds or so
    // If the device is not found within a certain timeout, stop the scan and complete the future with null.
    Future.delayed(bte_timeout).then((_) async {
      if (!completer.isCompleted) {
        await FlutterBluePlus.stopScan();
        subscription.cancel();
        completer.complete(null);
      }
    });
    print("Returning value: ${completer.future}");
    return completer
        .future; // Return the future that completes when the device is found or the timeout occurs
  }

  @override
  Future<void> connectToDexDevice(BluetoothDevice device) async {
    print("Attempting to connect to device");
    await device.connect(); // Connect to the device
    try {
      if (Platform.isAndroid) {
        int desiredMtu =
            517; // Arbitrary MTU, will be changed when testing for Android
        // Request a specific MTU size (Android only)
        int actualMtu = await device.requestMtu(desiredMtu);
        //print('MTU size set to $actualMtu');
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
              int count = 0;
              characteristic.onValueReceived.listen((data) {
                print('Dexcom MTU packet ${count++}: $data');
                if (data.length == 19) {
                  Uint8List packet = Uint8List.fromList(data);
                  decodeBTEPacket(packet);
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

  @override
  Future<void> decodeBTEPacket(Uint8List packet) async {
    EGlucoseRxMessage data = EGlucoseRxMessage(packet);
    double bloodGlucose = convertReadValToGlucose(data.glucose);
    print("Blood glucose measured is: $bloodGlucose mmol/L");
    StateStorageService storageService = StateStorageService();

    final DexGlucosePacket dexGlucosePacket = DexGlucosePacket(
        data.statusRaw,
        data.glucose,
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

    await storageService.saveDexGlucosePacket(dexGlucosePacket);
    await storageService.saveLatestRawGlucose(data.glucose);
  }

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

    return glucose;
  }

  /*
 double convertReadValToGlucose(int val) {
    // If the converted value is 100, then the blood glucose is measured to being 5.5
    // The blood glucose measurement increases by 0.1 mmol/L for every 2nd step in either direction (e.g 98 = 5.4, 99 = 5.5, 100 = 5.5, 101=5.6, 102 = 5.6, 103 = 5.7)
    double glucose = 5.5; // Starting point where we will either increase or decrease it to the actual value
    double mmolChangePerStep = 0.1; // Glucose changes by a rate of 0.1 for every 2 steps.
    int stepSize = 2;
    int stepDiff = (val - 99); // to account for rounding error of type double

    int roundedStepDiff = (stepDiff + 1) ~/ stepSize * stepSize;
    // Calculate the real glucose value
    double conversion = (roundedStepDiff/stepSize) * mmolChangePerStep;
    if (val >= 99) {
      glucose += conversion;
    } else {
      glucose -= conversion;
    }
    //TODO: Save it in state_storage_service with timestamp
    // Calculates int val = 128 into 6.95mmol/L which is incorrect. It should be 7.1
    return glucose;
  }
   */

// 135 = 7.3 but real value is 7.5?
  @override
  Future<double> getLatestGlucose() {
    // TODO: implement getLatestGlucose
    throw UnimplementedError();
  }

  @override
  Future<double> getTrend() {
    // TODO: implement getTrend
    throw UnimplementedError();
  }
}
