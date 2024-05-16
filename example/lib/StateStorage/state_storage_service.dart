import 'dart:convert';
import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader_example/models/dexdevice.dart';
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

    List<String>? existingPackets = prefs.getStringList(
            "${packet.deviceIdentifier.str}/LatestDexGlucosePackets") ??
        [];

    existingPackets.add(jsonString);
    await prefs.setStringList(
        "${packet.deviceIdentifier.str}/LatestDexGlucosePackets",
        existingPackets);
  }

  Future<List<DexGlucosePacket>> getGlucosePacketReadings(
      DeviceIdentifier identifier) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? packetsString =
        prefs.getStringList("${identifier.str}/LatestDexGlucosePackets");

    if (packetsString == null) return [];
    print("number of readings saved on device: ${packetsString.length}");
    List<DexGlucosePacket> packets = packetsString
        .map((jsonStr) => DexGlucosePacket.fromJson(json.decode(jsonStr)))
        .toList();
    return packets;
  }

  Future<void> saveDexcomDevice(DexDevice device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(device.toJson());

    List<String>? existingDevices = prefs.getStringList("/knownDexDevices") ?? [];

    //!devices.any((d) => d.platformName == platformName)¨
    print("Is this device already saved: ${!existingDevices.any((d) => d.contains(device.platformName))}");
    if(!existingDevices.any((d) => d.contains(device.platformName))){
      // Add the new device JSON string to the list
      existingDevices.add(jsonString);
      await prefs.setStringList("/knownDexDevices", existingDevices);
      print("device saved");
    }

  }

  Future<List<DexDevice>> getKnownDexDevicesIfExist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? devicesStringList = prefs.getStringList("/knownDexDevices");
    print("Getting stringList: $devicesStringList");
    if (devicesStringList == null) return [];

    // Map each JSON string to a DexDevice instance
    List<DexDevice> devices = devicesStringList
        .map((jsonStr) => DexDevice.fromJson(json.decode(jsonStr)))
        .toList();

    return devices;
  }


}
