import 'dart:async';
import 'package:dexcom_reader/dexcom_data.dart';
import 'package:flutter/services.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DexcomDeviceStatus { scanning, connecting, connected, disconnected }

class DexcomReader {
  late StreamSubscription _deviceSubscription;

  // TODO: Implement these streams
  final _statusController = StreamController<DexcomDeviceStatus>();
  Stream<DexcomDeviceStatus> get status => _statusController.stream;

  final _glucoseReadingsController = StreamController<EGlucoseRxMessage>();
  Stream<EGlucoseRxMessage> get glucoseReadings =>
      _glucoseReadingsController.stream;

  /// This method returns a BluetoothDevice that corresponds to a Dexcom G7.
  /// The data returned will be used to connect to device for listening
  Future<BluetoothDevice?> scan() async {
    BluetoothDevice? device;
    await FlutterBluePlus.startScan(
        withNames: ["DXCMHO"], timeout: const Duration(seconds: 330));
    _statusController.add(DexcomDeviceStatus.scanning);
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.platformName == 'DXCMHO') {
          FlutterBluePlus.stopScan();
          //connect(result.device);
          device = result.device;
          break;
        }
      }
    });

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    subscription.cancel();
    return device;
  }

  /// This method connects to a Dexcom BTDevice and listens to the relevant MTU packet(s)
  /// If device information is not stored in memory, then we must first scan() before connecting
  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
    _statusController.add(DexcomDeviceStatus.connecting);
    device.mtu.listen((mtu) {});
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          await characteristic.setNotifyValue(true);
          _deviceSubscription = characteristic.onValueReceived.distinct().listen((data) {
            if (data.length == 19) {
              _statusController.add(DexcomDeviceStatus.connected);
              decodeGlucosePacket(Uint8List.fromList(data));
            }
          });
        }
      }
    }
  }

  Future<void> disconnect() async {
    await _deviceSubscription.cancel();
    _statusController.add(DexcomDeviceStatus.disconnected);
  }


  /// DecodeGlucosePacket()
  /// This method takes a Dexcom packet with an adequate length and converts it into readable data, for example:
  /// [78, 0, 207, 74, 13, 0, 90, 11, 0, 1, 6, 0, 102, 0, 6, 251, 93, 0, 15] =>
  /// {"statusRaw":0,"glucose":102,"clock":871119,"timestamp":1712909742781,"unfiltered":0,"filtered":0,"sequence":2906,"glucoseIsDisplayOnly":false,"state":6,"trend":-0.5,"age":6,"valid":true}
  EGlucoseRxMessage decodeGlucosePacket(Uint8List packet) {
    return EGlucoseRxMessage(packet);
  }

  /// ConvertReadValToGlucose
  /// This method converts the raw value for glucose found in the relevant Dexcom MTU packet into mmol/L. It still needs to be optimized and loses accuracy at high and low blood glucose levels
  /// Hypothesis: The value increases by 0.1 for every 2nd step in the raw value. With exception for every 30th raw value. I.e. [99,100] = 5.5, [101] = 5.6, [102,103] = 5.7 .... [129,130]? = 7.2, [131]? = 7.3, [132,133]? = 7.4 ,
  /// [134,135] = 7.5, [136,137] = 7.6, [138,139] = 7.7, [140,141] = 7.8, [142,143] = 7.9, [144,145] = 8
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
}
