import 'dart:typed_data';

import 'package:dexcom_reader/plugin/g7/DexGlucosePacket.dart';
import 'package:dexcom_reader/plugin/services/state_storage_service.dart';

class EGlucoseRxMessage {
  int statusRaw = 0;
  int clock = 0;
  int timestamp = 0;
  int unfiltered = 0;
  int filtered = 0;
  int sequence = 0;
  bool glucoseIsDisplayOnly = false;
  int glucose = 0;
  int state = 0;
  double trend = 0.0;
  int age = 0;
  bool valid = false;

  EGlucoseRxMessage(Uint8List packet) {
    if (packet.length >= 19) {
      final data = ByteData.sublistView(packet);
      int offset = 0;

      int opcode = data.getUint8(offset++);
      if (opcode == 0x4e) {
        // Assuming 0x4e is the opcode
        statusRaw = data.getUint8(offset++);
        clock = data.getUint32(offset, Endian.little);
        offset += 4;
        sequence = data.getUint16(offset, Endian.little);
        offset += 2;
        data.getUint16(offset, Endian.little); // Skip the 'bogus' value
        offset += 2;

        age = data.getUint16(offset, Endian.little);
        offset += 2;

        timestamp = DateTime.now().millisecondsSinceEpoch - (age * 1000);

        int glucoseBytes = data.getUint16(offset, Endian.little);
        offset += 2;
        glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0;
        glucose = glucoseBytes & 0xfff;

        state = data.getUint8(offset++);
        trend = data.getInt8(offset++) / 10.0;

        // Assuming 'predicted_glucose' is the next field, adjust as necessary
        int predictedGlucose = data.getUint16(offset) & 0x03ff;

        valid = true; // Mark the message as valid

        // Print or handle the parsed values as needed
        print('EGlucoseRX: glucose: $glucose, timestamp: $timestamp, trend: $trend, valid: $valid');
      }
    }
  }
}
