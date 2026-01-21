import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../app/routes.dart';
import '../../app/app_config.dart';
import '../../core/constants/app_constants.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final authService = context.read<AuthService>();
    final uid = authService.currentUserId;
    if (uid != null) {
      final role = await authService.getUserRole(uid);
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncOrganizations(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing organizations...')),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      // Get all users who are organizations
      final usersSnapshot = await firestore
          .collection(ApiEndpoints.users)
          .where('role', isEqualTo: 'organization')
          .get();

      int repairedCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final uid = userDoc.id;
        final userData = userDoc.data();

        // Check if organization doc exists
        final orgDoc = await firestore
            .collection(ApiEndpoints.organizations)
            .doc(uid)
            .get();

        if (!orgDoc.exists) {
          // Create missing organization doc
          await firestore.collection(ApiEndpoints.organizations).doc(uid).set({
            'name': userData['name'] ?? 'Organization',
            'email': userData['email'] ?? '',
            'verified': false,
            'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
          });
          repairedCount++;
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync complete. Repaired $repairedCount accounts.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error syncing: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed Scaffold to avoid duplication with AdminHome
    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Administration',
                style: AppTextStyles.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync Missing Organizations',
                onPressed: () => _syncOrganizations(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_userRole == AppConstants.roleSuperAdmin || _userRole == 'super_admin') ...[
              _AdminCard(
                icon: Icons.person_add,
                title: 'Create Admin',
                description: 'Create a new sub-admin account',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.createAdmin);
                },
              ),
              const SizedBox(height: 16),
            ],

            _AdminCard(
              icon: Icons.verified_user,
              title: 'Verify Organizations',
              description: 'Approve or reject organization accounts',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.verifyOrg);
              },
            ),
            const SizedBox(height: 16),

            _AdminCard(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              description: 'View platform statistics',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.analytics);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminCard({
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
          borderRadius:
              BorderRadius.circular(AppConfig.borderRadius),
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
