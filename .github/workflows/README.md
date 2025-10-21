# GitHub Actions Workflows

## Build Android APK

The `build-android.yml` workflow automatically builds Android APK files for the example app.

### Triggers

The workflow runs on:
- **Push** to the `main` branch
- **Pull requests** to the `main` branch
- **Manual trigger** via GitHub Actions UI (workflow_dispatch)

### What it does

1. **Sets up the environment:**
   - Checks out the code
   - Installs Java 17 (Temurin distribution)
   - Installs Flutter 3.35.6 (stable channel)
   - Caches Gradle and Flutter dependencies for faster builds

2. **Runs quality checks:**
   - `flutter analyze` - Checks code for potential issues
   - `flutter test` - Runs unit tests (continues even if tests fail)

3. **Builds APKs:**
   - Debug APK (`app-debug.apk`)
   - Release APK (`app-release.apk`)

4. **Uploads artifacts:**
   - Both APKs are uploaded as artifacts
   - Artifacts are retained for 30 days
   - APK size information is logged

### Downloading APKs

After a workflow run completes:

1. Go to the workflow run in GitHub Actions
2. Scroll to the "Artifacts" section at the bottom
3. Download either:
   - `android-debug-apk` - Debug build with debugging symbols
   - `android-release-apk` - Optimized release build

### Local Testing

To test the build process locally:

```bash
# Debug build
cd example
flutter build apk --debug

# Release build
flutter build apk --release

# Find the APKs
ls -lh build/app/outputs/flutter-apk/
```

### Build Configuration

The workflow uses:
- **Java Version:** 17 (Temurin)
- **Flutter Version:** 3.35.6 (stable)
- **Runner:** ubuntu-latest

### Known Warnings

The current project has some version warnings that don't affect the build but should be addressed:
- Gradle version (8.3.0) should be upgraded to 8.7.0+
- Android Gradle Plugin (8.2.1) should be upgraded to 8.6.0+
- Kotlin version (1.9.22) should be upgraded to 2.1.0+

These warnings don't prevent the APK from building successfully.

### Troubleshooting

**Build fails with Gradle errors:**
- Check the Java version (should be 17)
- Clear Gradle cache: `./gradlew clean` in the `android` directory

**Build fails with dependency errors:**
- Run `flutter pub get` in both root and example directories
- Check that all dependencies in `pubspec.yaml` are compatible

**APK won't install on device:**
- Debug APKs are signed with a debug certificate
- For production, you'll need to sign the release APK with your keystore

---

## Build iOS App

The `build-ios.yml` workflow automatically builds iOS app bundles for the example app.

### Triggers

The workflow runs on:
- **Push** to the `main` branch
- **Pull requests** to the `main` branch
- **Manual trigger** via GitHub Actions UI (workflow_dispatch)

### What it does

1. **Sets up the environment:**
   - Checks out the code
   - Installs Flutter 3.35.6 (stable channel)
   - Installs CocoaPods dependencies
   - Caches Flutter dependencies for faster builds

2. **Runs quality checks:**
   - `flutter analyze` - Checks code for potential issues
   - `flutter test` - Runs unit tests (continues even if tests fail)

3. **Builds iOS apps:**
   - Simulator build (Debug) - For testing in iOS Simulator
   - Device build (Debug, unsigned) - For reference/testing

4. **Packages and uploads:**
   - Creates ZIP archives of both builds
   - Uploads as downloadable artifacts
   - Artifacts are retained for 30 days
   - Build size information is logged

### Downloading iOS Builds

After a workflow run completes:

1. Go to the workflow run in GitHub Actions
2. Scroll to the "Artifacts" section at the bottom
3. Download either:
   - `ios-simulator-debug` - For iOS Simulator (43 MB)
   - `ios-device-debug` - For reference (29 MB, unsigned)

### Local Testing

To test the build process locally:

```bash
cd example

# Simulator build (for testing in iOS Simulator)
flutter build ios --simulator --debug

# Device build (unsigned, for reference)
flutter build ios --debug --no-codesign

# Find the builds
ls -lh build/ios/Debug-iphonesimulator/Runner.app
ls -lh build/ios/Debug-iphoneos/Runner.app
```

### Build Configuration

The workflow uses:
- **Flutter Version:** 3.35.6 (stable)
- **Runner:** macos-latest (macOS is required for iOS builds)
- **CocoaPods:** Automatically installed on macOS runners

### Important Notes

**Code Signing:**
- The device builds created by this workflow are **unsigned**
- These builds cannot be installed on real iOS devices
- For production or TestFlight distribution, you need:
  - Apple Developer account
  - Provisioning profiles
  - Code signing certificates
  - Use `flutter build ipa` with proper signing

**Simulator Builds:**
- Can be run in Xcode Simulator on macOS
- Unzip the artifact and drag the `.app` bundle to the simulator
- Useful for testing without a physical device

**Cost Considerations:**
- macOS runners on GitHub Actions are more expensive than Linux runners
- Consider limiting the workflow to run only on main branch or tagged releases
- Free tier includes limited macOS runner minutes

### Troubleshooting

**Build fails with CocoaPods errors:**
- Delete `Podfile.lock` and `Pods/` directory
- Run `pod install` in the `ios` directory
- Ensure CocoaPods is up to date: `pod --version`

**Build fails with Xcode errors:**
- Check Xcode version on runner (should be latest stable)
- Verify iOS deployment target in `ios/Podfile`
- Check minimum iOS version in `ios/Podfile`

**Cannot run on device:**
- Device builds require code signing
- Use the simulator build for testing
- For device testing, build locally with your signing credentials

---

## Build Web App

The `build-web.yml` workflow automatically builds the Flutter web app for the example app.

### Triggers

