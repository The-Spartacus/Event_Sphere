import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../app/routes.dart';
import '../events/presentation/event_list_screen.dart';
import 'student_dashboard_screen.dart';
import 'my_events_screen.dart';
import '../certificates/certificate_vault_screen.dart';

import '../../widgets/custom_floating_navbar.dart';
import '../../widgets/app_drawer.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _index = 0;
  bool _isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
    StudentDashboardScreen(
      onOpenDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
    ),
    const EventListScreen(),
    const MyEventsScreen(),
    const CertificateVaultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      endDrawer: const AppDrawer(),
      onEndDrawerChanged: (isOpen) {
        setState(() {
          _isDrawerOpen = isOpen;
        });
      },
      body: _pages[_index],
      bottomNavigationBar: _isDrawerOpen 
          ? null 
          : CustomFloatingNavBar(
              currentIndex: _index,
              onTap: (i) {
                setState(() => _index = i);
              },
              onActionButtonTap: null, // Removed notification icon
              items: [
                CustomNavBarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Home',
                ),
                CustomNavBarItem(
                  icon: Icons.event_outlined,
                  activeIcon: Icons.event,
                  label: 'Events',
                ),
                CustomNavBarItem(
                  icon: Icons.event_available_outlined,
                  activeIcon: Icons.event_available,
                  label: 'My Events',
                ),
                CustomNavBarItem(
                  icon: Icons.workspace_premium_outlined,
                  activeIcon: Icons.workspace_premium,
                  label: 'Certificates',
                ),
              ],
            ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authService = context.read<AuthService>();
    await authService.logout();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }
}
