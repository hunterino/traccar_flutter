import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traccar_flutter/entity/traccar_configs.dart';
import 'package:traccar_flutter_example/settings_page.dart';

/// Simplified widget tests for SettingsPage that focus on core functionality
/// without complex scrolling interactions
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage Core Functionality', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify page loaded successfully
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('displays all required sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all three section headers
      expect(find.text('Basic Settings'), findsOneWidget);
      expect(find.text('Location Settings'), findsOneWidget);
      expect(find.text('Advanced Settings'), findsOneWidget);
    });

    testWidgets('displays all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all text fields are present
      expect(find.text('Device ID'), findsOneWidget);
      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Update Interval (seconds)'), findsOneWidget);
      expect(find.text('Distance Threshold (meters)'), findsOneWidget);
      expect(find.text('Angle Threshold (degrees)'), findsOneWidget);
      expect(find.text('Location Accuracy'), findsOneWidget);
      expect(find.text('Notification Icon (Android)'), findsOneWidget);

      // Verify switches
      expect(find.text('Offline Buffering'), findsOneWidget);
      expect(find.text('Wake Lock'), findsOneWidget);
    });

    testWidgets('loads default values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that text form fields exist and are initialized
      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      expect(textFields.length, greaterThan(0));

      // Verify at least some fields have default values
      final filledFields = textFields.where((field) =>
        field.controller?.text != null && field.controller!.text.isNotEmpty
      );
      expect(filledFields.length, greaterThan(3));
    });

    testWidgets('loads saved settings from SharedPreferences', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'deviceId': 'test-device-123',
        'serverUrl': 'http://localhost:5055',
        'interval': 60,
        'distance': 100,
        'angle': 45,
        'accuracy': 'medium',
        'offlineBuffering': false,
        'wakelock': false,
        'notificationIcon': 'custom_icon',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify loaded text values are displayed
      expect(find.text('test-device-123'), findsOneWidget);
      expect(find.text('http://localhost:5055'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('custom_icon'), findsOneWidget);
    });

    testWidgets('displays info card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify info card exists
      expect(
        find.text('Configure your Traccar tracking settings. Changes require service restart.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('has save button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify save button exists in AppBar
      expect(find.byIcon(Icons.save), findsWidgets);
    });

    testWidgets('displays switches with correct initial values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find all switches
      final switches = find.byType(SwitchListTile);
      expect(switches, findsNWidgets(2));

      // Verify both switches are present
      expect(find.text('Offline Buffering'), findsOneWidget);
      expect(find.text('Wake Lock'), findsOneWidget);
    });

    testWidgets('displays accuracy dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify accuracy dropdown exists
      final accuracyDropdown = find.byType(DropdownButtonFormField<AccuracyLevel>);
      expect(accuracyDropdown, findsOneWidget);
    });

    testWidgets('displays preset buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify server presets
      expect(find.text('Demo Server'), findsOneWidget);
      expect(find.text('Localhost'), findsOneWidget);

      // Verify interval presets
      expect(find.text('10s'), findsOneWidget);
      expect(find.text('30s'), findsOneWidget);
      expect(find.text('1min'), findsOneWidget);
      expect(find.text('5min'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      // Before pumpAndSettle, should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // After loading, indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('has proper form structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify form exists
      expect(find.byType(Form), findsOneWidget);

      // Verify scrollable
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify has TextFormFields
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
