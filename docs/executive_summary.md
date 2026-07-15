# Executive Summary: Traccar Flutter

## Overview
Traccar Flutter is a Flutter plugin that integrates with the Traccar GPS tracking platform, providing a bridge to native Android (Kotlin) and iOS (Swift) SDKs for seamless background location tracking. It enables Flutter apps to report device positions to a Traccar server with offline buffering, automatic retries, and configurable tracking parameters.

## Technology Stack
- Flutter (Dart), SDK ^3.5.3, published as pub.dev package (v1.0.4)
- Android: Kotlin with Room database, FusedLocationProvider, foreground service
- iOS: Swift with Core Data, CoreLocation
- MethodChannel for Dart-to-native communication
- Traccar protocol (HTTP-based position reporting)

## Status
Production (published on pub.dev)

## Key Features
- Background location tracking on Android and iOS
- Real-time position streaming from native to Flutter via MethodChannel
- Offline buffering with automatic retry (Room on Android, Core Data on iOS)
- Configurable tracking intervals, distance thresholds, and accuracy levels
- Automatic database cleanup (retention days + max positions)
- Service status API with lifecycle state tracking
- Auto-restart after device reboot (Android)
- Battery monitoring and optimization

## Architecture
Federated Flutter plugin architecture with a Dart API surface communicating via MethodChannel to native implementations. Both Android and iOS layers are adapted from official Traccar client SDKs, implementing foreground services (Android) and CoreLocation background modes (iOS) for persistent tracking with local database buffering.

## Target Users
Flutter developers building GPS tracking applications that need to report positions to a Traccar server, such as fleet management, asset tracking, or personal location logging apps.

## Dependencies & Infrastructure
- Traccar server instance (self-hosted or cloud) for receiving position data
- Google Play Services (Android, for FusedLocationProvider)
- CoreLocation framework (iOS)
- No additional cloud services required
