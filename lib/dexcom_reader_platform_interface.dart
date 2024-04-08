import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dexcom_reader_method_channel.dart';

abstract class DexcomG7ReaderPlatform extends PlatformInterface {
  /// Constructs a DexcomG7ReaderPlatform.
  DexcomG7ReaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static DexcomG7ReaderPlatform _instance = MethodChannelDexcomG7Reader();

  /// The default instance of [DexcomG7ReaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelDexcomG7Reader].
  static DexcomG7ReaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DexcomG7ReaderPlatform] when
  /// they register themselves.
  static set instance(DexcomG7ReaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
