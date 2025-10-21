import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:traccar_flutter/traccar_flutter.dart';
import 'package:traccar_flutter/traccar_flutter_platform_interface.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';

class MockTraccarFlutterPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TraccarFlutterPlatform {}

void main() {
  late TraccarFlutter traccar;
  late MockTraccarFlutterPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockTraccarFlutterPlatform();
    TraccarFlutterPlatform.instance = mockPlatform;
    traccar = TraccarFlutter();
  });

  group('TraccarFlutter', () {
    test('initTraccar returns success message', () async {
      // Arrange
      when(() => mockPlatform.initTraccar())
          .thenAnswer((_) async => 'initialized successfully');

      // Act
      final result = await traccar.initTraccar();

      // Assert
      expect(result, equals('initialized successfully'));
      verify(() => mockPlatform.initTraccar()).called(1);
    });

    test('initTraccar returns null on failure', () async {
      // Arrange
      when(() => mockPlatform.initTraccar()).thenAnswer((_) async => null);

      // Act
      final result = await traccar.initTraccar();

      // Assert
      expect(result, isNull);
      verify(() => mockPlatform.initTraccar()).called(1);
    });

    test('setConfigs passes configuration correctly', () async {
      // Arrange
      final configs = TraccarConfigs(
        deviceId: 'test-device-123',
        serverUrl: 'https://test.traccar.org',
        interval: 5000,
        distance: 100,
        angle: 30,
        accuracy: AccuracyLevel.high,
        offlineBuffering: true,
        wakelock: true,
        notificationIcon: 'custom_icon',
      );

      when(() => mockPlatform.setConfigs(configs))
          .thenAnswer((_) async => 'configs set');

      // Act
      final result = await traccar.setConfigs(configs);

      // Assert
      expect(result, equals('configs set'));
      verify(() => mockPlatform.setConfigs(configs)).called(1);
    });

    test('startService returns success message', () async {
      // Arrange
      when(() => mockPlatform.startService())
          .thenAnswer((_) async => 'service started');

      // Act
      final result = await traccar.startService();

      // Assert
      expect(result, equals('service started'));
      verify(() => mockPlatform.startService()).called(1);
    });

    test('stopService returns success message', () async {
      // Arrange
      when(() => mockPlatform.stopService())
          .thenAnswer((_) async => 'service stopped');

      // Act
      final result = await traccar.stopService();

      // Assert
      expect(result, equals('service stopped'));
      verify(() => mockPlatform.stopService()).called(1);
    });

    test('showStatusLogs calls platform method', () async {
      // Arrange
      when(() => mockPlatform.showStatusLogs())
          .thenAnswer((_) async => 'launch status activity');

      // Act
      final result = await traccar.showStatusLogs();

      // Assert
      expect(result, equals('launch status activity'));
      verify(() => mockPlatform.showStatusLogs()).called(1);
    });
  });
}
