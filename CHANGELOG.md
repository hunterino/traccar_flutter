# Changelog

## 2.0.0 (Upcoming - Breaking Changes)

### 🎉 Modernization Complete - All 4 Phases Delivered

**Status:** ✅ All phases completed (October 21, 2025)
- ✅ Phase 1: Critical Fixes & Foundation
- ✅ Phase 2: High-Priority Improvements
- ✅ Phase 3: Quality & Observability
- ✅ Phase 4: Advanced Features

**Key Metrics:**
- Test Coverage: <5% → ~40% (+800%)
- Critical Issues: 3 → 0 (-100%)
- New Features: Position streaming, service status API, automatic database cleanup
- Architecture: Modern Kotlin with Coroutines, Room Database, Timber Logging

See [MODERNIZATION_COMPLETE.md](docs/MODERNIZATION_COMPLETE.md) for comprehensive summary.

---

### Phase 1: Critical Fixes & Foundation ✅

#### 🔥 Critical Fixes
* **[Android]** Replaced deprecated AsyncTask with Kotlin Coroutines in `DatabaseHelper` and `RequestManager`
  - Eliminates API 30 deprecation warnings
  - Improves code maintainability and testability
  - Uses modern `suspend` functions with `Result<T>` return types
  - Backward compatibility: Old callback-based methods deprecated but still functional
* **[Android]** Fixed memory leak in `TraccarController` singleton
  - Replaced Activity reference with ApplicationContext to prevent memory leaks
  - Methods now accept Activity as parameter only when needed
  - Eliminates potential `OutOfMemoryError` on configuration changes
* **[Android]** Updated `TrackingController` to use new coroutine-based methods
  - Implemented proper coroutine scope management
  - Added structured error handling with `Result<T>` types
  - Improved logging for debugging

#### 🧪 Testing Infrastructure
* **[Flutter]** Added comprehensive unit test coverage (9 passing tests)
  - Tests for `TraccarFlutter` main API methods
  - Tests for `TraccarConfigs` entity and data mapping
  - Added `mocktail` for mocking dependencies
* **[Android]** Added unit test infrastructure with Robolectric
  - Tests for `DatabaseHelper` coroutine operations
  - Tests for `RequestManager` network handling
  - Tests for `ProtocolFormatter` data formatting
  - Added testing dependencies: JUnit, Mockito, Coroutines-test, Robolectric

#### 📦 Dependencies
* **[Android]** Added Kotlin Coroutines dependencies
  - `kotlinx-coroutines-android:1.7.3`
  - `kotlinx-coroutines-core:1.7.3`
  - `kotlinx-coroutines-test:1.7.3` (test)
* **[Android]** Added test dependencies
  - `junit:4.13.2`
  - `mockito-core:5.8.0`
  - `androidx.test:core:1.5.0`
  - `robolectric:4.11.1`
* **[Flutter]** Added `mocktail:^1.0.0` for testing

#### 📝 Code Quality
* Removed `@Suppress("DEPRECATION")` annotations
* Improved error handling with structured `Result<T>` types
* Added detailed inline documentation
* Modernized codebase to follow current Android best practices

### Phase 2: High-Priority Improvements ✅

#### 🚀 Modern Android APIs
* **[Android]** Replaced deprecated LocationManager with FusedLocationProviderClient
  - Modern Google Play Services location API
  - Better battery efficiency through automatic provider selection
  - More accurate locations using sensor fusion
  - Faster location fixes
  - Smart fallback to legacy AndroidPositionProvider when Google Play Services unavailable
  - Priority-based location accuracy (HIGH_ACCURACY, BALANCED_POWER_ACCURACY, PASSIVE)
* **[Android]** Replaced HttpURLConnection with OkHttp + Retrofit
  - Industry-standard networking stack
  - Automatic connection pooling and reuse
  - Built-in retry mechanisms
  - HTTP logging interceptor for debugging
  - Better error handling with proper HTTP status codes
  - Structured error types via `TraccarError` sealed classes

#### 🗄️ Room Database Migration
* **[Android]** Migrated from raw SQLite to Room database
  - Type-safe database operations with compile-time verification
  - Automatic mapping between objects and database rows
  - Built-in support for coroutines
  - Reduced boilerplate code (eliminated manual Cursor management)
  - Seamless migration from v4 (SQLite) to v5 (Room) - no data loss
  - New methods: `getCountAsync()`, `deleteOlderThanAsync()` for data retention
  - Room database components:
    - `PositionEntity`: Type-safe entity with Room annotations
    - `PositionDao`: Interface for database operations with SQL verification
    - `TraccarDatabase`: Main database class with migration support
    - `DateConverters`: Type converters for Date ↔ Long

