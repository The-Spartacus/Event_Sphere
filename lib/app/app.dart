import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Sphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // 🚀 Splash is the ONLY entry point
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
