import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/services/auth_service.dart';
import '../../../app/routes.dart';
import '../../profile/logic/profile_controller.dart';
import '../../../core/theme/theme_provider.dart';

class AdminDrawer extends StatelessWidget {
  final Function(int)? onTabSelect;

  const AdminDrawer({super.key, this.onTabSelect});

  @override
  Widget build(BuildContext context) {
    // If onTabSelect provided, we highlight based on index? 
    // Wait, AdminHome manages index. AdminDrawer doesn't know _index unless passed.
    // For now, let's just use onTabSelect to navigate.
    
    // We can use currentRoute logic for selection if onTabSelect is NULL.
    // If onTabSelect IS provided, we assume we are in AdminHome Tabs.
    // But how do we know which tab is selected? 
    // Maybe pass `selectedIndex` too? 
    // Let's keep it simple: Just allow navigation. Highlight is bonus.
    
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Consumer2<ProfileController, ThemeProvider>(
        builder: (context, profileController, themeProvider, _) {
          final profile = profileController.profile;
          final hasImage = profile?.profilePhotoUrl != null &&
              profile!.profilePhotoUrl!.isNotEmpty;
          
          final displayName = profile?.name.isNotEmpty == true ? profile!.name : 'Admin';
          final displayEmail = profile?.email ?? 'admin@eventsphere.com';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(displayName),
                accountEmail: Text(displayEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: hasImage
                      ? CachedNetworkImageProvider(profile!.profilePhotoUrl!)
                      : null,
                  child: !hasImage
                      ? const Icon(Icons.shield, size: 40, color: Colors.grey)
                      : null,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Administration', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                selected: currentRoute == AppRoutes.adminHome,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                selectedColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  if (onTabSelect != null) {
                    onTabSelect!(0);
                  } else if (currentRoute != AppRoutes.adminHome) {
                    Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Verify Organizations'),
                selected: currentRoute == AppRoutes.verifyOrg,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                selectedColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  if (onTabSelect != null) {
                    onTabSelect!(1);
                  } else if (currentRoute != AppRoutes.verifyOrg) {
                    Navigator.pushReplacementNamed(context, AppRoutes.verifyOrg);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Ad Requests'),
                selected: currentRoute == AppRoutes.adApproval,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                selectedColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  if (onTabSelect != null) {
                    onTabSelect!(2);
                  } else if (currentRoute != AppRoutes.adApproval) {
                    Navigator.pushReplacementNamed(context, AppRoutes.adApproval);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Analytics'),
                selected: currentRoute == AppRoutes.analytics,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                selectedColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  if (onTabSelect != null) {
                    onTabSelect!(3);
                  } else if (currentRoute != AppRoutes.analytics) {
                    Navigator.pushReplacementNamed(context, AppRoutes.analytics);
                  }
                },
              ),

              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Preferences', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),

              SwitchListTile(
                secondary: Icon(themeProvider.isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
                title: const Text('Dark Mode'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close dialog
                            final authService = context.read<AuthService>();
                            await authService.logout();
                            if (!context.mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (_) => false,
                            );
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