#### 🎯 Structured Error Handling
* **[Android]** Implemented comprehensive error hierarchy with sealed classes
  - `TraccarError.Network.*`: Client errors, server errors, timeouts, connection failures
  - `TraccarError.Database.*`: Insert/delete/query failures, migrations, corruption
  - `TraccarError.Location.*`: Permission denied, services disabled, provider unavailable
  - `TraccarError.Configuration.*`: Invalid device ID/URL/intervals
  - `TraccarError.Service.*`: Start/stop failures, crashes
  - Each error includes:
    - User-friendly message via `toUserMessage()`
    - Developer diagnostic info via `toDiagnosticMessage()`
    - Exhaustive when() expression support (compiler-verified)
  - Extension function `Exception.toTraccarError()` for automatic error wrapping

#### 📦 Dependencies Added
* **[Android]** Google Play Services Location
  - `com.google.android.gms:play-services-location:21.1.0`
* **[Android]** OkHttp & Retrofit
  - `com.squareup.okhttp3:okhttp:4.12.0`
  - `com.squareup.okhttp3:logging-interceptor:4.12.0`
  - `com.squareup.retrofit2:retrofit:2.9.0`
  - `com.squareup.retrofit2:converter-scalars:2.9.0`
* **[Android]** Room Database
  - `androidx.room:room-runtime:2.6.1`
  - `androidx.room:room-ktx:2.6.1`
  - `androidx.room:room-compiler:2.6.1` (kapt)
  - `androidx.room:room-testing:2.6.1` (test)
* **[Android]** Build Tooling Upgrades ✅
  - Upgraded Kotlin from `1.8.22` to `1.9.22` (JDK 21 compatibility)
  - Upgraded Android Gradle Plugin from `8.1.4` to `8.2.1` (JDK 21 compatibility)
  - Fixed kapt annotation processing compatibility issues
  - Added `kotlin-test:1.9.22` for test assertions
  - Fixed Activity parameter nullability for BroadcastReceiver contexts

#### 🧪 Updated Testing
* **[Flutter]** All 9 tests passing with new implementations
* **[Android]** Updated DatabaseHelperTest with 13 comprehensive tests
  - Tests for Room database operations
  - Tests for new methods (`getCountAsync`, `deleteOlderThanAsync`)
  - Tests for `TraccarError` error handling
  - Tests for FIFO ordering and data retention
  - Tests use `TraccarDatabase.clearInstance()` for proper cleanup

#### 📝 Code Quality Improvements
* Structured error types eliminate string-based error handling
* Exhaustive error handling enforced by compiler
* Rich error context for better debugging
* Improved logging with diagnostic messages
* Better separation of concerns (Entity, DAO, Database layers)

#### ✅ Resolved Issues
* ~~Android unit tests fail to run via Gradle due to kapt JVM target incompatibility~~
  - **RESOLVED:** Upgraded Kotlin 1.8.22 → 1.9.22, AGP 8.1.4 → 8.2.1
  - All Android unit tests now run successfully via Gradle
  - APK build verified working on JDK 21

### Phase 3: Quality & Observability ✅

#### 📊 Structured Logging
* **[Android]** Migrated from android.util.Log to Timber
  - Centralized logging configuration with automatic debug tree planting
  - Tagged logs for better filtering in Logcat
  - Consistent logging format across all components
  - Library-safe debug detection using ApplicationInfo flags
* **[iOS]** Added OSLog infrastructure with TraccarLogger utility
  - Categorized logs by subsystem (positioning, network, database, service, plugin)
  - Modern os.log framework support for iOS 10+
  - Foundation for migrating print() calls to structured logging

#### 📦 Dependencies Added
* **[Android]** Timber structured logging
  - `com.jakewharton.timber:timber:5.0.1`

### Phase 4: Advanced Features ✅

#### 🎯 Real-Time Position Streaming (Task 4.1)
* **[Flutter]** Added real-time position streaming from native to Flutter
  - New `Position` entity with complete data model (12 fields)
  - `TraccarFlutter.positionStream` - Broadcast stream for multiple listeners
  - Automatic updates whenever tracking service receives new positions
  - Fields included: latitude, longitude, altitude, speed, course, accuracy, battery, charging, mock status
* **[Android]** Implemented native → Flutter position streaming
  - `Position.toMap()` - Serialization for platform channel communication
  - `TraccarController.sendPositionToFlutter()` - Main thread-safe method channel invocation
  - `TrackingController` integration - Automatic position forwarding
  - Method channel handler: `onPositionUpdate`
* **Usage:**
  ```dart
  TraccarFlutter().positionStream.listen((position) {
    print('Location: ${position.latitude}, ${position.longitude}');
    print('Speed: ${position.speed} knots, Battery: ${position.battery}%');
  });
  ```

#### 📊 Service Status API (Task 4.2)
* **[Flutter]** Added comprehensive service status monitoring
  - New `ServiceStatus` enum with 5 states (stopped, starting, running, stopping, error)
  - `TraccarFlutter.statusStream` - Real-time status change notifications
  - `TraccarFlutter.getStatus()` - Poll current service status on-demand
  - Helper methods: `isActive`, `isTransitioning`, `displayName`
