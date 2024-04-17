import 'dart:convert';

import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateStorageService {
  @override
  Future<void> saveBTEDevice(BluetoothDevice device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("BTEDevice", device.toString());
  }

  Future<void> saveDexGlucosePacket(DexGlucosePacket packet) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> packetMap = packet.toJson();
    String packetString = json.encode(packetMap);
    await prefs.setString("LatestDexGlucosePacket", packetString);
  }

  Future<DexGlucosePacket?> getLatestDexGlucosePacket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? packetString = prefs.getString("LatestDexGlucosePacket");
    Map<String, dynamic> packetMap = json.decode(packetString!);
    DexGlucosePacket dexGlucosePacket = DexGlucosePacket.fromJson(packetMap);
    return dexGlucosePacket;
  }
}
