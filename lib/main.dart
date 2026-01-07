import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'app/app.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';

// ADD THESE IMPORTS
import 'features/events/logic/event_controller.dart';
import 'features/events/data/event_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const EventSphereApp());
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

        // ✅ THIS IS THE FIX
        ChangeNotifierProvider<EventController>(
          create: (_) => EventController(EventRepository()),
        ),
      ],
      child: const App(),
    );
  }
}
