/// Represents a geographic position with metadata.
///
/// This class contains all location data captured by the tracking service,
/// including coordinates, speed, accuracy, battery level, and more.
class Position {
  /// Unique identifier for this position (0 for new positions)
  final int id;

  /// Device identifier that recorded this position
  final String deviceId;

  /// Timestamp when position was recorded
  final DateTime time;

  /// Latitude in decimal degrees
  final double latitude;

  /// Longitude in decimal degrees
  final double longitude;

  /// Altitude in meters above sea level
  final double altitude;

  /// Speed in meters per second
  final double speed;

  /// Course/bearing in degrees (0-360)
  final double course;

  /// Horizontal accuracy in meters
  final double accuracy;

  /// Battery level percentage (0-100)
  final double battery;

  /// Whether device is charging
  final bool charging;

  /// Whether location is from a mock provider (debug mode)
  final bool mock;

  const Position({
    required this.id,
    required this.deviceId,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.course,
    required this.accuracy,
    required this.battery,
    required this.charging,
    required this.mock,
  });

  /// Creates a Position from a map (from platform channel)
  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      id: map['id'] as int? ?? 0,
      deviceId: map['deviceId'] as String? ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int? ?? 0),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      course: (map['course'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      battery: (map['battery'] as num?)?.toDouble() ?? 100.0,
      charging: map['charging'] as bool? ?? false,
      mock: map['mock'] as bool? ?? false,
    );
  }

  /// Converts this Position to a map (for platform channel)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'time': time.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'course': course,
      'accuracy': accuracy,
      'battery': battery,
      'charging': charging,
      'mock': mock,
    };
  }

  @override
  String toString() {
    return 'Position(deviceId: $deviceId, lat: $latitude, lon: $longitude, time: $time)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Position &&
        other.id == id &&
        other.deviceId == deviceId &&
        other.time == time &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(id, deviceId, time, latitude, longitude);
  }
}
