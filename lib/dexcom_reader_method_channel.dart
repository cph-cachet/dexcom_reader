import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dexcom_reader_platform_interface.dart';

/// An implementation of [DexcomG7ReaderPlatform] that uses method channels.
class MethodChannelDexcomG7Reader extends DexcomG7ReaderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dexcom_g7_reader');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
