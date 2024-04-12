import 'dart:typed_data';

import 'package:intl/intl.dart';

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
        // Perform bitwise AND between glucoseBytes and hex value 0xfff = 111111111111, which extracts the relevant lower 12 bits from the glucoseBytes value after being read in little endian order.
        glucose = glucoseBytes & 0xfff;

        state = data.getUint8(offset++);
        trend = data.getInt8(offset++) / 10.0;

        // Assuming 'predicted_glucose' is the next field, adjust as necessary
        int predictedGlucose = data.getUint16(offset) & 0x03ff;
        print("glucoseRaw: $glucose");
        valid = true; // Mark the message as valid
      }
    }
  }

  String dateTimeText(int timestamp) {
    // Convert the timestamp (assumed to be in milliseconds) to a DateTime object
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    // Format the DateTime object to a string in the desired format
    return DateFormat('yyyy-MM-dd kk:mm:ss').format(date);
  }
}
