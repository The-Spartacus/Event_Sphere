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
import 'features/profile/data/storage_service.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/logic/profile_controller.dart';
import 'core/theme/theme_provider.dart';

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

        ChangeNotifierProvider<EventController>(
          create: (_) => EventController(EventRepository()),
        ),

        Provider<StorageService>(
          create: (_) => StorageService(),
        ),

        Provider<ProfileRepository>(
          create: (_) => ProfileRepository(),
        ),

        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(
            repository: context.read<ProfileRepository>(),
            storageService: context.read<StorageService>(),
          ),
        ),

        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const App(),
    );
  }
}
