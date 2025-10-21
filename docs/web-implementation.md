# Web Implementation Guide

## Overview

The `traccar_flutter` plugin now supports web platforms using the browser's native Geolocation API. This allows location tracking in web browsers without requiring platform channels or native code.

## Features

The web implementation provides:

- **Browser Geolocation** - Uses `navigator.geolocation.watchPosition()` for continuous location tracking
- **Settings Persistence** - Stores configuration in browser localStorage
- **Offline Buffering** - Queues position updates when server is unreachable (up to 100 positions)
- **Interval-based Tracking** - Sends updates based on time interval
- **Distance-based Tracking** - Sends updates based on distance traveled
- **Accuracy Control** - Supports high/medium/low accuracy modes
- **Status Monitoring** - Shows tracking status via browser alert dialog

## How It Works

### Location Tracking

The web implementation uses the browser's Geolocation API:

```dart
final stream = html.window.navigator.geolocation!.watchPosition(
  enableHighAccuracy: true,
  timeout: Duration(milliseconds: 30000),
  maximumAge: Duration(milliseconds: 0),
);

stream.listen((position) {
  // Process location update
});
```

### Position Updates

Updates are sent when:
1. **Time interval** elapsed (e.g., every 30 seconds)
2. **Distance threshold** exceeded (e.g., moved 100 meters)
3. **Both conditions** met (configurable via `TraccarConfigs`)

### Data Storage

Configuration is persisted in browser localStorage:
- `traccar_flutter_deviceId`
- `traccar_flutter_serverUrl`
- `traccar_flutter_interval`
- `traccar_flutter_distance`
- `traccar_flutter_angle`
- `traccar_flutter_accuracy`
- `traccar_flutter_offlineBuffering`

## Browser Permissions

The web app requires location permission from the user. The permission prompt appears when `startService()` is called:

```dart
await TraccarFlutter().startService();
// Browser shows: "Allow [site] to access your location?"
```

## CORS Considerations

### The Challenge

Web browsers enforce CORS (Cross-Origin Resource Sharing) security. When your web app runs on one domain (e.g., `myapp.com`) and tries to send data to a Traccar server on another domain (e.g., `traccar.example.com`), the browser blocks the request unless the server explicitly allows it.

### Expected Behavior

When running from `localhost` during development:
```
Failed to send position to http://demo.traccar.org:5055?id=...
Note: If you see a CORS error, the Traccar server needs to enable CORS headers.
For production, deploy your web app to the same domain as your Traccar server.
```

This is **normal and expected** - the location tracking is working correctly, but the HTTP request is blocked by browser security.

### Solutions

#### Option 1: Enable CORS on Traccar Server (Recommended for Development)

Add CORS headers to your Traccar server configuration:

```xml
<!-- In traccar.xml -->
<entry key='web.origin'>*</entry>
```

Or configure your web server (nginx/Apache) to add CORS headers:

```nginx
# nginx example
location /api {
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'Content-Type';
}
```

#### Option 2: Same-Origin Deployment (Recommended for Production)

Deploy your Flutter web app to the same domain as your Traccar server:

```
https://tracking.example.com/app/     <- Flutter web app
https://tracking.example.com/api/     <- Traccar server
```

No CORS configuration needed when both are on the same domain.

#### Option 3: CORS Proxy (Development Only)

Use a CORS proxy during development:

```dart
TraccarConfigs(
  serverUrl: 'https://cors-anywhere.herokuapp.com/http://demo.traccar.org:5055',
  // ... other configs
)
```

**Warning:** Never use CORS proxies in production - they can expose sensitive data.

## Testing

### Local Testing

```bash
# Run web app in Chrome
cd example
flutter run -d chrome
```

The app will:
1. Request location permission
2. Start tracking GPS coordinates
3. Attempt to send to configured server (may fail due to CORS)

### Production Testing

1. Build the web app:
```bash
flutter build web --release
```

2. Deploy to your web server:
```bash
cp -r build/web/* /var/www/html/
```

3. Access from same domain as Traccar server

## Browser Compatibility

### Supported Browsers

- Chrome/Edge 50+
- Firefox 55+
- Safari 11+
- Opera 37+

### Required Features

- Geolocation API (`navigator.geolocation`)
- LocalStorage
- ES6 features (Promises, async/await)

### Mobile Browsers

The web implementation works on mobile browsers:
- Chrome Mobile (Android)
- Safari (iOS)
- Firefox Mobile
- Samsung Internet

**Note:** Mobile web tracking is less reliable than native apps. For production mobile tracking, use the native Android/iOS implementations.

## Limitations

### 1. Background Tracking

Web browsers **cannot track location in the background**. Tracking stops when:
- Browser tab is closed
- User switches to another tab (on mobile)
- Device sleeps

