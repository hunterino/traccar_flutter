import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isServiceStarted = false;
  String? traccingMessage;
  String? currentDeviceId;
  String? currentServerUrl;
  int? currentInterval;

  @override
  void initState() {
    super.initState();
    initPlatformState();
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
