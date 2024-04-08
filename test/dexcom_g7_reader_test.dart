import 'package:flutter_test/flutter_test.dart';
import 'package:dexcom_reader/dexcom_reader.dart';
import 'package:dexcom_reader/dexcom_reader_platform_interface.dart';
import 'package:dexcom_reader/dexcom_reader_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDexcomG7ReaderPlatform
    with MockPlatformInterfaceMixin
    implements DexcomG7ReaderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DexcomG7ReaderPlatform initialPlatform = DexcomG7ReaderPlatform.instance;

  test('$MethodChannelDexcomG7Reader is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDexcomG7Reader>());
  });

  test('getPlatformVersion', () async {
    DexcomG7Reader dexcomG7ReaderPlugin = DexcomG7Reader();
    MockDexcomG7ReaderPlatform fakePlatform = MockDexcomG7ReaderPlatform();
    DexcomG7ReaderPlatform.instance = fakePlatform;

    expect(await dexcomG7ReaderPlugin.getPlatformVersion(), '42');
  });
}