For reliable background tracking, use native Android/iOS apps.

### 2. Battery API

The web implementation returns a fixed battery level of 100%:

```dart
double _getBatteryLevel() {
  // Web doesn't have reliable battery API access
  return 100.0;
}
```

The Battery Status API is deprecated and not available in most browsers.

### 3. Wakelock

The `wakelock` config parameter is ignored on web (no effect):

```dart
TraccarConfigs(
  wakelock: true,  // Ignored on web platform
)
```

### 4. Notifications

The `notificationIcon` parameter is ignored on web (no foreground service concept).

### 5. Accuracy

GPS accuracy on web depends on:
- Device hardware (phone GPS vs laptop WiFi triangulation)
- Browser implementation
- User's location settings

Generally less accurate than native implementations.

## Example Usage

```dart
import 'package:traccar_flutter/traccar_flutter.dart';

final traccar = TraccarFlutter();

// Initialize
await traccar.initTraccar();

// Configure
await traccar.setConfigs(TraccarConfigs(
  deviceId: 'web-device-001',
  serverUrl: 'https://tracking.example.com/api',  // Same domain!
  interval: 30000,        // 30 seconds
  distance: 100,          // 100 meters
  accuracy: AccuracyLevel.high,
  offlineBuffering: true,
));

// Start tracking
await traccar.startService();

// Stop tracking
await traccar.stopService();

// View status
await traccar.showStatusLogs();
```

## Security Considerations

### HTTPS Required

Modern browsers require HTTPS for geolocation (except localhost):

- ✅ `https://myapp.com` - Works
- ✅ `http://localhost` - Works (development only)
- ❌ `http://myapp.com` - Blocked by browser

### LocalStorage Privacy

Configuration data is stored in browser localStorage:
- Persists between sessions
- Accessible to JavaScript on same domain
- Not encrypted
- Cleared when user clears browser data

**Recommendation:** Don't store sensitive tokens in configs on web.

## Troubleshooting

### Permission Denied

**Error:** "Location permission denied"

**Solution:** User must grant permission in browser. Check browser settings:
- Chrome: Settings → Privacy and security → Site Settings → Location
- Firefox: about:permissions
- Safari: Preferences → Websites → Location Services

### CORS Errors

**Error:** "Failed to send position"

**Solution:** See [CORS Considerations](#cors-considerations) section above.

### No Location Updates

**Causes:**
1. Permission not granted
2. Device has no GPS (desktop computer)
3. Browser tab in background (mobile)
4. WiFi/GPS disabled in OS

**Debug:**
```dart
TraccarFlutter().positionStream.listen((position) {
  print('Location: ${position.latitude}, ${position.longitude}');
});
```

### High Battery Drain

Web tracking uses continuous GPS which drains battery on mobile devices.

**Solution:** Increase interval to reduce power consumption:
```dart
TraccarConfigs(
  interval: 300000,  // 5 minutes instead of 30 seconds
)
```

## Performance

### Network Usage

Each position update sends ~200 bytes:
```
http://server:5055?id=123&lat=40.7&lon=-111.6&timestamp=...&speed=0&bearing=0&altitude=0&accuracy=10&batt=100
```

At 30-second intervals: ~5.7 KB/hour or ~137 KB/day

### CPU Usage

Minimal CPU usage:
- GPS polling handled by browser
- JavaScript only processes position updates
- No heavy computations

### Memory Usage

~5-10 MB including:
- Flutter framework
- App code
- Offline buffer (up to 100 positions)

## Future Enhancements

Potential improvements:
1. **Service Workers** - Background sync when browser supports it
2. **IndexedDB** - More robust offline storage
3. **WebSocket** - Real-time bidirectional communication
4. **Battery Status API** - When/if browsers re-enable it
5. **Wake Lock API** - Keep screen on during tracking

## Comparison: Web vs Native

| Feature | Web | Android | iOS |
|---------|-----|---------|-----|
| Background tracking | ❌ No | ✅ Yes | ✅ Yes |
| Automatic restart | ❌ No | ✅ Yes | ✅ Yes |
| Battery efficiency | ⚠️ Medium | ✅ High | ✅ High |
| Setup complexity | ✅ Simple | ⚠️ Medium | ⚠️ Complex |
| Distribution | ✅ Instant | ⚠️ Store | ⚠️ Store |
| Offline capability | ⚠️ Limited | ✅ Full | ✅ Full |
| CORS issues | ❌ Yes | ✅ No | ✅ No |

**Recommendation:** Use web for:
- Quick demos
- Dashboard applications
- Desktop tracking
- Temporary tracking needs

Use native (Android/iOS) for:
- Production mobile tracking
- 24/7 background tracking
- Fleet management
- Critical tracking applications
