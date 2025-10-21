import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _deviceIdController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _intervalController = TextEditingController();
  final _distanceController = TextEditingController();
  final _angleController = TextEditingController();
  final _notificationIconController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  AccuracyLevel _selectedAccuracy = AccuracyLevel.high;
  bool _offlineBuffering = true;
  bool _wakelock = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _serverUrlController.dispose();
    _intervalController.dispose();
    _distanceController.dispose();
    _angleController.dispose();
    _notificationIconController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _deviceIdController.text = prefs.getString('deviceId') ?? '1241234123';
      _serverUrlController.text = prefs.getString('serverUrl') ?? 'http://demo.traccar.org:5055';
      _intervalController.text = prefs.getInt('interval')?.toString() ?? '30';
      _distanceController.text = prefs.getInt('distance')?.toString() ?? '0';
      _angleController.text = prefs.getInt('angle')?.toString() ?? '0';
      _notificationIconController.text = prefs.getString('notificationIcon') ?? 'ic_notification';

      final accuracyString = prefs.getString('accuracy') ?? 'high';
      _selectedAccuracy = AccuracyLevel.values.firstWhere(
        (e) => e.name == accuracyString,
        orElse: () => AccuracyLevel.high,
      );

      _offlineBuffering = prefs.getBool('offlineBuffering') ?? true;
      _wakelock = prefs.getBool('wakelock') ?? true;

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceId', _deviceIdController.text.trim());
    await prefs.setString('serverUrl', _serverUrlController.text.trim());
    await prefs.setInt('interval', int.parse(_intervalController.text.trim()));
    await prefs.setInt('distance', int.parse(_distanceController.text.trim()));
    await prefs.setInt('angle', int.parse(_angleController.text.trim()));
    await prefs.setString('accuracy', _selectedAccuracy.name);
    await prefs.setBool('offlineBuffering', _offlineBuffering);
    await prefs.setBool('wakelock', _wakelock);
    await prefs.setString('notificationIcon', _notificationIconController.text.trim());

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved! Restart the service to apply changes.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Use Navigator.maybeOf to check if Navigator is available
      if (Navigator.maybeOf(context) != null) {
        Navigator.pop(context, true);
      }
    }
  }

  String? _validateDeviceId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Device ID is required';
    }
    if (value.trim().length < 3) {
      return 'Device ID must be at least 3 characters';
    }
    return null;
  }

  String? _validateServerUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server URL is required';
    }

    final url = value.trim().toLowerCase();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAuthority) {
      return 'Invalid URL format';
    }

    return null;
  }

  String? _validateInterval(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Interval is required';
    }

    final interval = int.tryParse(value.trim());
    if (interval == null) {
      return 'Must be a valid number';
    }

    if (interval < 5) {
      return 'Interval must be at least 5 seconds';
    }

    if (interval > 3600) {
      return 'Interval must be less than 3600 seconds';
    }

    return null;
  }

  String? _validateDistance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Distance is required';
    }

    final distance = int.tryParse(value.trim());
    if (distance == null) {
      return 'Must be a valid number';
    }

    if (distance < 0) {
      return 'Distance cannot be negative';
    }

    return null;
  }

  String? _validateAngle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Angle is required';
    }

    final angle = int.tryParse(value.trim());
    if (angle == null) {
      return 'Must be a valid number';
    }

    if (angle < 0 || angle > 360) {
      return 'Angle must be between 0 and 360';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traccar Settings'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Configure your Traccar tracking settings. Changes require service restart.',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Settings Section
                    _SectionHeader(
                      icon: Icons.settings,
                      title: 'Basic Settings',
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _deviceIdController,
                      decoration: const InputDecoration(
                        labelText: 'Device ID',
                        hintText: 'Enter unique device identifier',
                        prefixIcon: Icon(Icons.smartphone),
                        border: OutlineInputBorder(),
                        helperText: 'Unique identifier for this device',
                      ),
                      validator: _validateDeviceId,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'http://your-server.com:5055',
                        prefixIcon: Icon(Icons.cloud),
                        border: OutlineInputBorder(),
                        helperText: 'Your Traccar server endpoint',
                      ),
                      validator: _validateServerUrl,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16),

                    // Quick Server Presets
                    Wrap(
                      spacing: 8,
                      children: [
                        _PresetChip(
                          label: 'Demo Server',
                          icon: Icons.public,
                          onTap: () => setState(() {
                            _serverUrlController.text = 'http://demo.traccar.org:5055';
                          }),
                        ),
                        _PresetChip(
                          label: 'Localhost',
                          icon: Icons.computer,
                          onTap: () => setState(() {
                            _serverUrlController.text = 'http://localhost:5055';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Location Settings Section
                    _SectionHeader(
                      icon: Icons.location_on,
                      title: 'Location Settings',
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _intervalController,
                      decoration: const InputDecoration(
                        labelText: 'Update Interval (seconds)',
                        hintText: '30',
                        prefixIcon: Icon(Icons.timer),
                        border: OutlineInputBorder(),
                        helperText: 'Time between updates (5-3600 seconds)',
                        suffixText: 'seconds',
                      ),
                      validator: _validateInterval,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: 'Distance Threshold (meters)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.straighten),
                        border: OutlineInputBorder(),
                        helperText: 'Minimum distance to trigger update (0 = disabled)',
                        suffixText: 'meters',
                      ),
                      validator: _validateDistance,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _angleController,
                      decoration: const InputDecoration(
                        labelText: 'Angle Threshold (degrees)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.navigation),
                        border: OutlineInputBorder(),
                        helperText: 'Direction change to trigger update (0 = disabled)',
                        suffixText: 'degrees',
                      ),
                      validator: _validateAngle,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Accuracy Level Dropdown
                    DropdownButtonFormField<AccuracyLevel>(
                      initialValue: _selectedAccuracy,
                      decoration: const InputDecoration(
                        labelText: 'Location Accuracy',
                        prefixIcon: Icon(Icons.gps_fixed),
                        border: OutlineInputBorder(),
                        helperText: 'Higher accuracy uses more battery',
                      ),
                      items: AccuracyLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Icon(
                                _getAccuracyIcon(level),
                                size: 20,
                                color: _getAccuracyColor(level),
                              ),
                              const SizedBox(width: 8),
                              Text(_getAccuracyLabel(level)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAccuracy = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Interval Presets
                    Wrap(
                      spacing: 8,
                      children: [
                        _PresetChip(
                          label: '10s',
                          icon: Icons.timer,
                          onTap: () => setState(() => _intervalController.text = '10'),
                        ),
                        _PresetChip(
                          label: '30s',
                          icon: Icons.timer,
                          onTap: () => setState(() => _intervalController.text = '30'),
                        ),
                        _PresetChip(
                          label: '1min',
                          icon: Icons.timer,
                          onTap: () => setState(() => _intervalController.text = '60'),
                        ),
                        _PresetChip(
                          label: '5min',
                          icon: Icons.timer,
                          onTap: () => setState(() => _intervalController.text = '300'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Advanced Settings Section
                    _SectionHeader(
                      icon: Icons.tune,
                      title: 'Advanced Settings',
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('Offline Buffering'),
                      subtitle: const Text('Store locations when offline and send later'),
                      secondary: const Icon(Icons.cloud_off),
                      value: _offlineBuffering,
                      onChanged: (value) {
                        setState(() {
                          _offlineBuffering = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Wake Lock'),
                      subtitle: const Text('Keep device awake for reliable tracking'),
                      secondary: const Icon(Icons.lock_clock),
                      value: _wakelock,
                      onChanged: (value) {
                        setState(() {
                          _wakelock = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notificationIconController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Icon (Android)',
                        hintText: 'ic_notification',
                        prefixIcon: Icon(Icons.notifications),
                        border: OutlineInputBorder(),
                        helperText: 'Icon name from drawable resources (optional)',
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveSettings(),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getAccuracyIcon(AccuracyLevel level) {
    switch (level) {
      case AccuracyLevel.low:
        return Icons.battery_saver;
      case AccuracyLevel.medium:
        return Icons.battery_std;
      case AccuracyLevel.high:
        return Icons.battery_charging_full;
    }
  }

  Color _getAccuracyColor(AccuracyLevel level) {
    switch (level) {
      case AccuracyLevel.low:
        return Colors.orange;
      case AccuracyLevel.medium:
        return Colors.blue;
      case AccuracyLevel.high:
        return Colors.green;
    }
  }

  String _getAccuracyLabel(AccuracyLevel level) {
    switch (level) {
      case AccuracyLevel.low:
        return 'Low (Battery Saver)';
      case AccuracyLevel.medium:
        return 'Medium (Balanced)';
      case AccuracyLevel.high:
        return 'High (Most Accurate)';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
