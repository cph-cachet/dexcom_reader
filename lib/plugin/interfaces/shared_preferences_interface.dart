
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class IStateStorage {

  Future<void> saveDexDevice(BluetoothDevice device);

  Future<void> saveDexGlucosePacket(DexGlucosePacket packet);

  Future<void> getDexGlucosePacket();

  Future<BluetoothDevice?> getDexDevice();

  Future<void> saveGlucoseLevel(int glucose);

  Future<double?> getLatestGlucose();

  Future<double> getGlucoseFromPeriod(Duration period);



}