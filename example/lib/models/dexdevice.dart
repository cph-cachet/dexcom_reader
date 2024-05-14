import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DexDevice {
  final DeviceIdentifier remoteId;
  final String platformName;

  DexDevice({
    required this.remoteId,
    required this.platformName,
  });

  factory DexDevice.fromJson(Map<String, dynamic> json) {
    return DexDevice(
      remoteId: DeviceIdentifier(json['remoteId']),
      platformName: json['platformName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'remoteId': remoteId.str,
      'platformName': platformName,
    };
  }
}
