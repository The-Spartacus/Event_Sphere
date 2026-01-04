import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';
import 'firebase_options.dart';
import 'widgets/firebase_config_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // #region agent log
  final logFile = File('/home/vaishnav/Event_Sphere/.cursor/debug.log');
  try {
    await logFile.writeAsString('', mode: FileMode.write);
  } catch (_) {}
  final logEntry = (Map<String, dynamic> data) {
    try {
      final logData = Map<String, dynamic>.from(data);
      logData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      logFile.writeAsStringSync('${jsonEncode(logData)}\n',
          mode: FileMode.append);
    } catch (_) {}
  };
  // #endregion

  // #region agent log
  logEntry({
    'sessionId': 'debug-session',
    'runId': 'run1',
    'hypothesisId': 'A',
    'location': 'main.dart:20',
    'message': 'Starting Firebase initialization',
    'data': {'step': 'before_initialize'}
  });
  // #endregion

  String? firebaseError;

  // Initialize Firebase
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    // #region agent log
    logEntry({
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'A',
      'location': 'main.dart:52',
      'message': 'Calling Firebase.initializeApp()',
      'data': {
        'hasOptions': true,
        'optionsSource': 'firebase_options.dart',
        'apiKey': options.apiKey.substring(
            0, options.apiKey.length > 10 ? 10 : options.apiKey.length),
        'projectId': options.projectId
      }
    });
    // #endregion

    // Check if using placeholder values
    if (options.apiKey.startsWith('YOUR_')) {
      firebaseError = 'Firebase options contain placeholder values. '
          'Please update lib/firebase_options.dart with your actual Firebase credentials.';
    } else {
      await Firebase.initializeApp(options: options);
      // #region agent log
      logEntry({
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'A',
        'location': 'main.dart:68',
        'message': 'Firebase initialized successfully',
        'data': {'appName': 'default'}
      });
      // #endregion
    }
  } catch (e, stackTrace) {
    // #region agent log
    logEntry({
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'A',
      'location': 'main.dart:73',
      'message': 'Firebase initialization error caught',
      'data': {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
        'stackTrace': stackTrace.toString()
      }
    });
    // #endregion
    firebaseError = e.toString();
    debugPrint('Firebase initialization error: $e');
  }

  // #region agent log
  logEntry({
    'sessionId': 'debug-session',
    'runId': 'run1',
    'hypothesisId': 'A',
    'location': 'main.dart:40',
    'message': 'About to run app',
    'data': {'step': 'before_runApp', 'hasFirebaseError': firebaseError != null}
  });
  // #endregion

  // Run app with error screen if Firebase failed, otherwise normal app
  runApp(firebaseError != null
      ? MaterialApp(
          title: 'Event Sphere',
          debugShowCheckedModeBanner: false,
          home: FirebaseConfigErrorScreen(errorMessage: firebaseError),
        )
      : const EventSphereApp());
}

class EventSphereApp extends StatelessWidget {
  const EventSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
      ],
      child: const App(),
    );
  }
}
