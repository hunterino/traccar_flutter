import 'package:flutter_test/flutter_test.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';

void main() {
  group('Settings Validation Logic', () {
    group('Device ID Validation', () {
      test('returns error when device ID is null', () {
        final result = validateDeviceId(null);
        expect(result, 'Device ID is required');
      });

      test('returns error when device ID is empty', () {
        final result = validateDeviceId('');
        expect(result, 'Device ID is required');
      });

      test('returns error when device ID is only whitespace', () {
        final result = validateDeviceId('   ');
        expect(result, 'Device ID is required');
      });

      test('returns error when device ID is too short', () {
        final result = validateDeviceId('ab');
        expect(result, 'Device ID must be at least 3 characters');
      });

      test('returns null for valid device ID with minimum length', () {
        final result = validateDeviceId('abc');
        expect(result, null);
      });

      test('returns null for valid device ID', () {
        final result = validateDeviceId('device-123-test');
        expect(result, null);
      });

      test('trims whitespace before validation', () {
        final result = validateDeviceId('  abc  ');
        expect(result, null);
      });
    });

    group('Server URL Validation', () {
      test('returns error when URL is null', () {
        final result = validateServerUrl(null);
        expect(result, 'Server URL is required');
      });

      test('returns error when URL is empty', () {
        final result = validateServerUrl('');
        expect(result, 'Server URL is required');
      });

      test('returns error when URL has no protocol', () {
        final result = validateServerUrl('example.com');
        expect(result, 'URL must start with http:// or https://');
      });

      test('returns error when URL has wrong protocol', () {
        final result = validateServerUrl('ftp://example.com');
        expect(result, 'URL must start with http:// or https://');
      });

      test('returns null for valid HTTP URL', () {
        final result = validateServerUrl('http://example.com:5055');
        expect(result, null);
      });

      test('returns null for valid HTTPS URL', () {
        final result = validateServerUrl('https://example.com:5055');
        expect(result, null);
      });

      test('returns null for valid URL without port', () {
        final result = validateServerUrl('http://example.com');
        expect(result, null);
      });

      test('returns null for valid URL with path', () {
        final result = validateServerUrl('http://example.com:5055/path');
        expect(result, null);
      });

      test('returns null for localhost URL', () {
        final result = validateServerUrl('http://localhost:5055');
        expect(result, null);
      });

      test('returns null for IP address URL', () {
        final result = validateServerUrl('http://192.168.1.1:5055');
        expect(result, null);
      });

      test('handles mixed case protocol', () {
        final result = validateServerUrl('HTTP://example.com');
        expect(result, null);
      });
    });

    group('Interval Validation', () {
      test('returns error when interval is null', () {
        final result = validateInterval(null);
        expect(result, 'Interval is required');
      });

      test('returns error when interval is empty', () {
        final result = validateInterval('');
        expect(result, 'Interval is required');
      });

      test('returns error when interval is not a number', () {
        final result = validateInterval('abc');
        expect(result, 'Must be a valid number');
      });

      test('returns error when interval is too small', () {
        final result = validateInterval('4');
        expect(result, 'Interval must be at least 5 seconds');
      });

      test('returns error when interval is zero', () {
        final result = validateInterval('0');
        expect(result, 'Interval must be at least 5 seconds');
      });

      test('returns error when interval is negative', () {
        final result = validateInterval('-5');
        expect(result, 'Interval must be at least 5 seconds');
      });

      test('returns error when interval is too large', () {
        final result = validateInterval('3601');
        expect(result, 'Interval must be less than 3600 seconds');
      });

      test('returns null for minimum valid interval', () {
        final result = validateInterval('5');
        expect(result, null);
      });

      test('returns null for maximum valid interval', () {
        final result = validateInterval('3600');
        expect(result, null);
      });

      test('returns null for typical interval', () {
        final result = validateInterval('30');
        expect(result, null);
      });

      test('trims whitespace before validation', () {
        final result = validateInterval('  30  ');
        expect(result, null);
      });
    });

    group('Distance Validation', () {
      test('returns error when distance is null', () {
        final result = validateDistance(null);
        expect(result, 'Distance is required');
      });

      test('returns error when distance is empty', () {
        final result = validateDistance('');
        expect(result, 'Distance is required');
      });

      test('returns error when distance is not a number', () {
        final result = validateDistance('abc');
        expect(result, 'Must be a valid number');
      });

      test('returns error when distance is negative', () {
        final result = validateDistance('-1');
        expect(result, 'Distance cannot be negative');
      });

      test('returns null for zero distance', () {
        final result = validateDistance('0');
        expect(result, null);
      });

      test('returns null for positive distance', () {
        final result = validateDistance('100');
        expect(result, null);
      });

      test('returns null for large distance', () {
        final result = validateDistance('10000');
        expect(result, null);
      });
    });

    group('Angle Validation', () {
      test('returns error when angle is null', () {
        final result = validateAngle(null);
        expect(result, 'Angle is required');
      });

      test('returns error when angle is empty', () {
        final result = validateAngle('');
        expect(result, 'Angle is required');
      });

      test('returns error when angle is not a number', () {
        final result = validateAngle('abc');
        expect(result, 'Must be a valid number');
      });

      test('returns error when angle is negative', () {
        final result = validateAngle('-1');
        expect(result, 'Angle must be between 0 and 360');
      });

      test('returns error when angle is greater than 360', () {
        final result = validateAngle('361');
        expect(result, 'Angle must be between 0 and 360');
      });

      test('returns null for minimum valid angle', () {
        final result = validateAngle('0');
        expect(result, null);
      });

      test('returns null for maximum valid angle', () {
        final result = validateAngle('360');
        expect(result, null);
      });

      test('returns null for typical angle', () {
        final result = validateAngle('45');
        expect(result, null);
      });

      test('returns null for 90 degrees', () {
        final result = validateAngle('90');
        expect(result, null);
      });

      test('returns null for 180 degrees', () {
        final result = validateAngle('180');
        expect(result, null);
      });
    });

    group('AccuracyLevel Conversion', () {
      test('converts "low" string to AccuracyLevel.low', () {
        final accuracy = AccuracyLevel.values.firstWhere(
          (e) => e.name == 'low',
          orElse: () => AccuracyLevel.high,
        );
        expect(accuracy, AccuracyLevel.low);
      });

      test('converts "medium" string to AccuracyLevel.medium', () {
        final accuracy = AccuracyLevel.values.firstWhere(
          (e) => e.name == 'medium',
          orElse: () => AccuracyLevel.high,
        );
        expect(accuracy, AccuracyLevel.medium);
      });

      test('converts "high" string to AccuracyLevel.high', () {
        final accuracy = AccuracyLevel.values.firstWhere(
          (e) => e.name == 'high',
          orElse: () => AccuracyLevel.high,
        );
        expect(accuracy, AccuracyLevel.high);
      });

      test('defaults to high for invalid string', () {
        final accuracy = AccuracyLevel.values.firstWhere(
          (e) => e.name == 'invalid',
          orElse: () => AccuracyLevel.high,
        );
        expect(accuracy, AccuracyLevel.high);
      });

      test('defaults to high for empty string', () {
        final accuracy = AccuracyLevel.values.firstWhere(
          (e) => e.name == '',
          orElse: () => AccuracyLevel.high,
        );
        expect(accuracy, AccuracyLevel.high);
      });
    });
  });
}

