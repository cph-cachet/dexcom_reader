import 'dart:async';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DexcomData {
  late num? glucoseLevel;

  DexcomData(this.glucoseLevel);

  DexcomData.fromDexcomSample(Map<String, dynamic> sample){
    glucoseLevel = sample['glucose'];
  }

  void example() async {
    var dex = DexcomReader();
    // Scan for devices and handle the case where no device is found
    List<BluetoothDevice> devices = await dex.getScannedDexcomDevices();
    List<EGlucoseRxMessage> glucoseMessages = [];

    await dex.connectWithId(devices[0].remoteId.str);

    StreamSubscription statusSubscription = dex.status.listen((event) async {
      if (event == DexcomDeviceStatus.connected) {
        // When connected, listen to glucose readings
        StreamSubscription glucoseReadingsSubscription = dex.glucoseReadings.listen((reading) {
          glucoseMessages.add(reading);
          print("Glucose raw value: ${glucoseMessages.first.glucoseRaw}");
          print("Glucose mmol/L: ${glucoseMessages.first.glucose}");
          print("Glucose trend: ${glucoseMessages.first.trend}");
        });
        await glucoseReadingsSubscription.cancel();
      }
    });
    await statusSubscription.cancel();
  }

}