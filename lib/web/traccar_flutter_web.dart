import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';
import 'package:traccar_flutter/traccar_flutter_platform_interface.dart';

/// Web implementation of TraccarFlutter
class TraccarFlutterWeb extends TraccarFlutterPlatform {
  /// Registers the web plugin
  static void registerWith(Registrar registrar) {
    TraccarFlutterPlatform.instance = TraccarFlutterWeb();
  }

  TraccarConfigs? _configs;
  html.Geoposition? _lastPosition;
  DateTime? _lastSendTime;
  bool _isTracking = false;
  final List<Map<String, dynamic>> _offlineBuffer = [];
  Timer? _intervalTimer;
  StreamSubscription<html.Geoposition>? _positionSubscription;

  static const String _storagePrefix = 'traccar_flutter_';

  @override
  Future<String?> initTraccar() async {
    try {
      // Check if geolocation is available
      if (html.window.navigator.geolocation == null) {
        return 'Geolocation is not supported by this browser';
      }

      // Load saved configs from localStorage
      _loadConfigs();

      return 'Traccar Web initialized successfully';
    } catch (e) {
      return 'Initialization failed: $e';
    }
  }

  @override
  Future<String?> setConfigs(TraccarConfigs configs) async {
    try {
      _configs = configs;
      _saveConfigs();
      return 'Configuration saved successfully';
    } catch (e) {
      return 'Failed to save configuration: $e';
    }
  }

  @override
  Future<String?> startService() async {
    try {
      if (_configs == null) {
        return 'Please configure Traccar first';
      }

      if (_isTracking) {
        return 'Service is already running';
      }

      // Request permission by getting current position
      try {
        await html.window.navigator.geolocation!.getCurrentPosition();
      } catch (e) {
        return 'Location permission denied. Please enable location access in your browser.';
      }

      _isTracking = true;
      _lastSendTime = null;

      // Start watching position
      _startLocationTracking();

      // Start interval-based sending
      final interval = _configs!.interval ?? 30000;
      if (interval > 0) {
        _startIntervalTimer(interval);
      }

      return 'Tracking started successfully';
    } catch (e) {
      _isTracking = false;
      return 'Failed to start tracking: $e';
    }
  }

  @override
  Future<String?> stopService() async {
    try {
      _isTracking = false;

      // Stop watching position
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // Stop interval timer
      _intervalTimer?.cancel();
      _intervalTimer = null;

      _lastPosition = null;
      _lastSendTime = null;

      return 'Tracking stopped successfully';
    } catch (e) {
      return 'Failed to stop tracking: $e';
    }
  }

  @override
  Future<String?> showStatusLogs() async {
    // Create a simple status popup for web
    final status = '''
Traccar Flutter Web Status:
- Device ID: ${_configs?.deviceId ?? 'Not configured'}
- Server URL: ${_configs?.serverUrl ?? 'Not configured'}
- Tracking: ${_isTracking ? 'Active' : 'Inactive'}
- Last position: ${_lastPosition != null ? 'Available' : 'None'}
- Offline buffer: ${_offlineBuffer.length} positions
''';

    html.window.alert(status);
    return 'Status displayed';
  }

  @override
  Future<String?> getServiceStatus() async {
    return _isTracking ? 'running' : 'stopped';
  }

  @override
  void setMethodCallHandler(Future<void> Function(String method, dynamic arguments)? handler) {
    // Web implementation doesn't need bidirectional method channel
    // Native platforms use this to send position updates back to Dart,
    // but web implementation handles position updates directly in Dart
  }

  void _startLocationTracking() {
    if (!_isTracking) return;

    final options = {
      'enableHighAccuracy': _configs!.accuracy == AccuracyLevel.high,
      'timeout': 30000,
      'maximumAge': 0,
    };

    // Use watchPosition with a Stream
    final stream = html.window.navigator.geolocation!.watchPosition(
      enableHighAccuracy: options['enableHighAccuracy'] as bool,
      timeout: Duration(milliseconds: options['timeout'] as int),
      maximumAge: Duration(milliseconds: options['maximumAge'] as int),
    );

    _positionSubscription = stream.listen(
      (html.Geoposition position) {
        _handleNewPosition(position);
      },
      onError: (error) {
        print('Location error: $error');
      },
    );
  }

