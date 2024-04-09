
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/interfaces/shared_preferences_interface.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateStorageService implements IStateStorage {
  @override
  Future<BluetoothDevice?> getDexDevice() {
    // TODO: implement getDexDevice
    throw UnimplementedError();
  }

  @override
  Future<double> getGlucoseFromPeriod(Duration period) {
    // TODO: implement getGlucoseFromPeriod
    throw UnimplementedError();
  }

  @override
  Future<double?> getLatestGlucose() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DexcomG7Reader reader = DexcomG7Reader();
    int? glucoseRaw = prefs.getInt("glucose_raw");
    return reader.convertReadValToGlucose(glucoseRaw!);
  }

  @override
  Future<void> saveDexDevice(BluetoothDevice device) {
    // TODO: implement saveDexDevice
    throw UnimplementedError();
  }

  @override
  Future<void> saveGlucoseLevel(int glucose) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt("glucose_raw", glucose);
  }

  @override
  Future<void> getDexGlucosePacket() {
    // TODO: implement getDexGlucosePacket
    throw UnimplementedError();
  }

  @override
  Future<void> saveDexGlucosePacket(DexGlucosePacket packet) {
    // TODO: implement saveDexGlucosePacket
    throw UnimplementedError();
  }

}