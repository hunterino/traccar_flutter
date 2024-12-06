part 'accuracy_level.dart';

/// Configuration settings for the Traccar tracking service.
///
/// This class encapsulates all the parameters required to initialize and
/// configure the Traccar service, such as server URL, device ID, accuracy level,
/// and various optional settings.
class TraccarConfigs {
  /// Unique identifier for the device being tracked.
  ///
  /// This value is required and should uniquely represent the device in the Traccar system.
  final String deviceId;

  /// The URL of the Traccar server.
  ///
  /// This value is required and specifies the endpoint where location data
  /// will be sent.
  final String serverUrl;

  /// Specifies the desired accuracy level for location tracking.
  ///
  /// Default is [AccuracyLevel.high].
  final AccuracyLevel accuracy;

  /// The interval (in milliseconds) for sending location updates.
  ///
  /// Default is `10000` (10 seconds). Adjust this value to control how frequently
  /// location updates are sent.
  final int? interval;

  /// The minimum distance (in meters) to trigger a location update.
  ///
  /// Default is `0`. If set to a positive value, location updates will only be sent
  /// when the device has moved at least this distance.
  final int? distance;

  /// The angle threshold (in degrees) for triggering location updates based on direction changes.
  ///
  /// Default is `0`. If set, location updates will be triggered when the device's direction
  /// changes by at least this angle.
  final int? angle;

  /// Enables or disables offline buffering of location updates.
  ///
  /// When enabled (default is `true`), location updates are saved locally when the device
  /// is offline and sent to the server when connectivity is restored.
  final bool? offlineBuffering;

  /// Specifies whether to acquire a wake lock to keep the device awake while tracking.
  ///
  /// Default is `true`. This ensures the tracking service runs reliably in the background.
  final bool? wakelock;

  /// The name of the custom notification icon to be used for the tracking service.
  ///
  /// This is optional. If provided, the icon must be included in the app's resources.
  final String? notificationIcon;

  /// Creates a [TraccarConfigs] object with the specified parameters.
  ///
  /// All required parameters must be provided, while optional ones have default values.
  TraccarConfigs({
    required this.deviceId,
    required this.serverUrl,
    this.interval = 10000,
    this.distance = 0,
    this.angle = 0,
    this.accuracy = AccuracyLevel.high,
    this.offlineBuffering = true,
    this.wakelock = true,
    this.notificationIcon,
  });

  /// Converts the configuration object into a map representation.
  ///
  /// Useful for sending the configuration to the native platform or for serialization.
  ///
  /// Returns a [Map] with keys and values corresponding to the configuration fields.
  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'serverUrl': serverUrl,
        'interval': interval,
        'distance': distance,
        'angle': angle,
        'accuracy': accuracy.channelName,
        'offlineBuffering': offlineBuffering,
        'wakelock': wakelock,
        'notificationIcon': notificationIcon,
      };
}
