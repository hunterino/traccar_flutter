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
