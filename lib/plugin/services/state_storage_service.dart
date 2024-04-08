
import 'package:dexcom_reader/plugin/interfaces/shared_preferences_interface.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  Future<double?> getLatestGlucose(BluetoothDevice device) {
    // TODO: implement getLatestGlucose
    throw UnimplementedError();
  }

  @override
  Future<void> saveDexDevice(BluetoothDevice device) {
    // TODO: implement saveDexDevice
    throw UnimplementedError();
  }

  @override
  Future<void> saveGlucoseLevel(int glucose) {
    // TODO: implement saveGlucoseLevel
    double glucoseLevel = glucose/18.05;
    throw UnimplementedError();
  }

}