  void _startIntervalTimer(int intervalMs) {
    _intervalTimer?.cancel();

    if (intervalMs <= 0) return;

    _intervalTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_lastPosition != null && _isTracking) {
        _sendPosition(_lastPosition!);
      }
    });
  }

  void _handleNewPosition(html.Geoposition position) {
    if (!_isTracking) return;

    final shouldSend = _shouldSendPosition(position);
    _lastPosition = position;

    if (shouldSend) {
      _sendPosition(position);
    }
  }

  bool _shouldSendPosition(html.Geoposition newPosition) {
    if (_lastPosition == null) return true;
    if (_configs == null) return false;

    // Check interval
    if (_lastSendTime != null) {
      final elapsed = DateTime.now().difference(_lastSendTime!).inMilliseconds;
      final interval = _configs!.interval ?? 30000;
      if (elapsed < interval) {
        return false;
      }
    }

    // Check distance
    final distance = _configs!.distance ?? 0;
    if (distance > 0) {
      final actualDistance = _calculateDistance(
        _lastPosition!.coords!.latitude!.toDouble(),
        _lastPosition!.coords!.longitude!.toDouble(),
        newPosition.coords!.latitude!.toDouble(),
        newPosition.coords!.longitude!.toDouble(),
      );

      if (actualDistance < distance.toDouble()) {
        return false;
      }
    }

    return true;
  }

  Future<void> _sendPosition(html.Geoposition position) async {
    if (_configs == null) return;

    _lastSendTime = DateTime.now();

    final data = {
      'id': _configs!.deviceId,
      'lat': position.coords!.latitude,
      'lon': position.coords!.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'speed': position.coords!.speed ?? 0,
      'bearing': position.coords!.heading ?? 0,
      'altitude': position.coords!.altitude ?? 0,
      'accuracy': position.coords!.accuracy ?? 0,
      'batt': _getBatteryLevel(),
    };

    try {
      await _sendToServer(data);

      // Send any offline buffered positions
      if (_offlineBuffer.isNotEmpty) {
        final buffered = List<Map<String, dynamic>>.from(_offlineBuffer);
        _offlineBuffer.clear();

        for (final bufferedData in buffered) {
          await _sendToServer(bufferedData);
        }
      }
    } catch (e) {
      print('Failed to send position: $e');

      // Buffer for offline sending if enabled
      if (_configs!.offlineBuffering == true) {
        _offlineBuffer.add(data);

        // Limit buffer size
        if (_offlineBuffer.length > 100) {
          _offlineBuffer.removeAt(0);
        }
      }
    }
  }

  Future<void> _sendToServer(Map<String, dynamic> data) async {
    if (_configs == null) return;

    final url = _buildTraccarUrl(data);

    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        requestHeaders: {
          'Accept': 'application/json',
        },
      );

      if (response.status != 200) {
        throw Exception('Server returned ${response.status}: ${response.statusText}');
      }

      print('Position sent successfully to server');
    } catch (e) {
      // CORS error is common when running web apps from localhost
      // This is expected browser security behavior
      print('Failed to send position to $url');
      print('Note: If you see a CORS error, the Traccar server needs to enable CORS headers.');
      print('For production, deploy your web app to the same domain as your Traccar server.');
      rethrow;
    }
  }

  String _buildTraccarUrl(Map<String, dynamic> data) {
    final baseUrl = _configs!.serverUrl.endsWith('/')
        ? _configs!.serverUrl.substring(0, _configs!.serverUrl.length - 1)
        : _configs!.serverUrl;

    final params = <String, String>{
      'id': data['id'].toString(),
      'lat': data['lat'].toString(),
      'lon': data['lon'].toString(),
      'timestamp': data['timestamp'].toString(),
      'speed': data['speed'].toString(),
      'bearing': data['bearing'].toString(),
      'altitude': data['altitude'].toString(),
      'accuracy': data['accuracy'].toString(),
      'batt': data['batt'].toString(),
    };

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$query';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  double _getBatteryLevel() {
    // Web doesn't have direct battery API access in all browsers
    // Return a default value
    return 100.0;
  }

  void _saveConfigs() {
    if (_configs == null) return;

    html.window.localStorage['${_storagePrefix}deviceId'] = _configs!.deviceId;
    html.window.localStorage['${_storagePrefix}serverUrl'] = _configs!.serverUrl;
    html.window.localStorage['${_storagePrefix}interval'] = _configs!.interval.toString();
    html.window.localStorage['${_storagePrefix}distance'] = _configs!.distance.toString();
    html.window.localStorage['${_storagePrefix}angle'] = _configs!.angle.toString();
    html.window.localStorage['${_storagePrefix}accuracy'] = _configs!.accuracy.name;
    html.window.localStorage['${_storagePrefix}offlineBuffering'] = _configs!.offlineBuffering.toString();
  }

  void _loadConfigs() {
    final deviceId = html.window.localStorage['${_storagePrefix}deviceId'];
    final serverUrl = html.window.localStorage['${_storagePrefix}serverUrl'];

    if (deviceId == null || serverUrl == null) {
      return;
    }

    final interval = int.tryParse(html.window.localStorage['${_storagePrefix}interval'] ?? '30000') ?? 30000;
    final distance = int.tryParse(html.window.localStorage['${_storagePrefix}distance'] ?? '0') ?? 0;
    final angle = int.tryParse(html.window.localStorage['${_storagePrefix}angle'] ?? '0') ?? 0;
    final accuracyStr = html.window.localStorage['${_storagePrefix}accuracy'] ?? 'high';
    final accuracy = AccuracyLevel.values.firstWhere(
      (e) => e.name == accuracyStr,
      orElse: () => AccuracyLevel.high,
    );
    final offlineBuffering = html.window.localStorage['${_storagePrefix}offlineBuffering'] == 'true';

    _configs = TraccarConfigs(
      deviceId: deviceId,
      serverUrl: serverUrl,
      interval: interval,
      distance: distance,
      angle: angle,
      accuracy: accuracy,
      offlineBuffering: offlineBuffering,
      wakelock: false, // Not applicable for web
      notificationIcon: '', // Not applicable for web
    );
  }
}
