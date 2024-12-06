import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';
import 'package:traccar_flutter/traccar_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _traccarFlutterPlugin = TraccarFlutter();
  bool isServiceStarted = false;
  String? traccingMessage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    traccingMessage = await _traccarFlutterPlugin.initTraccar();
    traccingMessage = await _traccarFlutterPlugin.setConfigs(TraccarConfigs(
      deviceId: '1241234123',
      serverUrl: 'http://demo.traccar.org:5055',
      notificationIcon: 'ic_notification',
    ));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Traccar Demo'),
        ),
        body: Center(
          child: Text(
            'Traccar Message: \n\n ${traccingMessage ?? '-'}',
            textAlign: TextAlign.center,
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: () {
                _traccarFlutterPlugin.showStatusLogs();
              },
              child: const Icon(Icons.screenshot_monitor),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _toggleService,
              child: Icon(isServiceStarted ? Icons.stop : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }

  _toggleService() async {
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
