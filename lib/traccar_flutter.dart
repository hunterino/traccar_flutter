import 'dart:async';

import 'entity/traccar_configs.dart';
import 'entity/position.dart';
import 'entity/service_status.dart';
import 'traccar_flutter_platform_interface.dart';

/// A Flutter library to integrate with the Traccar native SDKs for Android and iOS.
///
/// This class provides methods to initialize the Traccar SDK, configure settings,
/// start/stop the tracking service, access status logs, and stream position updates.
class TraccarFlutter {
  static final TraccarFlutter _instance = TraccarFlutter._internal();

  factory TraccarFlutter() => _instance;

  TraccarFlutter._internal() {
    TraccarFlutterPlatform.instance.setMethodCallHandler(_handleMethodCall);
  }

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  final StreamController<ServiceStatus> _statusController =
      StreamController<ServiceStatus>.broadcast();

  /// Stream of position updates from the tracking service.
  ///
  /// Listen to this stream to receive real-time location updates:
  /// ```dart
  /// TraccarFlutter().positionStream.listen((position) {
  ///   print('Location: ${position.latitude}, ${position.longitude}');
  /// });
  /// ```
  Stream<Position> get positionStream => _positionController.stream;

  /// Stream of service status updates.
  ///
  /// Listen to this stream to receive real-time service status changes:
  /// ```dart
  /// TraccarFlutter().statusStream.listen((status) {
  ///   print('Service status: ${status.displayName}');
  /// });
  /// ```
  Stream<ServiceStatus> get statusStream => _statusController.stream;

  /// Handles method calls from native platforms
  Future<void> _handleMethodCall(String method, dynamic arguments) async {
    switch (method) {
      case 'onPositionUpdate':
        final position = Position.fromMap(arguments as Map<String, dynamic>);
        _positionController.add(position);
        break;
      case 'onStatusUpdate':
        final status = ServiceStatus.fromString(arguments as String);
        _statusController.add(status);
        break;
      default:
        print('Unknown method call from native: $method');
    }
  }

  /// Disposes resources used by the Traccar service.
  void dispose() {
    _positionController.close();
    _statusController.close();
  }
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

  /// Gets the current status of the tracking service.
  ///
  /// This method queries the native platform to determine if the service
  /// is stopped, starting, running, stopping, or in an error state.
  ///
  /// Returns a [Future] that completes with the current [ServiceStatus].
  ///
  /// Example:
  /// ```dart
  /// final status = await TraccarFlutter().getStatus();
  /// if (status.isActive) {
  ///   print('Service is running');
  /// }
  /// ```
  Future<ServiceStatus> getStatus() async {
    final result = await TraccarFlutterPlatform.instance.getServiceStatus();
    return ServiceStatus.fromString(result ?? 'stopped');
  }
}
