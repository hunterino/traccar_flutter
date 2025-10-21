# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`traccar_flutter` is a Flutter plugin that integrates with the Traccar location tracking platform. It acts as a bridge to native Android (Kotlin) and iOS (Swift) implementations of the Traccar SDK, enabling seamless background location tracking across both platforms.

**Key Architecture Points:**
- This is a platform plugin following Flutter's federated plugin architecture
- The Dart layer defines the API surface and communicates via MethodChannel
- Native implementations (Android/iOS) handle actual location tracking, network communication, and persistence
- The native code is based on the official Traccar client SDKs with modifications for Flutter integration

## Development Commands

### Flutter Development
```bash
# Get dependencies
flutter pub get

# Run linter
flutter analyze

# Run the example app (requires Android/iOS setup)
cd example && flutter run

# Clean build artifacts
flutter clean
```

### Android Development
```bash
# Build Android library
cd android && ./gradlew build

# Run Android tests (if available)
cd android && ./gradlew test
```

### iOS Development
```bash
# Install CocoaPods dependencies
cd example/ios && pod install

# Build from example app
cd example && flutter build ios
```

## Code Architecture

### Flutter Layer (Dart)
- **`lib/traccar_flutter.dart`**: Main public API that Flutter apps interact with
- **`lib/traccar_flutter_platform_interface.dart`**: Abstract interface defining platform contracts
- **`lib/traccar_flutter_method_channel.dart`**: MethodChannel implementation for platform communication
- **`lib/entity/`**: Data models (`TraccarConfigs`, `AccuracyLevel`)

### Android Layer (Kotlin)
Located in `android/src/main/kotlin/dev/mostafamovahhed/traccar_flutter/`:

- **`TraccarFlutterPlugin.kt`**: Flutter plugin entry point, handles MethodChannel calls and activity lifecycle
- **`client/TraccarController.kt`**: Singleton controller managing service lifecycle, permissions, and SharedPreferences
- **`client/TrackingService.kt`**: Foreground service for continuous location tracking
- **`client/TrackingController.kt`**: Coordinates position updates and network requests
- **`client/PositionProvider.kt`** & **`AndroidPositionProvider.kt`**: Location acquisition using Android Location APIs
- **`client/DatabaseHelper.kt`**: SQLite database for offline buffering of positions
- **`client/NetworkManager.kt`** & **`client/RequestManager.kt`**: HTTP communication with Traccar server
- **`client/ProtocolFormatter.kt`**: Formats location data into Traccar protocol URL format
- **`client/StatusActivity.kt`**: Native UI for viewing service logs

**Android Key Patterns:**
- Uses SharedPreferences for configuration persistence
- Implements foreground service with notification for background tracking
- Permission handling includes location (fine, coarse, background) and notification permissions
- AlarmManager ensures service restarts after reboot via `AutostartReceiver`

### iOS Layer (Swift)
Located in `ios/Classes/`:

- **`TraccarFlutterPlugin.swift`**: Flutter plugin entry point, handles MethodChannel calls
- **`TraccarController.swift`**: Singleton controller managing service lifecycle and Core Data
- **`TrackingController.swift`**: Coordinates position updates and network requests
- **`PositionProvider.swift`**: Location acquisition using CoreLocation
- **`DatabaseHelper.swift`**: Core Data wrapper for offline buffering
- **`NetworkManager.swift`** & **`RequestManager.swift`**: URLSession-based HTTP communication
- **`ProtocolFormatter.swift`**: Formats location data into Traccar protocol URL format
- **`StatusViewController.swift`**: Native UI for viewing service logs
- **`PreferenceKeys.swift`**: UserDefaults key definitions

**iOS Key Patterns:**
- Uses UserDefaults for configuration persistence
- Uses Core Data for position database (TraccarClient.sqlite)
- CoreLocation for background location tracking with region monitoring
- Notification center for app lifecycle events

### Method Channel Communication
Both platforms implement these methods:
- `init`: Initialize native SDK and setup
- `setConfigs`: Configure tracking parameters (device ID, server URL, intervals, etc.)
- `startService`: Start location tracking service
- `stopService`: Stop location tracking service
- `statusActivity`: Show native debug/status screen

Configuration parameters passed via `TraccarConfigs.toMap()` include:
- `deviceId`, `serverUrl` (required)
- `interval`, `distance`, `angle` (location update thresholds)
- `accuracy` (low/medium/high)
- `offlineBuffering`, `wakelock` (Android only)
- `notificationIcon` (Android only - custom icon name)

