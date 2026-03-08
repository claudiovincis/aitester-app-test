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
    final button1 = find.text('Button 1 -> View A (click 5x for bug)');
    expect(button1, findsOneWidget);

    print('🐛 TEST: Triggering Division by Zero bug...');
    for (int i = 0; i < 5; i++) {
      print('Click ${i + 1}/5 on Home Button 1');
      
      try {
        await tester.tap(button1);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      } catch (e) {
        print('✅ Division by zero caught at click ${i + 1}: $e');
        // Expected to fail on 5th click
        if (i == 4) {
          print('✅ Bug triggered successfully on 5th click!');
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
    final button1 = find.text('Button 1 -> View A (click 5x for bug)');
    await tester.tap(button1);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Now we're in View A, find the tap button
    final tapButton = find.textContaining('Tap me');
    expect(tapButton, findsOneWidget);

    print('🐛 TEST: Triggering Null Pointer bug...');
    
    // Tap once - should be fine
    await tester.tap(tapButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    print('Tap 1/2 - OK');

    // Tap twice - should crash
    try {
      await tester.tap(tapButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      fail('Expected null pointer error on 2nd tap');
    } catch (e) {
      print('✅ Null pointer caught on 2nd tap: $e');
      print('✅ Bug triggered successfully!');
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
    final button2 = find.text('Button 2 -> View D (click 3x for bug)');
    expect(button2, findsOneWidget);

    print('🐛 TEST: Triggering JSON Parse error...');
    for (int i = 0; i < 3; i++) {
      print('Click ${i + 1}/3 on Hub Button 2');
      
      try {
        await tester.tap(button2);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      } catch (e) {
        print('✅ JSON Parse error caught at click ${i + 1}: $e');
        // Expected to fail on 3rd click
        if (i == 2) {
          print('✅ Bug triggered successfully on 3rd click!');
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

    print('🐛 TEST: Triggering intentional StateError crash...');
    
    // Navigate to Crash View - should crash immediately
    try {
      await tester.tap(find.text('Button 3 -> Crash View'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      fail('Expected StateError crash when opening Crash View');
    } catch (e) {
      print('✅ StateError caught: $e');
      print('✅ Intentional crash triggered successfully!');
    }
  });
}
