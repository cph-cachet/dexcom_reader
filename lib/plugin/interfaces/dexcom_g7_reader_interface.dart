
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class IDexcomG7Reader {

  Future<String> getPlatformVersion();

  Future<BluetoothDevice?> scanForDexDevice();

  Future<void> connectToDexDevice(BluetoothDevice device);

  double convertReadValToGlucose(int value); // val = 100 is glucose 5.5, 101&102=5.6

  Future<double> getLatestGlucose();



}