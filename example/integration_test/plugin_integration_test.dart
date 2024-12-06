// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';
import 'package:traccar_flutter/traccar_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final traccar = TraccarFlutter();

  testWidgets('Initialize Traccar', (WidgetTester tester) async {
    final initResult = await traccar.initTraccar();
    expect(initResult, equals('initialized successfully'));
  });

  group('Set configurations and check service', () {
    testWidgets('Set configurations',
        (WidgetTester tester) async {
      final configs = TraccarConfigs(
        deviceId: 'test-device-id',
        serverUrl: 'https://demo.traccar.org',
        interval: 5000,
        accuracy: AccuracyLevel.high,
        offlineBuffering: true,
        wakelock: true,
      );

      final configResult = await traccar.setConfigs(configs);
      expect(configResult, equals('configs set'));
    });

    testWidgets('Start service', (WidgetTester tester) async {
      final stopResult = await traccar.startService();
      expect(stopResult, equals('service started'));
    });

    testWidgets('Stop service', (WidgetTester tester) async {
      final stopResult = await traccar.stopService();
      expect(stopResult, equals('service stopped'));
    });

    testWidgets('Show status logs', (WidgetTester tester) async {
      final logs = await traccar.showStatusLogs();
      expect(logs, equals('launch status activity'));
    });
  });
}
