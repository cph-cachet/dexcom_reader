
import 'dart:typed_data';

import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class IDexcomReader {

  Future<String> getPlatformVersion();

  Future<BluetoothDevice?> scanForDexDevice();

  Future<void> connectToDexDevice(BluetoothDevice device);

  Future<void> decodeGlucosePacket(Uint8List packet);

  Future<DexGlucosePacket?> getLatestGlucosePacket();

  Future<double?> getLatestGlucose();

  Future<double?> getLatestTrend();

  double convertReadValToGlucose(int value); // val = 100 is glucose 5.5, 101&102=5.6

  String convertTimeStampToDatetime(int timestamp);






}