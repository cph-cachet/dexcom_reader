import 'dart:convert';

import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/interfaces/shared_preferences_interface.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateStorageService implements IStateStorage {
  @override
  Future<void> saveBTEDevice(BluetoothDevice device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("BTEDevice", device.toString());
  }

  @override
  Future<void> saveDexGlucosePacket(DexGlucosePacket packet) async {
    // TODO: implement saveDexGlucosePacket
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String packetString = packet.toJson().toString();
    print("Saving DexGlucosePacket: $packetString");
    await prefs.setString("LatestDexGlucosePacket", packetString);
  }

  @override
  Future<DexGlucosePacket?> getLatestDexGlucosePacket() async {
    // TODO: implement getLatestDexGlucosePacket
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? packetString = prefs.getString("LatestDexGlucosePacket");
    Map<String, dynamic> packetMap = json.decode(packetString!);
    DexGlucosePacket dexGlucosePacket = DexGlucosePacket.fromJson(packetMap);
    return dexGlucosePacket;
  }

  @override
  Future<void> addDexGlucosePacket(DexGlucosePacket packet) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? packetsString = prefs.getString('DexGlucosePackets');
    List<DexGlucosePacket> packetsList = [];

    // If there is an existing list, decode it
    if (packetsString != null) {
      List<dynamic> packetsMapList = json.decode(packetsString);
      packetsList = packetsMapList
          .map((packetMap) => DexGlucosePacket.fromJson(packetMap))
          .toList();
    }

    // Add the latest packet to the list
    packetsList.add(packet);

    String updatedPacketsString =
        json.encode(packetsList.map((packet) => packet.toJson()).toList());
    await prefs.setString('DexGlucosePackets', updatedPacketsString);
  }

  @override
  Future<List<DexGlucosePacket>> getDexGlucosePackets() async {
    // Can perhaps optimize since it is duplicating the same code as in addDexGlucosePacket()
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? packetsString = prefs.getString('DexGlucosePackets');
    List<DexGlucosePacket> packetsList = [];

    // If there is an existing list, decode it
    if (packetsString != null) {
      List<dynamic> packetsMapList = json.decode(packetsString);
      packetsList = packetsMapList
          .map((packetMap) => DexGlucosePacket.fromJson(packetMap))
          .toList();
    }
    return packetsList;
  }

  @override
  Future<BluetoothDevice?> getDexBluetoothDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? BTEDeviceStr = prefs.getString("BTEDevice");
    BluetoothDevice? device = BTEDeviceStr as BluetoothDevice;
    return device;
  }

  @override
  Future<void> saveLatestRawGlucose(int glucose) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt("glucose_raw", glucose);
  }

  @override
  Future<double?> getLatestGlucoseLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DexcomG7Reader reader = DexcomG7Reader();
    int? glucoseRaw = prefs.getInt("glucose_raw");
    return reader.convertReadValToGlucose(glucoseRaw!);
  }

  @override
  Future<double> getGlucoseFromPeriod(DateTime date) {
    // TODO: implement getGlucoseFromPeriod
    throw UnimplementedError();
  }
}
