import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../../profile/logic/profile_controller.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/planet_orbit_loader.dart';

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

    if (state != AuthState.unauthenticated && authService.currentUserId != null) {
      // Pre-load profile
      final profileController = context.read<ProfileController>();
      await profileController.loadProfile(authService.currentUserId!);
    }
    
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/event_sphere.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(width: 20),
                Text(
                  'Event Sphere',
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            const PlanetOrbitLoader(
              size: 120,
              planetColor: Colors.white,
              coreColor: Color(0xFFFFD700), // Gold core
            ),
          ],
        ),
      ),
    );
  }
}
