import 'dart:async';

import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DexcomData {
  late BluetoothDevice device;
  late num? glucoseLevel;

  DexcomData(this.device, this.glucoseLevel);

  DexcomData.fromDexcomSample(Map<String, dynamic> sample){
    glucoseLevel = sample['glucose'];
  }

  void example() async {
    var dex = DexcomReader();
    // Scan for devices and handle the case where no device is found
    var _device = await dex.scan();
    if (_device == null) {
      print("No Dexcom device scanned.");
      return;
    }

    // Connect to the device
    await dex.connect(_device);

    // Listen to status updates
    StreamSubscription statusSubscription = dex.status.listen((event) async {
      if (event == DexcomDeviceStatus.connected) {
        // When connected, listen to glucose readings
        StreamSubscription readingsSubscription = dex.glucoseReadings.listen((reading) {
          print(dex.convertReadValToGlucose(reading.glucose)); // TODO: Do something with stream?
        });
        await readingsSubscription.cancel();
      }
    });
    await statusSubscription.cancel();
  }
}