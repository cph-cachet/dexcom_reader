// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction


import 'dart:typed_data';

import 'package:dexcom_reader/plugin/g7/EGlucoseRxMessage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dexcom_reader/dexcom_reader.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final DexcomReader plugin = DexcomReader();
    Uint8List packet = Uint8List.fromList([78, 0, 207, 74, 13, 0, 90, 11, 0, 1, 6, 0, 102, 0, 6, 251, 93, 0, 15]);
    final EGlucoseRxMessage rxMessage = plugin.decodeGlucosePacket(packet);
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(rxMessage, true);
  });
}
