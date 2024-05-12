import 'dart:convert';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateStorageService {


  Future<DexGlucosePacket?> getLatestDexGlucosePacket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? packetString = prefs.getString("LatestDexGlucosePackets");
    if (packetString == null) {
      return null;
    }
    Map<String, dynamic> packetMap = json.decode(packetString);
    DexGlucosePacket dexGlucosePacket = DexGlucosePacket.fromJson(packetMap);
    return dexGlucosePacket;
  }

  Future<void> saveLatestDexGlucosePacket(DexGlucosePacket packet) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(packet.toJson());
    prefs.setString("LatestDexGlucosePacket", jsonString);
  }

  Future<void> addGlucosePacketReading(DexGlucosePacket packet) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(packet.toJson());

    // Retrieve the existing list from SharedPreferences
    List<String>? existingPackets = prefs.getStringList("${packet.deviceIdentifier.str}/LatestDexGlucosePackets") ?? [];

    // Add the new packet's JSON string to the list
    existingPackets.add(jsonString);
    // Save the updated list back to SharedPreferences
    await prefs.setStringList("${packet.deviceIdentifier.str}/LatestDexGlucosePackets", existingPackets);
  }


  Future<List<DexGlucosePacket>> getGlucosePacketReadings(DeviceIdentifier identifier) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? packetsString = prefs.getStringList("${identifier.str}/LatestDexGlucosePackets");

    // Check if there are any stored packets, if not return an empty list
    if (packetsString == null) return [];
    print("number of readings saved on device: ${packetsString.length}");
    print(packetsString.last);
    // Decode each JSON string back into a DexGlucosePacket object
    List<DexGlucosePacket> packets = packetsString.map((jsonStr) => DexGlucosePacket.fromJson(json.decode(jsonStr))).toList();
    return packets;
  }


}
