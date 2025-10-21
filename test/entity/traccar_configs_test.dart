import 'package:flutter_test/flutter_test.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';

void main() {
  group('TraccarConfigs', () {
    test('toMap converts all fields correctly', () {
      // Arrange
      final configs = TraccarConfigs(
        deviceId: 'device-123',
        serverUrl: 'https://demo.traccar.org',
        interval: 5000,
        distance: 100,
        angle: 30,
        accuracy: AccuracyLevel.high,
        offlineBuffering: true,
        wakelock: false,
        notificationIcon: 'ic_notification',
      );

      // Act
      final map = configs.toMap();

      // Assert
      expect(map['deviceId'], equals('device-123'));
      expect(map['serverUrl'], equals('https://demo.traccar.org'));
      expect(map['interval'], equals(5000));
      expect(map['distance'], equals(100));
      expect(map['angle'], equals(30));
      expect(map['accuracy'], equals('High'));
      expect(map['offlineBuffering'], equals(true));
      expect(map['wakelock'], equals(false));
      expect(map['notificationIcon'], equals('ic_notification'));
    });

    test('toMap handles default values', () {
      // Arrange
      final configs = TraccarConfigs(
        deviceId: 'device-123',
        serverUrl: 'https://demo.traccar.org',
      );

      // Act
      final map = configs.toMap();

      // Assert
      expect(map['deviceId'], equals('device-123'));
      expect(map['serverUrl'], equals('https://demo.traccar.org'));
      expect(map['interval'], equals(10000)); // Default value
      expect(map['distance'], equals(0)); // Default value
      expect(map['angle'], equals(0)); // Default value
      expect(map['accuracy'], equals('High')); // Default value
      expect(map['offlineBuffering'], equals(true)); // Default value
      expect(map['wakelock'], equals(true)); // Default value
      expect(map['notificationIcon'], isNull);
    });

    test('accuracy levels map to correct strings', () {
      // Test all accuracy levels
      expect(
        TraccarConfigs(
          deviceId: 'test',
          serverUrl: 'test',
          accuracy: AccuracyLevel.low,
        ).toMap()['accuracy'],
        equals('Low'),
      );

      expect(
        TraccarConfigs(
          deviceId: 'test',
          serverUrl: 'test',
          accuracy: AccuracyLevel.medium,
        ).toMap()['accuracy'],
        equals('Medium'),
      );

      expect(
        TraccarConfigs(
          deviceId: 'test',
          serverUrl: 'test',
          accuracy: AccuracyLevel.high,
        ).toMap()['accuracy'],
        equals('High'),
      );
    });
  });
}
