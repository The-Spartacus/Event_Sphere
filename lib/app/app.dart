import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return MaterialApp(
      title: 'Event Sphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: AppRoutes.generateRoute,
      home: FutureBuilder<AuthState>(
        future: authService.checkAuthState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data == AuthState.unauthenticated) {
            return AppRoutes.loginWidget();
          }

          switch (snapshot.data) {
            case AuthState.student:
              return AppRoutes.studentHomeWidget();
            case AuthState.organization:
              return AppRoutes.organizationHomeWidget();
            case AuthState.admin:
              return AppRoutes.adminHomeWidget();
            default:
              return AppRoutes.loginWidget();
          }
        },
      ),
    );
  }
}
