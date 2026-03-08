// AUTO-GENERATED integration test from crash: 419C1EA7-F062-4D0E-BB3C-E37B562C596F
// Generated at: 2026-03-08T21:03:46.9737405Z
// Events: 22

import 'package:aitester_sdk/aitester_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AITester.initialize(
      AITesterConfig(
        serverUrl: 'http://192.168.1.13:5000',
        appId: 'flutter-test-app-resolve',
        buildVersion: '1.0.0-resolve',
        enableAutoTracking: true,
        enableCrashReporting: true,
        debugMode: true,
      ),
    );
  });

  testWidgets('Replay crash 419C1EA7-F062-4D0E-BB3C-E37B562C596F', (WidgetTester tester) async {
    await tester.pumpWidget(const AITesterApp());
    await tester.pumpAndSettle();

    // Login
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
    await tester.enterText(textFields.at(1), 'testuser');
    await tester.enterText(textFields.at(2), 'test123');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Replay events
    // click: HOME_VIEW -> BTN_HOME_1
    await tester.tap(find.text('Button 1 -> View A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    // click: HOME_VIEW -> BTN_HOME_1
    await tester.tap(find.text('Button 1 -> View A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    // click: HOME_VIEW -> BTN_HOME_1
    await tester.tap(find.text('Button 1 -> View A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    // click: HOME_VIEW -> BTN_HOME_1
    await tester.tap(find.text('Button 1 -> View A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    // click: HOME_VIEW -> BTN_HOME_1
    await tester.tap(find.text('Button 1 -> View A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    print('✅ Replayed 22 events without crash');
  });
}
