import 'dart:convert';

import 'package:aitester_sdk/aitester_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  // Initialize AITester SDK
  AITester.initialize(
    AITesterConfig(
      serverUrl: 'http://192.168.1.13:5000',
      appId: 'flutter-test-app',
      buildVersion: '1.0.0',
      enableAutoTracking: true,
      enableCrashReporting: true,
      debugMode: true,
    ),
  );

  // Run app with crash handling
  AITester.runApp(() => const AITesterApp());
}

class AITesterApp extends StatefulWidget {
  const AITesterApp({super.key});

  @override
  State<AITesterApp> createState() => _AITesterAppState();
}

class _AITesterAppState extends State<AITesterApp> {
  late final AppState _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _appState,
      observers: [AITester.navigatorObserver], // Add AITester observer for automatic route tracking
      redirect: (context, state) {
        final isLogin = state.matchedLocation == '/login';
        final hasSession = _appState.session != null;
        if (!hasSession && !isLogin) return '/login';
        if (hasSession && isLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginPage(appState: _appState)),
        GoRoute(path: '/home', builder: (context, state) => HomePage(appState: _appState)),
        GoRoute(path: '/hub', builder: (context, state) => HubPage(appState: _appState)),
        GoRoute(path: '/view-a', builder: (context, state) => TaggedViewPage(appState: _appState, title: 'View A', viewTag: ViewTags.viewA)),
        GoRoute(path: '/view-b', builder: (context, state) => TaggedViewPage(appState: _appState, title: 'View B', viewTag: ViewTags.viewB)),
        GoRoute(path: '/view-c', builder: (context, state) => TaggedViewPage(appState: _appState, title: 'View C', viewTag: ViewTags.viewC)),
        GoRoute(path: '/view-d', builder: (context, state) => TaggedViewPage(appState: _appState, title: 'View D', viewTag: ViewTags.viewD)),
        GoRoute(path: '/crash', builder: (context, state) => CrashViewPage(appState: _appState)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AITester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B7F79)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class ViewTags {
  static const login = 'LOGIN_VIEW';
  static const home = 'HOME_VIEW';
  static const hub = 'HUB_VIEW';
  static const viewA = 'VIEW_A';
  static const viewB = 'VIEW_B';
  static const viewC = 'VIEW_C';
  static const viewD = 'VIEW_D';
  static const crash = 'CRASH_VIEW';
}

class ActionTags {
  static const loginSubmit = 'BTN_LOGIN_SUBMIT';
  static const home1 = 'BTN_HOME_1';
  static const home2 = 'BTN_HOME_2';
  static const home3 = 'BTN_HOME_3';
  static const hub1 = 'BTN_HUB_1';
  static const hub2 = 'BTN_HUB_2';
  static const hub3 = 'BTN_HUB_3';
}

class AppState extends ChangeNotifier {
  String baseUrl = 'http://192.168.1.13:5000';
  SessionData? session;

  void updateBaseUrl(String value) {
    baseUrl = value.trim();
    notifyListeners();
  }

  void setSession(SessionData data) {
    session = data;
    notifyListeners();
  }
}

class SessionData {
  const SessionData({required this.userId, required this.sessionId, required this.token});

  final String userId;
  final String sessionId;
  final String token;
}

class ApiClient {
  ApiClient(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            contentType: 'application/json',
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

  final Dio _dio;

  Future<SessionData> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {
        'username': username,
        'password': password,
        'deviceInfo': 'flutter-client',
      },
    );

    final body = response.data!;
    return SessionData(
      userId: body['userId'] as String,
      sessionId: body['sessionId'] as String,
      token: body['token'] as String,
    );
  }

  Future<void> sendTrackingEvent({
    required SessionData session,
    required String eventType,
    required String viewTag,
    String? actionTag,
    Map<String, dynamic>? payload,
  }) async {
    await _dio.post<void>(
      '/api/tracking/events',
      data: {
        'sessionId': session.sessionId,
        'userId': session.userId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'eventType': eventType,
        'viewTag': viewTag,
        'actionTag': actionTag,
        'payloadJson': payload == null ? null : jsonEncode(payload),
      },
    );
  }

  Future<void> sendCrash({
    required SessionData session,
    required String viewTag,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    await _dio.post<void>(
      '/api/tracking/crashes',
      data: {
        'sessionId': session.sessionId,
        'userId': session.userId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'viewTag': viewTag,
        'errorType': error.runtimeType.toString(),
        'stackTrace': stackTrace.toString(),
        'buildVersion': 'dev-local',
      },
    );
  }
}

// Tracker class removed - now using AITester SDK for all tracking

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.appState});

  final AppState appState;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController(text: 'http://192.168.1.13:5000');
  final _userController = TextEditingController(text: 'testuser');
  final _passController = TextEditingController(text: 'test123');
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AITester Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Server URL'),
              TextFormField(
                controller: _serverController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci URL server' : null,
              ),
              const SizedBox(height: 12),
              const Text('Username'),
              TextFormField(
                controller: _userController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci username' : null,
              ),
              const SizedBox(height: 12),
              const Text('Password'),
              TextFormField(
                controller: _passController,
                obscureText: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci password' : null,
              ),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Accedi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient(_serverController.text.trim());
      final session = await apiClient.login(_userController.text.trim(), _passController.text.trim());
      widget.appState.updateBaseUrl(_serverController.text.trim());
      widget.appState.setSession(session);

      await AITester.bindSession(sessionId: session.sessionId, userId: session.userId);

      AITester.trackClick(ActionTags.loginSubmit, viewTag: ViewTags.login);
    } on DioException catch (e) {
      setState(() {
        _error = 'Errore login: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _error = 'Errore inatteso: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.appState});

  final AppState appState;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Track view open (also tracked automatically by navigator observer)
    AITester.trackViewOpen(ViewTags.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home - 3 Pulsanti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AIButton(
              actionTag: ActionTags.home1,
              viewTag: ViewTags.home,
              onPressed: () {
                if (context.mounted) context.push('/view-a');
              },
              child: const Text('Button 1 -> View A'),
            ),
            AIButton(
              actionTag: ActionTags.home2,
              viewTag: ViewTags.home,
              onPressed: () {
                if (context.mounted) context.push('/view-b');
              },
              child: const Text('Button 2 -> View B'),
            ),
            AIButton(
              actionTag: ActionTags.home3,
              viewTag: ViewTags.home,
              onPressed: () {
                if (context.mounted) context.push('/hub');
              },
              child: const Text('Button 3 -> Hub Secondario'),
            ),
          ],
        ),
      ),
    );
  }
}

