import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../app/routes.dart';
import '../../../app/app_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardItem> _pages = const [
    _OnboardItem(
      icon: Icons.search,
      title: 'Discover Events',
      description:
          'Find seminars, workshops, internships, and academic programs.',
    ),
    _OnboardItem(
      icon: Icons.event_available,
      title: 'Register Easily',
      description: 'Register for events in one tap.',
    ),
    _OnboardItem(
      icon: Icons.workspace_premium,
      title: 'Secure Certificates',
      description:
          'Store and verify your certificates digitally.',
    ),
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.hasSeenOnboarding, true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon,
                            size: 120, color: AppColors.primary),
                        const SizedBox(height: 32),
                        Text(p.title,
                            style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 12),
                        Text(
                          p.description,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == i ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_index == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(
                        duration:
                            const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _index == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardItem {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
