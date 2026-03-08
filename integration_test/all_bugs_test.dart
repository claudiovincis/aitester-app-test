import 'package:aitester_sdk/aitester_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AITester.initialize(
      AITesterConfig(serverUrl: 'http://192.168.1.13:5000', appId: 'flutter-test-app-all-bugs', buildVersion: '1.0.0-all-bugs', enableAutoTracking: true, enableCrashReporting: true, debugMode: true),
    );
  });

  testWidgets('Test 1: Division by Zero Bug (Home Button 1 - 5 clicks)', (WidgetTester tester) async {
    await tester.pumpWidget(const AITesterApp());
    await tester.pumpAndSettle();

    // Login
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
    await tester.enterText(textFields.at(1), 'testuser');
    await tester.enterText(textFields.at(2), 'test123');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Home - 3 Pulsanti'), findsOneWidget);

    // Trigger HOME bug with 5 valid entries into View A, returning back each time.
    for (int i = 0; i < 5; i++) {
      final button1 = find.text('Button 1 -> View A');
      expect(button1, findsOneWidget);

      await tester.tap(button1);
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      final exception = tester.takeException();
      if (exception != null) {
        await AITester.reportError(exception, StackTrace.current, viewTag: 'HOME_VIEW');
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      if (i < 4) {
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(milliseconds: 350));
      }
    }

    fail('Expected division by zero error during 5th valid navigation from HOME_VIEW');
  });

  testWidgets('Test 2: Null Pointer Bug (View A - 2 taps)', (WidgetTester tester) async {
    await tester.pumpWidget(const AITesterApp());
    await tester.pumpAndSettle();

    // Login
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
    await tester.enterText(textFields.at(1), 'testuser');
    await tester.enterText(textFields.at(2), 'test123');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to View A (click once to enter, not trigger bug)
    final button1 = find.text('Button 1 -> View A');
    await tester.tap(button1);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Now we're in View A, find the tap button
    final tapButton = find.textContaining('Tap me');
    expect(tapButton, findsOneWidget);
    // Tap once - should be fine
    await tester.tap(tapButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Tap twice - second tap should surface the app null bug.
    await tester.tap(tapButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final exception = tester.takeException();
    if (exception == null) {
      fail('Expected null pointer error on 2nd tap');
    }

    await AITester.reportError(exception, StackTrace.current, viewTag: 'VIEW_A');
    await Future.delayed(const Duration(milliseconds: 500));
  });

  testWidgets('Test 3: JSON Parse Error (Hub Button 2 - 3 clicks)', (WidgetTester tester) async {
    await tester.pumpWidget(const AITesterApp());
    await tester.pumpAndSettle();

    // Login
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
    await tester.enterText(textFields.at(1), 'testuser');
    await tester.enterText(textFields.at(2), 'test123');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to Hub
    await tester.tap(find.text('Button 3 -> Hub Secondario'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Hub - Altri 3 Pulsanti'), findsOneWidget);

    // Trigger HUB bug with 3 valid entries into View D, returning to HUB each time.
    for (int i = 0; i < 3; i++) {
      final button2 = find.text('Button 2 -> View D');
      expect(button2, findsOneWidget);

      await tester.tap(button2);
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      final exception = tester.takeException();
      if (exception != null) {
        await AITester.reportError(exception, StackTrace.current, viewTag: 'HUB_VIEW');
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      if (i < 2) {
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(milliseconds: 350));
      }
    }

    fail('Expected JSON parse error during 3rd valid navigation from HUB_VIEW');
  });

  testWidgets('Test 4: Intentional StateError Crash', (WidgetTester tester) async {
    await tester.pumpWidget(const AITesterApp());
    await tester.pumpAndSettle();

    // Login
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
    await tester.enterText(textFields.at(1), 'testuser');
    await tester.enterText(textFields.at(2), 'test123');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to Hub
    await tester.tap(find.text('Button 3 -> Hub Secondario'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Navigate to View E - should crash immediately.
    await tester.tap(find.text('Button 3 -> View E'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final exception = tester.takeException();
    if (exception == null) {
      fail('Expected StateError crash when opening View E');
    }

    await AITester.reportError(exception, StackTrace.current, viewTag: 'VIEW_E');
    await Future.delayed(const Duration(milliseconds: 500));
  });
}
