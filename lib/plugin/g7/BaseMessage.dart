import 'dart:typed_data';

class BaseMessage {
  late ByteBuffer data;

  static int getUnsignedInt(ByteBuffer buffer) {
    Uint8List data = buffer.asUint8List();
    return (data[0] + (data[1] << 8) + (data[2] << 16) + (data[3] << 24));
  }

  static int getUnsignedShort(ByteBuffer buffer) {
    Uint8List data = buffer.asUint8List();
    return (data[0] + (data[1] << 8));
  }

  static int getUnsignedByte(ByteBuffer buffer) {
    Uint8List data = buffer.asUint8List();
    return data[0];
  }

  static String dottedStringFromData(ByteBuffer buffer, int length) {
    Uint8List data = buffer.asUint8List(0, length);
    return data.map((x) => x.toString()).join(".");
  }
}
