import 'dart:convert';

import 'package:dexcom_reader/dexcom_reader.dart';
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

}