The workflow runs on:
- **Push** to the `main` branch
- **Pull requests** to the `main` branch
- **Manual trigger** via GitHub Actions UI (workflow_dispatch)

### What it does

1. **Sets up the environment:**
   - Checks out the code
   - Installs Flutter 3.35.6 (stable channel)
   - Caches Flutter dependencies for faster builds

2. **Runs quality checks:**
   - `flutter analyze` - Checks code for potential issues
   - `flutter test` - Runs unit tests (continues even if tests fail)

3. **Builds web app:**
   - Release build optimized for production
   - Tree-shakes icons to reduce bundle size
   - Creates deployment-ready web directory

4. **Packages and uploads:**
   - Creates ZIP archive of build output
   - Includes BUILD_INFO.txt with deployment instructions
   - Uploads as downloadable artifact
   - Artifacts are retained for 30 days
   - Build size information is logged

### Downloading Web Build

After a workflow run completes:

1. Go to the workflow run in GitHub Actions
2. Scroll to the "Artifacts" section at the bottom
3. Download `web-release` (~30 MB ZIP file)
4. Extract and deploy to your web server

### Local Testing

To test the build process locally:

```bash
cd example

# Release build (production)
flutter build web --release

# Find the build
ls -lh build/web

# Test locally with a web server
python3 -m http.server 8000 --directory build/web
# Then visit http://localhost:8000
```

### Build Configuration

The workflow uses:
- **Flutter Version:** 3.35.6 (stable)
- **Runner:** ubuntu-latest
- **Build Type:** Release (optimized)

### Build Output

The web build includes:
- `index.html` - Entry point
- `main.dart.js` - Compiled Dart code (~2.4 MB)
- `flutter.js` - Flutter framework
- `assets/` - App assets and fonts
- `canvaskit/` - Canvas rendering library
- `icons/` - App icons
- `manifest.json` - PWA manifest

**Total size:** ~30 MB uncompressed, ~8-10 MB when served with gzip

### Deployment

After downloading the artifact:

1. **Extract the ZIP:**
   ```bash
   unzip web-release.zip
   cd web
   ```

2. **Upload to your web server:**
   ```bash
   # Example: Upload to your server
   scp -r * user@yourserver.com:/var/www/html/
   ```

3. **Configure web server:**
   - Enable HTTPS (required for geolocation)
   - Enable gzip compression for `.js` and `.wasm` files
   - Set proper MIME types
   - Configure CORS headers if needed

4. **Test deployment:**
   - Visit your deployed app
   - Grant location permission when prompted
   - Verify tracking works correctly

### Important Notes

**HTTPS Required:**
- Modern browsers require HTTPS for geolocation API
- Localhost is exempted during development
- Production deployment MUST use HTTPS

**CORS Configuration:**
- If web app and Traccar server are on different domains
- Server must send `Access-Control-Allow-Origin` header
- See [Web Implementation Guide](../../docs/web-implementation.md)

**Browser Support:**
- Chrome/Edge 50+
- Firefox 55+
- Safari 11+
- Opera 37+

**Background Tracking:**
- Web cannot track location when tab is closed
- This is a browser limitation, not a bug
- For 24/7 tracking, use native Android/iOS apps

### Deployment Examples

**Nginx configuration:**
```nginx
server {
    listen 443 ssl;
    server_name tracking.example.com;

    # SSL certificates
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Web app
    location / {
        root /var/www/traccar-flutter-web;
        try_files $uri $uri/ /index.html;
    }

    # CORS headers (if Traccar is on different domain)
    location /api {
        proxy_pass http://traccar-server:5055;
        add_header 'Access-Control-Allow-Origin' 'https://tracking.example.com';
    }
}
```

**Apache configuration:**
```apache
<VirtualHost *:443>
    ServerName tracking.example.com

    # SSL configuration
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem

    # Enable compression
    AddOutputFilterByType DEFLATE text/html text/plain text/css application/json application/javascript

    # Web app directory
    DocumentRoot /var/www/traccar-flutter-web

    <Directory /var/www/traccar-flutter-web>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted

        # Rewrite for single-page app
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^ index.html [L]
    </Directory>
</VirtualHost>
```

### Troubleshooting

**Build fails with compilation errors:**
- Ensure web implementation is correct in `lib/web/`
- Check that `pubspec.yaml` includes `flutter_web_plugins`
- Run `flutter clean` and try again

**Large bundle size:**
- 30 MB is normal for Flutter web apps (includes framework)
- Enable gzip on web server (reduces to ~8-10 MB transferred)
- Consider code splitting for very large apps

**Geolocation not working:**
- Ensure HTTPS is enabled (required for production)
- Check browser console for permission errors
- Verify user granted location permission

**CORS errors in production:**
- Configure Traccar server to send CORS headers
- Or deploy web app and Traccar on same domain
- See [Web Implementation Guide](../../docs/web-implementation.md) for solutions

**Performance issues:**
- Enable gzip compression on server
- Use CDN for static assets
- Check browser console for errors
- Verify network tab shows proper caching

### Performance Optimization

**Server-side:**
```nginx
# Cache static assets
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Compress JavaScript
gzip on;
gzip_comp_level 6;
gzip_types application/javascript;
```

**Build optimizations:**
```bash
# Build with optimizations
flutter build web --release --web-renderer canvaskit

# Or use html renderer for smaller size
flutter build web --release --web-renderer html
```

### Known Warnings

**WebAssembly (Wasm):**
- Current implementation uses `dart:html` which is not compatible with Wasm
- This is expected and does not affect functionality
- JavaScript version works perfectly
- Future versions may migrate to Wasm-compatible APIs

The warning can be suppressed with:
```bash
flutter build web --release --no-wasm-dry-run
```