## Important Implementation Notes

### Native Code Origins
The native Android and iOS implementations are adapted from the official Traccar client repositories:
- Android: https://github.com/traccar/traccar-client-android
- iOS: https://github.com/traccar/traccar-client-ios

Both retain original Apache 2.0 license headers. When modifying native code, maintain compatibility with Traccar's protocol and server expectations.

### Permission Handling
- **Android**: The plugin handles runtime permission requests internally via `TraccarController`. Permissions include location (fine, coarse, background) and POST_NOTIFICATIONS (Android 13+)
- **iOS**: Location permissions must be handled by the host app; the plugin assumes permissions are granted when `startService` is called

### Offline Buffering
Both platforms persist location data locally when the server is unreachable:
- **Android**: SQLite via `DatabaseHelper` (stores positions with timestamps, retries on next successful connection)
- **iOS**: Core Data managed by `TraccarController` (same retry logic)

### Background Tracking Reliability
- **Android**: Uses foreground service with persistent notification; `AutostartReceiver` ensures restart after device reboot; battery optimization dialog may be shown for certain manufacturers
- **iOS**: Relies on CoreLocation background modes; tracking continues when app is backgrounded but iOS may suspend if battery is low

### Configuration State Management
- **Android**: SharedPreferences in default app preferences
- **iOS**: UserDefaults with `PreferenceKeys` enum
- Both platforms persist `serviceStatus` to auto-restart tracking after app restarts

## Known Technical Debt

For complete details, see `docs/technical-debt-and-modernization.md`.

**Critical Issues:**
- **Android**: Uses deprecated AsyncTask (deprecated in API 30) - requires migration to Kotlin Coroutines
- **Android**: Memory leak potential in singleton holding Activity reference
- **Test Coverage**: < 5% across all layers - makes refactoring risky

**High Priority:**
- Android uses deprecated LocationManager instead of modern FusedLocationProviderClient
- Android uses HttpURLConnection instead of OkHttp/Retrofit
- iOS has force unwraps (`!`) that could cause crashes
- No structured error handling (methods return `String?` instead of Result types)
- Unbounded database growth (no size limits or expiration policy)

**Impact:** The plugin is functional but requires modernization for long-term maintainability. See the modernization roadmap in `docs/` for detailed implementation guides.

## Platform-Specific Behavior

**Configuration Parameters:**
- `wakelock`: Android only (ignored on iOS)
- `notificationIcon`: Android only (ignored on iOS)
- Parameters are silently ignored on non-applicable platforms

**Permission Handling:**
- **Android**: Plugin handles runtime permissions internally via permission dialogs
- **iOS**: Host app MUST request and obtain permissions before calling `startService()`
- Different integration patterns required per platform

**Error Handling:**
- Both platforms return simple success strings (`"initialized successfully"`) or null
- No structured error codes or detailed exception messages
- Difficult to provide specific user feedback on failures

## Testing Status

**Current State:**
- **Dart**: 1 integration test, 0 unit tests
- **Android**: 0 tests (test infrastructure present in build.gradle)
- **iOS**: 0 tests

**Before Making Changes:**
Given the minimal test coverage, exercise extreme caution when refactoring:
- Always test on real devices (simulators have limited location capabilities)
- Test offline buffering by disconnecting network mid-session
- Verify service persistence across app kills and device reboots
- Use Android Profiler / Xcode Instruments to check for memory leaks
- Test on both platforms as behavior differs significantly

## Common Development Tasks

### Adding a New Configuration Parameter
1. Add property to `TraccarConfigs` in `lib/entity/traccar_configs.dart`
2. Update `toMap()` method to include new parameter
3. Update Android `TraccarController.setConfigs()` to read and store via SharedPreferences
4. Update iOS `TraccarController.setConfigs()` to read and store via UserDefaults
5. Use the parameter in the respective position/tracking logic

### Modifying Location Tracking Behavior
- **Android**: Edit `AndroidPositionProvider.kt` (currently uses deprecated LocationManager - migration to FusedLocationProviderClient planned)
- **iOS**: Edit `PositionProvider.swift` (uses CLLocationManager)
- Consider how changes affect battery consumption and accuracy

