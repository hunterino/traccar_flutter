import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traccar_flutter/entity/position.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';
import 'package:traccar_flutter/traccar_flutter.dart';

import 'settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traccar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _traccarFlutterPlugin = TraccarFlutter();
  final MapController _mapController = MapController();
  bool isServiceStarted = false;
  String? traccingMessage;
  String? currentDeviceId;
  String? currentServerUrl;
  int? currentInterval;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _startListeningToPosition();
  }

  void _startListeningToPosition() {
    _positionSubscription = _traccarFlutterPlugin.positionStream.listen(
      (position) {
        setState(() {
          _currentPosition = position;
        });

        // Auto-center map on new position
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      },
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await _loadAndApplySettings();
  }

  Future<void> _loadAndApplySettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load settings with defaults
    final deviceId = prefs.getString('deviceId') ?? '1241234123';
    final serverUrl = prefs.getString('serverUrl') ?? 'http://demo.traccar.org:5055';
    final intervalSeconds = prefs.getInt('interval') ?? 30;
    final distance = prefs.getInt('distance') ?? 0;
    final angle = prefs.getInt('angle') ?? 0;
    final notificationIcon = prefs.getString('notificationIcon') ?? 'ic_notification';

    // Load accuracy level
    final accuracyString = prefs.getString('accuracy') ?? 'high';
    final accuracy = AccuracyLevel.values.firstWhere(
      (e) => e.name == accuracyString,
      orElse: () => AccuracyLevel.high,
    );

    final offlineBuffering = prefs.getBool('offlineBuffering') ?? true;
    final wakelock = prefs.getBool('wakelock') ?? true;

    setState(() {
      currentDeviceId = deviceId;
      currentServerUrl = serverUrl;
      currentInterval = intervalSeconds;
    });

    // Initialize and configure Traccar
    traccingMessage = await _traccarFlutterPlugin.initTraccar();
    traccingMessage = await _traccarFlutterPlugin.setConfigs(TraccarConfigs(
      deviceId: deviceId,
      serverUrl: serverUrl,
      interval: intervalSeconds * 1000, // Convert seconds to milliseconds
      distance: distance,
      angle: angle,
      accuracy: accuracy,
      offlineBuffering: offlineBuffering,
      wakelock: wakelock,
      notificationIcon: notificationIcon,
    ));

    setState(() {});
  }

  Future<void> _openSettings() async {
    final settingsChanged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    // If settings were saved, reload and reapply them
    if (settingsChanged == true) {
      setState(() {
        traccingMessage = 'Settings updated. Restart service to apply.';
      });
      await _loadAndApplySettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Traccar Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isServiceStarted ? Icons.check_circle : Icons.circle_outlined,
                            color: isServiceStarted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isServiceStarted ? 'Service Running' : 'Service Stopped',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (traccingMessage != null)
                        Text(
                          traccingMessage!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuration Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Configuration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _ConfigRow(
                        icon: Icons.smartphone,
                        label: 'Device ID',
                        value: currentDeviceId ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _ConfigRow(
                        icon: Icons.cloud,
                        label: 'Server',
                        value: currentServerUrl ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _ConfigRow(
                        icon: Icons.timer,
                        label: 'Interval',
                        value: currentInterval != null ? '${currentInterval}s' : '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Map Widget
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 300,
                  child: _buildMapWidget(),
                ),
              ),
              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _traccarFlutterPlugin.showStatusLogs();
                      },
                      icon: const Icon(Icons.analytics),
                      label: const Text('View Logs'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _toggleService,
                      icon: Icon(isServiceStarted ? Icons.stop : Icons.play_arrow),
                      label: Text(isServiceStarted ? 'Stop' : 'Start'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: isServiceStarted ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildMapWidget() {
    // Default center (San Francisco) if no position yet
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(37.7749, -122.4194);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.mostafamovahhed.traccar_flutter.example',
          maxZoom: 19,
        ),
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        if (_currentPosition != null && _currentPosition!.accuracy > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                radius: _currentPosition!.accuracy,
                useRadiusInMeter: true,
                color: Colors.blue.withValues(alpha: 0.1),
                borderColor: Colors.blue.withValues(alpha: 0.3),
                borderStrokeWidth: 2,
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _toggleService() async {
    try {
      String? result;
      if (isServiceStarted) {
        result = await _traccarFlutterPlugin.stopService();
      } else {
        result = await _traccarFlutterPlugin.startService();
      }
      setState(() {
        traccingMessage = result;
        isServiceStarted = !isServiceStarted;
      });
    } catch (e) {
      setState(() {
        traccingMessage = e.toString();
      });
    }
  }
}

class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
