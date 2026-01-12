import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(StorageKeys.hasSeenOnboarding) ?? false;

    if (!hasSeenOnboarding) {
      // FIRST INSTALL → Onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    // After onboarding → check auth
    final authService = context.read<AuthService>();
    final state = await authService.checkAuthState();

    if (!mounted) return;

    switch (state) {
      case AuthState.student:
        Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
        break;
      case AuthState.organization:
        Navigator.pushReplacementNamed(context, AppRoutes.orgHome);
        break;
      case AuthState.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/event_sphere.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 16),
            Text(
              'Event Sphere',
              style: AppTextStyles.headlineLarge.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