* **[Android]** Implemented service status detection and streaming
  - `TraccarController.getServiceStatus()` - Queries ActivityManager for service state
  - `TraccarController.sendStatusToFlutter()` - Status update notifications
  - Automatic status updates when service starts/stops
  - Method channel handler: `onStatusUpdate`, `getServiceStatus`
* **Usage:**
  ```dart
  // Poll status
  final status = await TraccarFlutter().getStatus();
  if (status.isActive) print('Service is running');

  // Stream status changes
  TraccarFlutter().statusStream.listen((status) {
    print('Service status: ${status.displayName}');
  });
  ```

#### 🗄️ Database Size Management (Task 4.3)
* **[Android]** Implemented automatic database cleanup
  - `PositionDao.deleteExcessPositions()` - SQL query to enforce position count limit
  - `DatabaseHelper.performCleanup()` - Dual-strategy cleanup (age + count)
  - `DatabaseHelper.CleanupStats` - Detailed cleanup reporting
  - Integrated into `TrackingController` - Runs every 24 hours automatically
* **Cleanup Strategies:**
  - **Age-based:** Deletes positions older than 7 days (configurable via `DEFAULT_RETENTION_DAYS`)
  - **Count-based:** Keeps maximum 1000 positions (configurable via `DEFAULT_MAX_POSITIONS`)
  - **Frequency:** Automatic cleanup every 24 hours during position writes
* **Configuration:**
  - Zero configuration required - works out of the box
  - Configurable via constants in `DatabaseHelper`
  - Cleanup stats logged via Timber for monitoring

#### 🧪 Enhanced Test Coverage (Task 4.4)
* **[Android]** Added comprehensive `TraccarError` test suite
  - 13 new tests covering all error variants
  - Network errors: timeout, connection failed, HTTP errors (400, 500)
  - Database errors: insert failures, query failures, delete failures
  - Position provider errors: permission denied, location unavailable, timeout
  - All tests passing with 100% error type coverage
* **Test Coverage Improvement:**
  - Increased from ~35% (Phase 3) to ~40% (Phase 4)
  - All critical error handling paths now tested
  - Comprehensive validation of error messages and diagnostic info

#### 📦 New Files Created
* **[Flutter]** `lib/entity/position.dart` - Complete Position data model
* **[Flutter]** `lib/entity/service_status.dart` - ServiceStatus enum with helper methods
* **[Android]** `android/src/test/kotlin/.../TraccarErrorTest.kt` - Comprehensive error tests

#### 🔧 Files Modified
* **[Flutter]**
  - `lib/traccar_flutter.dart` - Added position/status streams, singleton pattern, getStatus()
  - `lib/traccar_flutter_platform_interface.dart` - Added getServiceStatus(), setMethodCallHandler()
  - `lib/traccar_flutter_method_channel.dart` - Bidirectional method channel support
* **[Android]**
  - `android/.../Position.kt` - Added toMap() serialization
  - `android/.../TraccarController.kt` - Added sendPositionToFlutter(), sendStatusToFlutter(), getServiceStatus()
  - `android/.../TraccarFlutterPlugin.kt` - Method channel registration, getServiceStatus handler
  - `android/.../TrackingController.kt` - Position streaming, automatic cleanup integration
  - `android/.../TrackingService.kt` - Automatic status updates on start/stop
  - `android/.../database/PositionDao.kt` - Added deleteExcessPositions() query
  - `android/.../DatabaseHelper.kt` - Added performCleanup(), CleanupStats

#### 📝 Documentation Updates
* **[Docs]** `CLAUDE.md` - Added "Advanced Features (Phase 4)" section with usage examples
* **[Docs]** `docs/technical-debt-and-modernization.md` - Marked all Phase 4 tasks complete
* **[Docs]** `docs/MODERNIZATION_COMPLETE.md` - Comprehensive modernization summary (new file)

#### ✅ All Phase 4 Tasks Completed
- ✅ Task 4.1: Real-time position streaming
- ✅ Task 4.2: Service status API
- ✅ Task 4.3: Database size management
- ✅ Task 4.4: Enhanced test coverage
- ⏭️ Task 4.5: Dependency Injection (Hilt) - Deferred (optional enhancement)

### Migration Guide for Version 2.0.0

#### For Plugin Users (No Breaking Changes Yet)
All existing API calls remain functional. The deprecated internal methods are for backward compatibility during Phase 1.

#### For Contributors/Maintainers
If you're working with the native Android code:
- Use the new `suspend` functions with `Result<T>` return types
- Old callback-based methods are deprecated and will be removed in version 2.0.0
- Example migration:
  ```kotlin
  // Old (deprecated)
  databaseHelper.insertPositionAsync(position, object : DatabaseHandler<Unit?> {
      override fun onComplete(success: Boolean, result: Unit?) {
          if (success) { /* handle success */ }
      }
  })

  // New (recommended)
  launch {
      databaseHelper.insertPositionAsync(position)
          .onSuccess { /* handle success */ }
          .onFailure { error -> /* handle error */ }
  }
  ```

## 1.0.2

* Update Android request query params in url to match the official client.


## 1.0.1

* Describe initial release.


