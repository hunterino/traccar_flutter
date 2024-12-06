import 'entity/traccar_configs.dart';
import 'traccar_flutter_platform_interface.dart';

/// A Flutter library to integrate with the Traccar native SDKs for Android and iOS.
///
/// This class provides methods to initialize the Traccar SDK, configure settings,
/// start/stop the tracking service, and access status logs.
class TraccarFlutter {
  /// Initializes the Traccar service.
  ///
  /// This method sets up the necessary resources for Traccar to function.
  /// Call this method before using other functionalities.
  ///
  /// Returns a [Future] that completes with a success message as a [String],
  /// or `null` if the initialization fails.
  Future<String?> initTraccar() {
    return TraccarFlutterPlatform.instance.initTraccar();
  }

  /// Configures the Traccar service with the provided settings.
  ///
  /// [configs]: An instance of [TraccarConfigs] containing configuration options,
  /// such as server URL, interval, and other related settings.
  ///
  /// Returns a [Future] that completes with a success message as a [String],
  /// or `null` if configuration fails.
  Future<String?> setConfigs(TraccarConfigs configs) {
    return TraccarFlutterPlatform.instance.setConfigs(configs);
  }

  /// Starts the Traccar tracking service.
  ///
  /// This method activates the service to begin tracking and sending location updates.
  /// Ensure that configurations are set before calling this method.
  ///
  /// Returns a [Future] that completes with a success message as a [String],
  /// or `null` if the service fails to start.
  Future<String?> startService() {
    return TraccarFlutterPlatform.instance.startService();
  }

  /// Stops the Traccar tracking service.
  ///
  /// This method deactivates the service and stops location tracking.
  ///
  /// Returns a [Future] that completes with a success message as a [String],
  /// or `null` if the service fails to stop.
  Future<String?> stopService() {
    return TraccarFlutterPlatform.instance.stopService();
  }

  /// Displays the status logs screen of the Traccar service. (Native screen)
  ///
  /// This method is used for debugging or monitoring the current state
  /// and logs of the Traccar service.
  ///
  /// Returns a [Future] that completes with the logs as a [String],
  /// or `null` if no logs are available.
  Future<String?> showStatusLogs() {
    return TraccarFlutterPlatform.instance.showStatusLogs();
  }
}