// Validation helper functions matching the SettingsPage implementation
String? validateDeviceId(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Device ID is required';
  }
  if (value.trim().length < 3) {
    return 'Device ID must be at least 3 characters';
  }
  return null;
}

String? validateServerUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Server URL is required';
  }

  final url = value.trim().toLowerCase();
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return 'URL must start with http:// or https://';
  }

  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasAuthority) {
    return 'Invalid URL format';
  }

  return null;
}

String? validateInterval(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Interval is required';
  }

  final interval = int.tryParse(value.trim());
  if (interval == null) {
    return 'Must be a valid number';
  }

  if (interval < 5) {
    return 'Interval must be at least 5 seconds';
  }

  if (interval > 3600) {
    return 'Interval must be less than 3600 seconds';
  }

  return null;
}

String? validateDistance(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Distance is required';
  }

  final distance = int.tryParse(value.trim());
  if (distance == null) {
    return 'Must be a valid number';
  }

  if (distance < 0) {
    return 'Distance cannot be negative';
  }

  return null;
}

String? validateAngle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Angle is required';
  }

  final angle = int.tryParse(value.trim());
  if (angle == null) {
    return 'Must be a valid number';
  }

  if (angle < 0 || angle > 360) {
    return 'Angle must be between 0 and 360';
  }

  return null;
}
