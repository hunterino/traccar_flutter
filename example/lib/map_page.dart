import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_flutter/entity/position.dart';
import 'package:traccar_flutter/traccar_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _traccarFlutterPlugin = TraccarFlutter();
  final MapController _mapController = MapController();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isFollowing = true;

  @override
  void initState() {
    super.initState();
    _startListeningToPosition();
  }

  void _startListeningToPosition() {
    _positionSubscription = _traccarFlutterPlugin.positionStream.listen(
      (position) {
        setState(() {
          _currentPosition = position;
        });

        // Auto-center map on new position if following is enabled
        if (_isFollowing) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _toggleFollowing() {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    if (_isFollowing && _currentPosition != null) {
      _centerOnCurrentPosition();
    }
  }

  void _centerOnCurrentPosition() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default center (San Francisco) if no position yet
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(37.7749, -122.4194);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Map'),
        actions: [
          IconButton(
            icon: Icon(_isFollowing ? Icons.my_location : Icons.location_searching),
            onPressed: _toggleFollowing,
            tooltip: _isFollowing ? 'Following enabled' : 'Following disabled',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                // If user manually moves the map, disable following
                if (hasGesture) {
                  setState(() {
                    _isFollowing = false;
                  });
                }
              },
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
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
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
                              size: 30,
                            ),
                          ),
                        ],
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
          ),

          // Position info card at the bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _currentPosition != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Latitude',
                            value: _currentPosition!.latitude.toStringAsFixed(6),
                          ),
                          _InfoRow(
                            label: 'Longitude',
                            value: _currentPosition!.longitude.toStringAsFixed(6),
                          ),
                          if (_currentPosition!.speed > 0)
                            _InfoRow(
                              label: 'Speed',
                              value: '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                            ),
                          if (_currentPosition!.accuracy > 0)
                            _InfoRow(
                              label: 'Accuracy',
                              value: '${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                            ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'Waiting for location data...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton(
              onPressed: _centerOnCurrentPosition,
              tooltip: 'Center on current location',
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
