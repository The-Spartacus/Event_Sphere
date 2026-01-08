import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../app/routes.dart';
import 'admin_dashboard.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Admin'),
              accountEmail: Text('admin@eventsphere.com'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.adminHome,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Verify Organizations'),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.verifyOrg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.analytics);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await authService.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: const AdminDashboard(),
    );
  }
}
