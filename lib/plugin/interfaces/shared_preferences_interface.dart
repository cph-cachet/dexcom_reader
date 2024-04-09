
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class IStateStorage {

  Future<void> saveBTEDevice(BluetoothDevice device);

  Future<void> saveDexGlucosePacket(DexGlucosePacket packet);

  Future<DexGlucosePacket?> getLatestDexGlucosePacket();

  Future<void> addDexGlucosePacket(DexGlucosePacket packet);

  Future<List<DexGlucosePacket>?> getDexGlucosePackets();

  Future<BluetoothDevice?> getDexBluetoothDevice();

  Future<void> saveLatestRawGlucose(int glucose);

  Future<double?> getLatestGlucoseLevel();

  Future<double> getGlucoseFromPeriod(DateTime date);




}