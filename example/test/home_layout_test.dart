import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traccar_flutter_example/main.dart';

/// Regression tests for the home page layout.
///
/// The body used to be a plain [Column] holding two cards, a fixed 300px map
/// and the action buttons. On any viewport shorter than that content the
/// RenderFlex overflowed and the Start/Stop button was pushed off screen —
/// reproduced on a 640x360 landscape emulator as "BOTTOM OVERFLOWED BY 449
/// PIXELS".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('traccar_flutter');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'ok');
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Renders [MyApp] at a logical size of [width] x [height].
  Future<void> pumpAtSize(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    const devicePixelRatio = 2.0;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.physicalSize =
        Size(width * devicePixelRatio, height * devicePixelRatio);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
  }

  testWidgets('lays out without overflow on a short landscape viewport',
      (WidgetTester tester) async {
    // The exact geometry of the Small Phone API 31 emulator that overflowed.
    await pumpAtSize(tester, width: 640, height: 360);

    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the action buttons on screen when space is tight',
      (WidgetTester tester) async {
    await pumpAtSize(tester, width: 640, height: 360);

    // The primary action must stay reachable rather than being pushed past
    // the bottom edge of the viewport.
    final startButton = find.text('Start');
    expect(startButton, findsOneWidget);
    expect(find.text('View Logs'), findsOneWidget);

    final viewportHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
    expect(tester.getRect(startButton).bottom, lessThanOrEqualTo(viewportHeight));
  });

  testWidgets('still lays out cleanly on a tall phone viewport',
      (WidgetTester tester) async {
    await pumpAtSize(tester, width: 402, height: 874);

    expect(tester.takeException(), isNull);
    expect(find.text('Start'), findsOneWidget);
  });
}