class HubPage extends StatefulWidget {
  const HubPage({super.key, required this.appState});

  final AppState appState;

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  @override
  void initState() {
    super.initState();
    AITester.trackViewOpen(ViewTags.hub);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hub - Altri 3 Pulsanti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AIButton(
              actionTag: ActionTags.hub1,
              viewTag: ViewTags.hub,
              onPressed: () {
                if (context.mounted) context.push('/view-c');
              },
              child: const Text('Button 1 -> View C'),
            ),
            AIButton(
              actionTag: ActionTags.hub2,
              viewTag: ViewTags.hub,
              onPressed: () {
                if (context.mounted) context.push('/view-d');
              },
              child: const Text('Button 2 -> View D'),
            ),
            AIButton(
              actionTag: ActionTags.hub3,
              viewTag: ViewTags.hub,
              onPressed: () {
                if (context.mounted) context.push('/crash');
              },
              child: const Text('Button 3 -> Crash View'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaggedViewPage extends StatefulWidget {
  const TaggedViewPage({super.key, required this.appState, required this.title, required this.viewTag});

  final AppState appState;
  final String title;
  final String viewTag;

  @override
  State<TaggedViewPage> createState() => _TaggedViewPageState();
}

class _TaggedViewPageState extends State<TaggedViewPage> {
  @override
  void initState() {
    super.initState();
    AITester.trackViewOpen(widget.viewTag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: Text('Sei in ${widget.title} (tag: ${widget.viewTag})')),
    );
  }
}

class CrashViewPage extends StatefulWidget {
  const CrashViewPage({super.key, required this.appState});

  final AppState appState;

  @override
  State<CrashViewPage> createState() => _CrashViewPageState();
}

class _CrashViewPageState extends State<CrashViewPage> {
  static const bool _enableCrash = true;

  @override
  void initState() {
    super.initState();
    _triggerCrashFlow();
  }

  Future<void> _triggerCrashFlow() async {
    print('🔴 [DEBUG] _triggerCrashFlow chiamato - _enableCrash: $_enableCrash');
    AITester.trackViewOpen(ViewTags.crash);
    print('🔴 [DEBUG] trackViewOpen completato');

    if (_enableCrash) {
      print('🔴 [DEBUG] Sto per lanciare il crash...');
      final error = StateError('Crash intenzionale per test AI replay/fix');
      final stack = StackTrace.current;
      // Report crash before throwing (AITester will also catch it automatically)
      await AITester.reportError(error, stack, viewTag: ViewTags.crash);
      print('🔴 [DEBUG] reportError completato, ora lancio throw...');
      throw error;
    } else {
      print('🟡 [DEBUG] Crash disabilitato - _enableCrash è false');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Crash view aperta. Se ENABLE_CRASH=true l\'app lancia un crash intenzionale.'),
      ),
    );
  }
}