### Debugging Native Issues
- **Android**: Use `TraccarController.addStatusLog()` to log to `StatusActivity`
- **iOS**: Use `TraccarController.addStatusLog()` to log to `StatusViewController`
- Both platforms show logs in native status screens accessible via `showStatusLogs()`

### Testing the Plugin
- Test on real devices for location and background behavior (simulators have limitations)
- Verify permissions flow on both platforms
- Test offline buffering by disconnecting network and reconnecting
- Test service persistence across app kills and device reboots
- Verify foreground service notification appears on Android

## Package Publishing
- Version is managed in `pubspec.yaml` (currently 1.0.2+4)
- Update `CHANGELOG.md` with user-facing changes
- Package is published to pub.dev: https://pub.dev/packages/traccar_flutter
- Maintained by Mostafa Movahhed (not an official Traccar project)

## Advanced Features (Phase 4)

The plugin includes several advanced features implemented in Phase 4 of the modernization roadmap:

### Real-Time Position Streaming

**Flutter API:**
```dart
// Listen to position updates in real-time
TraccarFlutter().positionStream.listen((position) {
  print('Location: ${position.latitude}, ${position.longitude}');
  print('Speed: ${position.speed} knots');
  print('Battery: ${position.battery}%');
});
```

**Implementation Details:**
- Positions are streamed from native → Flutter via method channel (TraccarFlutterPlugin.kt:118, TraccarController.kt:84-94)
- Position model includes 12 fields: lat/lon, altitude, speed, course, accuracy, battery, charging, mock (lib/entity/position.dart)
- Updates are sent whenever TrackingController receives new positions (TrackingController.kt:75)
- Uses broadcast streams for multiple listeners

### Service Status API

**Flutter API:**
```dart
// Get current service status
final status = await TraccarFlutter().getStatus();
if (status.isActive) {
  print('Service is running');
}

// Listen to status changes
TraccarFlutter().statusStream.listen((status) {
  print('Service status: ${status.displayName}');
});
```

**ServiceStatus States:**
- `stopped`: Service is not running
- `starting`: Service is initializing (transitional)
- `running`: Service is actively tracking
- `stopping`: Service is shutting down (transitional)
- `error`: Service encountered an error

**Implementation Details:**
- Status is queried via ActivityManager on Android (TraccarController.kt:347-366)
- Automatic status updates sent when service starts/stops (TrackingService.kt:52, 89)
- Helper methods: `isActive`, `isTransitioning`, `displayName` (lib/entity/service_status.dart)

### Database Size Management

**Automatic Cleanup:**
The plugin automatically manages database size to prevent unbounded growth:

- **Retention Policy**: Deletes positions older than 7 days (configurable)
- **Size Limit**: Keeps maximum 1000 positions (configurable)
- **Cleanup Frequency**: Runs every 24 hours during position writes
- **Zero Configuration**: Works out of the box with sensible defaults

**Implementation Details:**
- `PositionDao.deleteOlderThan()`: Removes positions by age (PositionDao.kt:85-86)
- `PositionDao.deleteExcessPositions()`: Enforces maximum count (PositionDao.kt:96-113)
- `DatabaseHelper.performCleanup()`: Combines both strategies (DatabaseHelper.kt:287-318)
- Triggered automatically in TrackingController (TrackingController.kt:132-147)
- Configurable via `DEFAULT_RETENTION_DAYS` and `DEFAULT_MAX_POSITIONS` constants

**Cleanup Statistics:**
```kotlin
data class CleanupStats(
    val deletedByAge: Int,      // Positions deleted due to age
    val deletedByLimit: Int,    // Positions deleted to enforce limit
    val totalDeleted: Int       // Total positions removed
)
```

## Additional Documentation

For in-depth technical analysis and modernization guidance, see:

- **`docs/architecture-analysis.md`**: Comprehensive architectural analysis including:
  - Layer-by-layer code quality assessment (Dart, Android, iOS)
  - Data flow analysis and communication patterns
  - Performance characteristics and battery impact
  - Security analysis and best practices comparison
  - Detailed strengths/weaknesses of each platform implementation

- **`docs/technical-debt-and-modernization.md`**: Complete technical debt inventory with:
  - Prioritized list of 23+ technical debt items with effort estimates
  - 4-phase modernization roadmap with implementation guides
  - Code examples showing before/after migrations
  - Breaking change analysis and migration strategies
  - Success metrics and ROI calculation
