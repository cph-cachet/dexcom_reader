import 'dart:typed_data';

// Other potential messages:
//SensorRxMessage -> 0x2f:{TransmitterStatus, timestamp, unfiltered, filtered}
// 
class EGlucoseRxMessage {
  int statusRaw = 0;
  int clock = 0;
  int timestamp = 0;
  int unfiltered = 0;
  int filtered = 0;
  int sequence = 0;
  bool glucoseIsDisplayOnly = false;
  int glucoseRaw = 0;
  double glucose = 0;
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
        glucoseRaw = glucoseBytes & 0xfff;
        glucose = convertReadValToGlucose(glucoseRaw);
        state = data.getUint8(offset++);
        trend = data.getInt8(offset++) / 10.0;

        // Assuming 'predicted_glucose' is the next field, adjust as necessary
        int predictedGlucose = data.getUint16(offset) & 0x03ff;
        print("glucoseRaw: $glucoseRaw");
        valid = true; // Mark the message as valid
      }
    }
  }

  /// TODO: Refactor this to use the same regression model as XDrip
  double convertReadValToGlucose(int rawVal) {
    double glucose = 5.5; // Starting glucose level at val 100
    int baseline = 100; // Baseline value for glucose calculations
    // Calculate the step difference from the baseline
    int stepDifference = rawVal - baseline;
    // Ensure we count every full 2-step increment only
    int fullSteps = stepDifference ~/
        2; // Using integer division to round down to the nearest even number
    // Glucose increases by 0.1 mmol/L for each full 2-step increment
    double totalGlucoseChange = fullSteps * 0.1;
    // Update the glucose level based on the step difference
    glucose += totalGlucoseChange;
    return glucose;
  }

}
