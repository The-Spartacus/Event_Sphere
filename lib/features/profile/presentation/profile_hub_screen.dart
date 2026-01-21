import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/profile_controller.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../app/routes.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, _) {
        final profile = controller.profile;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasImage = profile.profilePhotoUrl != null &&
            profile.profilePhotoUrl!.isNotEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: hasImage
                              ? NetworkImage(profile.profilePhotoUrl!)
                              : null,
                          child: !hasImage
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.isNotEmpty 
                                  ? profile.name 
                                  : (profile.organizationName ?? 'User'),
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                profile.email,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildSectionHeader(context, 'Account'),
                  _buildListTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Manage your profile',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.editProfile,
                        arguments: profile.role,
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Password & Security',
                    onTap: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.language,
                    title: 'Language',
                    trailing: const Text('English', style: TextStyle(color: Colors.grey)),
                    onTap: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(context, 'Preferences'),
                  _buildListTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap: () {
                       // Placeholder
                    },
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                        title: const Text('Theme'),
                        subtitle: Text(themeProvider.isDarkMode ? 'Dark' : 'Light'),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      );
                    }
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    onTap: () {
                       // Placeholder
                    },
                  ),
                   const SizedBox(height: 40),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).iconTheme.color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
