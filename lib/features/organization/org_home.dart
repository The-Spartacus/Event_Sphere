import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../app/routes.dart';
import '../../widgets/custom_floating_navbar.dart';
import '../../widgets/app_drawer.dart';
import '../profile/logic/profile_controller.dart';

import 'org_dashboard_screen.dart';
import 'org_events_list_screen.dart';
import 'create_event_screen.dart';
import 'scan_qr_screen.dart';

class OrgHome extends StatefulWidget {
  const OrgHome({super.key});

  @override
  State<OrgHome> createState() => _OrgHomeState();
}

class _OrgHomeState extends State<OrgHome> {
  int _index = 0;
  bool _isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
    OrgDashboardScreen(
      onOpenDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
    ),
    const OrgEventsListScreen(),
    const CreateEventScreen(),
    const ScanQrScreen(), // Fixed typo and case
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final userId = authService.currentUserId;
      if (userId != null) {
        context.read<ProfileController>().loadProfile(userId);
      }
    });
  }

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
              onActionButtonTap: () {
                setState(() => _index = 3); // Switch to Scan QR index
              },
              actionButtonIcon: Icons.qr_code_scanner,
              items: [
                CustomNavBarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                ),
                CustomNavBarItem(
                  icon: Icons.event_note_outlined,
                  activeIcon: Icons.event_note,
                  label: 'My Events',
                ),
                CustomNavBarItem(
                  icon: Icons.add_circle_outline,
                  activeIcon: Icons.add_circle,
                  label: 'Create',
                ),
              ],
            ),
    );
  }
}
