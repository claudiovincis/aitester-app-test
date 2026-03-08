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
        appId: 'flutter-test-app-all-bugs',
        buildVersion: '1.0.0-all-bugs',
        enableAutoTracking: true,
        enableCrashReporting: true,
        debugMode: true,
      ),
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

    // Click 5 times on Button 1 to trigger division by zero
    final button1 = find.text('Button 1 -> View A');
    expect(button1, findsOneWidget);

    for (int i = 0; i < 5; i++) {
      try {
        await tester.tap(button1);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      } catch (e, stack) {
        // Expected to fail on 5th click - report crash manually
        if (i == 4) {
          await AITester.reportError(e, stack, viewTag: 'HOME_VIEW');
          await Future.delayed(const Duration(milliseconds: 500)); // Give time to send
          return;
        }
      }
    }

    fail('Expected division by zero error on 5th click');
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

    // Tap twice - should crash
    try {
      await tester.tap(tapButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      fail('Expected null pointer error on 2nd tap');
    } catch (e, stack) {
      // Expected error - report crash manually
      await AITester.reportError(e, stack, viewTag: 'VIEW_A');
      await Future.delayed(const Duration(milliseconds: 500)); // Give time to send
    }
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

    // Click Hub Button 2 three times to trigger JSON parse error
    final button2 = find.text('Button 2 -> View D');
    expect(button2, findsOneWidget);

    for (int i = 0; i < 3; i++) {
      
      try {
        await tester.tap(button2);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      } catch (e, stack) {
        // Expected to fail on 3rd click - report crash manually
        if (i == 2) {
          await AITester.reportError(e, stack, viewTag: 'HUB_VIEW');
          await Future.delayed(const Duration(milliseconds: 500)); // Give time to send
          return;
        }
      }
    }

    fail('Expected JSON parse error on 3rd click');
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
    
    // Navigate to View E - should crash immediately
    try {
      await tester.tap(find.text('Button 3 -> View E'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      fail('Expected StateError crash when opening View E');
    } catch (e, stack) {
      // Expected error - report crash manually
      await AITester.reportError(e, stack, viewTag: 'VIEW_E');
      await Future.delayed(const Duration(milliseconds: 500)); // Give time to send
    }
  });
}
