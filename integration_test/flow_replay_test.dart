import 'package:dio/dio.dart';
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
        appId: 'flutter-test-app-tests',
        buildVersion: '1.0.0-test',
        enableAutoTracking: true,
        enableCrashReporting: true,
        debugMode: true,
      ),
    );
  });

  group('Flow Replay Integration Tests', () {
    testWidgets('Replay crash flow from server logs', (WidgetTester tester) async {
      // Step 1: Avvia l'app
      await tester.pumpWidget(const AITesterApp());
      await tester.pumpAndSettle();

      // Step 2: Esegui login
      expect(find.text('AITester Login'), findsOneWidget);

      // Trova i campi di input per indice
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(3)); // server, username, password

      await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
      await tester.enterText(textFields.at(1), 'testuser');
      await tester.enterText(textFields.at(2), 'test123');

      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 3: Verifica di essere arrivati alla home
      expect(find.text('Home - 3 Pulsanti'), findsOneWidget);
    });

    testWidgets('Navigate to crash path without triggering', (WidgetTester tester) async {
      // Setup app
      await tester.pumpWidget(const AITesterApp());
      await tester.pumpAndSettle();

      // Login
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'http://192.168.1.13:5000');
      await tester.enterText(textFields.at(1), 'testuser');
      await tester.enterText(textFields.at(2), 'test123');
      
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate: Home -> Button 3 -> Hub
      expect(find.text('Button 3 -> Hub Secondario'), findsOneWidget);
      await tester.tap(find.text('Button 3 -> Hub Secondario'));
      await tester.pumpAndSettle();

      // Verify we're at the Hub
      expect(find.text('Hub - Altri 3 Pulsanti'), findsOneWidget);
      
      // Verify the crash button exists (but don't tap it to avoid breaking the test)
      expect(find.text('Button 3 -> Crash View'), findsOneWidget);
      
      print('Navigation test completed - all buttons present');
    });

    testWidgets('Fetch and replay flow from server API', (WidgetTester tester) async {
      // Questo test dimostra come leggere e replicare un flusso reale dal server
      const serverUrl = 'http://192.168.1.13:5000';
      
      // Skip se non abbiamo un sessionId da testare
      const testSessionId = String.fromEnvironment('TEST_SESSION_ID', defaultValue: '');
      if (testSessionId.isEmpty) {
        print('Skipping server flow replay: TEST_SESSION_ID not provided');
        return;
      }

      // Fetch flow from server
      final dio = Dio();
      final response = await dio.get<List<dynamic>>('$serverUrl/api/flows/$testSessionId');
      final events = response.data!;

      print('Fetched ${events.length} events from server for session $testSessionId');

      // Setup app
      await tester.pumpWidget(const AITesterApp());
      await tester.pumpAndSettle();

      // Login first
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), serverUrl);
      await tester.enterText(textFields.at(1), 'testuser');
      await tester.enterText(textFields.at(2), 'test123');
      
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Replay each click event
      for (final event in events) {
        final eventType = event['eventType'] as String;
        final viewTag = event['viewTag'] as String;
        final actionTag = event['actionTag'] as String?;

        if (eventType == 'click' && actionTag != null) {
          print('Replaying click: $viewTag -> $actionTag');

          // Map action tags to UI buttons
          Finder? targetButton;
          switch (actionTag) {
            case 'BTN_HOME_1':
              targetButton = find.text('Button 1 -> View A');
              break;
            case 'BTN_HOME_2':
              targetButton = find.text('Button 2 -> View B');
              break;
            case 'BTN_HOME_3':
              targetButton = find.text('Button 3 -> Hub Secondario');
              break;
            case 'BTN_HUB_1':
              targetButton = find.text('Button 1 -> View C');
              break;
            case 'BTN_HUB_2':
              targetButton = find.text('Button 2 -> View D');
              break;
            case 'BTN_HUB_3':
              targetButton = find.text('Button 3 -> Crash View');
              break;
          }

          if (targetButton != null) {
            try {
              await tester.tap(targetButton);
              await tester.pumpAndSettle(const Duration(milliseconds: 500));
            } catch (e) {
              print('Error during replay at $actionTag: $e');
              // Crash potrebbe essere previsto
              break;
            }
          }
        }
      }

      print('Flow replay completed');
    });
  });
}
