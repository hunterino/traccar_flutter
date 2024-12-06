part of 'traccar_configs.dart';

/// Specifies the accuracy level for location tracking.
///
/// This enum defines the level of precision for collecting location updates.
/// Higher accuracy levels provide more precise location data but may consume more battery.
enum AccuracyLevel {
  /// Low accuracy level.
  ///
  /// Suitable for scenarios where approximate location data is sufficient.
  /// This mode consumes the least battery.
  low,

  /// Medium accuracy level.
  ///
  /// Provides a balance between location precision and battery consumption.
  medium,

  /// High accuracy level.
  ///
  /// Suitable for scenarios requiring precise location data, such as navigation.
  /// This mode consumes the most battery.
  high;

  /// Returns the channel name corresponding to the accuracy level.
  ///
  /// This is used to convert the enum values into their string representation
  /// for easier communication with native platforms or logging.
  String get channelName => {
        AccuracyLevel.low: 'Low',
        AccuracyLevel.medium: 'Medium',
        AccuracyLevel.high: 'High',
      }[this]!;
}
