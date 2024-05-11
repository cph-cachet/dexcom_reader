import 'dart:convert';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateStorageService {


  Future<DexGlucosePacket?> getLatestDexGlucosePacket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? packetString = prefs.getString("LatestDexGlucosePackets");
    if (packetString == null) {
      return null;
    }
    Map<String, dynamic> packetMap = json.decode(packetString);
    print("fetched: $packetString");
    print("decoded: $packetMap");
    DexGlucosePacket dexGlucosePacket = DexGlucosePacket.fromJson(packetMap);
    return dexGlucosePacket;
  }

  Future<void> saveLatestDexGlucosePacket(DexGlucosePacket packet) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(packet.toJson());
    print("saving: $jsonString");
    prefs.setString("LatestDexGlucosePackets", jsonString);
  }

  Future<void> addGlucosePacketReading(DexGlucosePacket packet) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

}
