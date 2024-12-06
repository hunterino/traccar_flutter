# Traccar Flutter

A Flutter library to integrate with the [Traccar](https://www.traccar.org/) tracking platform. This package acts as a bridge to the native Android and iOS implementations of the Traccar SDK, enabling seamless location tracking and configuration.

---

## Contact

If you have any questions or need support regarding the `traccar_flutter` plugin, feel free to reach out to me:

- [Mostafa Movahhed on LinkedIn](https://www.linkedin.com/in/mostafamovahhed)

I’ll be happy to assist you!

---

## Features
- Cross-platform support for **Android** and **iOS**.
- Provides methods to:
  - Initialize the Traccar service.
  - Configure tracking settings.
  - Start and stop the tracking service.
  - View service status logs.
- Uses the official Traccar native SDKs for Android and iOS for reliable and efficient tracking.


## Native Traccar SDKs
This library leverages the following native SDKs:
- [Traccar Android SDK](https://github.com/traccar/traccar-client-android)
- [Traccar iOS SDK](https://github.com/traccar/traccar-client-ios)

---

### Required Permissions

To ensure the proper functionality of this plugin, you need to add the following permissions to your application.

#### **Android**
In your `AndroidManifest.xml`, include the following permissions:

```xml
<!-- Permissions for location access -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Permissions for Traccar service -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!-- Manufacturer-specific permissions -->
<uses-permission android:name="oppo.permission.OPPO_COMPONENT_SAFE" />
<uses-permission android:name="com.huawei.permission.external_app_settings.USE_COMPONENT" />

<!-- Hardware features -->
<uses-feature android:name="android.hardware.location.network" />
<uses-feature android:name="android.hardware.location.gps" />
```

Make sure to also handle runtime permissions for Android 6.0 (API level 23) and above.

#### **iOS**
In your `Info.plist` file, add the following keys to define the permissions required for location tracking:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This is a tracking application and therefore requires access to location services</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This is a tracking application and therefore requires access to location services</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This is a tracking application and therefore requires access to location services</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

These permissions are required for the app to access location services in both foreground and background modes.

---

### Additional Notes:
- **Android**: Ensure you dynamically request location permissions at runtime for Android API level 23 or higher.
- **iOS**: Location permissions must be granted by the user. When using background location updates, ensure compliance with Apple's App Store guidelines.

---

## Installation
Add the following to your `pubspec.yaml`:
```yaml
dependencies:
  traccar_flutter: ^1.0.0
```

Run:
```bash
flutter pub get
```

## Usage
Here’s how to use the `TraccarFlutter` package:

### Import the package
```dart
import 'package:traccar_flutter/traccar_flutter.dart';
```

### Example Code
```dart
import 'package:traccar_flutter/traccar_flutter.dart';

void main() async {
  final traccar = TraccarFlutter();

  // Initialize the service
  await traccar.initTraccar();

  // Set configurations
  final configs = TraccarConfigs(
    deviceId: 'your-device-id',
    serverUrl: 'http://demo.traccar.org:5055',
    interval: 15000, // 15 seconds
    accuracy: AccuracyLevel.high,
    offlineBuffering: true,
  );
  await traccar.setConfigs(configs);

  // Start the tracking service
  await traccar.startService();

  // Optional: View status logs
  final logs = await traccar.showStatusLogs();
  print('Service Logs: $logs');
}
```

---

### Configuration Parameters

| **Parameter**        | **Type**           | **Required** | **Default Value** | **Description**                                                                                  |
|-----------------------|--------------------|--------------|-------------------|--------------------------------------------------------------------------------------------------|
| `deviceId`           | `String`          | ✅           | -                 | Unique identifier for the device.                                                              |
| `serverUrl`          | `String`          | ✅           | -                 | URL of the Traccar server where location data will be sent.                                     |
| `accuracy`           | `AccuracyLevel`   | ❌           | `AccuracyLevel.high` | Defines the desired location accuracy (Low, Medium, High).                                      |
| `interval`           | `int` (milliseconds) | ❌           | `10000` (10 seconds) | Time interval between location updates.                                                        |
| `distance`           | `int` (meters)    | ❌           | `0`               | Minimum distance (in meters) required to trigger a location update.                            |
| `angle`              | `int` (degrees)   | ❌           | `0`               | Angle threshold to trigger a location update based on direction changes.                       |
| `offlineBuffering`   | `bool`            | ❌           | `true`            | Enables offline buffering of location updates when the device is offline.                      |
| `wakelock`           | `bool`            | ❌           | `true`            | Keeps the device awake while the tracking service is running.                                   |
| `notificationIcon`   | `String`          | ❌           | `null`            | Name of the custom notification icon for the tracking service. Must be present in app assets.   |

---

### Example Usage:
```dart
final configs = TraccarConfigs(
  deviceId: 'unique-device-id',
  serverUrl: 'http://demo.traccar.org:5055',
  interval: 15000, // Send updates every 15 seconds
  distance: 10,    // Send updates after moving 10 meters
  angle: 30,       // Send updates when direction changes by 30 degrees
  accuracy: AccuracyLevel.high, // Use high accuracy mode
  offlineBuffering: true, // Enable offline data storage
  wakelock: true, // Keep device awake
  notificationIcon: 'custom_icon', // Optional notification icon
);
```

---

## Contributions
Feel free to submit issues or contribute to the library by creating a pull request.

## License
This library is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.

---