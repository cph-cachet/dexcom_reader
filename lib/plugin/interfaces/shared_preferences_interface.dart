
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class IStateStorage {

  Future<void> saveDexDevice(BluetoothDevice device);

  Future<BluetoothDevice?> getDexDevice();

  Future<void> saveGlucoseLevel(int glucose);

  Future<double?> getLatestGlucose(BluetoothDevice device);

  Future<double> getGlucoseFromPeriod(Duration period);



}