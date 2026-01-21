import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_provider.dart';
import '../profile/logic/profile_controller.dart';
import '../../widgets/app_drawer.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../app/routes.dart';
import '../../app/app_config.dart';

class OrgDashboardScreen extends StatelessWidget {
  const OrgDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event Sphere',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Consumer<ProfileController>(
              builder: (context, controller, _) {
                final profile = controller.profile;
                final hasImage = profile?.profilePhotoUrl != null &&
                    profile!.profilePhotoUrl!.isNotEmpty;
                
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: hasImage
                        ? NetworkImage(profile!.profilePhotoUrl!)
                        : null,
                    child: !hasImage
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Your Events',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 24),
            _DashboardCard(
              icon: Icons.event,
              title: 'My Events',
              description: 'View and manage your events',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.orgEventsList);
              },
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              icon: Icons.add_circle_outline,
              title: 'Create Event',
              description: 'Publish a new academic event',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.createEvent);
              },
            ),

          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.body),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
