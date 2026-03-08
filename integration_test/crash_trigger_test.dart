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

  testWidgets('Trigger intentional crash path', (WidgetTester tester) async {
    await tester.pumpWidget(const AITesterApp());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
    await tester.enterText(textFields.at(1), 'testuser');
    await tester.enterText(textFields.at(2), 'test123');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('Button 3 -> Hub Secondario'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.text('Button 3 -> Crash View'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  });
}
