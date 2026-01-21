import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/services/auth_service.dart';
import '../../app/routes.dart';
import '../../widgets/custom_floating_navbar.dart';
import '../profile/logic/profile_controller.dart';

import 'widgets/admin_drawer.dart';
import 'admin_dashboard.dart';
import 'verify_org_screen.dart';
import 'ad_approval_screen.dart';
import 'analytics_screen.dart';

class AdminHome extends StatefulWidget {
  final int initialIndex;

  const AdminHome({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late int _index;
  bool _isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Admin Dashboard',
    'Verify Organizations',
    'Pending Ad Requests',
    'Platform Analytics',
  ];

  final List<Widget> _pages = const [
    AdminDashboard(),
    VerifyOrgScreen(),
    AdApprovalScreen(),
    AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    
    // Load profile for Avatar
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
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 20, // Slightly smaller to fit longer titles
          ),
        ),
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
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: hasImage
                        ? CachedNetworkImageProvider(profile!.profilePhotoUrl!)
                        : null,
                    child: !hasImage
                        ? const Icon(Icons.shield, color: Colors.grey)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      endDrawer: AdminDrawer(
        onTabSelect: (index) {
          setState(() => _index = index);
        },
      ),
      onEndDrawerChanged: (isOpen) {
        setState(() => _isDrawerOpen = isOpen);
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
                setState(() => _index = 3); // Switch to Analytics index
              },
              actionButtonIcon: Icons.analytics_outlined,
              items: [
                CustomNavBarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                ),
                CustomNavBarItem(
                  icon: Icons.verified_user_outlined,
                  activeIcon: Icons.verified_user,
                  label: 'Verify',
                ),
                CustomNavBarItem(
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign,
                  label: 'Ads',
                ),
              ],
            ),
    );
  }
}
