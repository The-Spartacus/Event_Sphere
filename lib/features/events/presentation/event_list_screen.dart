import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:event_sphere/core/theme/text_styles.dart';
import 'package:event_sphere/app/routes.dart';
import 'package:event_sphere/features/events/logic/event_controller.dart';
import 'package:event_sphere/features/events/data/event_repository.dart';
import 'package:event_sphere/widgets/event_card.dart';
import 'package:event_sphere/core/theme/colors.dart';
import 'package:event_sphere/core/services/auth_service.dart';
import 'package:event_sphere/features/profile/logic/profile_controller.dart';
import 'package:event_sphere/core/theme/theme_provider.dart';

class EventListScreen extends StatefulWidget {
  final String? initialCategory;

  const EventListScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
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
    return ChangeNotifierProvider<EventController>(
      create: (_) {
        final controller = EventController(EventRepository());
        controller.loadEvents();
        if (widget.initialCategory != null) {
          controller.applyFilters(category: widget.initialCategory);
        }
        return controller;
      },
      child: Consumer<ProfileController>(
        builder: (context, profileController, _) {
          // Sync location from profile to event controller
          if (profileController.profile?.isLocationSet == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<EventController>().setUserLocation(
                  profileController.profile!.latitude,
                  profileController.profile!.longitude,
                );
              }
            });
          }
          
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
                  child: GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileController.profile?.profilePhotoUrl != null &&
                              profileController.profile!.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(profileController.profile!.profilePhotoUrl!)
                          : null,
                      child: profileController.profile?.profilePhotoUrl == null ||
                              profileController.profile!.profilePhotoUrl!.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            endDrawer: Drawer(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  final profile = profileController.profile;
                  final hasImage = profile?.profilePhotoUrl != null &&
                      profile!.profilePhotoUrl!.isNotEmpty;

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      UserAccountsDrawerHeader(
                        accountName: Text(profile?.name ?? 'Student'),
                        accountEmail: Text(profile?.email ?? ''),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: hasImage
                              ? NetworkImage(profile!.profilePhotoUrl!)
                              : null,
                          child: !hasImage
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
                              : null,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.pushNamed(
                            context,
                            AppRoutes.profile,
                            arguments: 'student',
                          );
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        secondary: Icon(themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode),
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
                        onTap: () async {
                          Navigator.pop(context); // Close drawer
                          final authService = context.read<AuthService>();
                          await authService.logout();
                          
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (_) => false,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            body: Consumer<EventController>(
              builder: (context, controller, _) {
                return Column(
                  children: [
                    // Filters Section
                    Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // College Search
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by College Name',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onChanged: (value) {
                              controller.searchByCollege(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Date Filters
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  isSelected: controller.startDate == null,
                                  onTap: controller.clearFilters,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Today',
                                  isSelected: _isToday(controller.startDate),
                                  onTap: controller.filterToday,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Tomorrow',
                                  isSelected: _isTomorrow(controller.startDate),
                                  onTap: controller.filterTomorrow,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'This Week',
                                  isSelected: _isThisWeek(controller.endDate),
                                  onTap: controller.filterThisWeek,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Event List
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (controller.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
            
                          if (controller.error != null) {
                            return Center(child: Text(controller.error!, style: AppTextStyles.body));
                          }
            
                          if (controller.events.isEmpty) {
                            return Center(child: Text('No events found', style: AppTextStyles.body));
                          }
            
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: controller.events.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final event = controller.events[index];
                              return EventCard(
                                title: event.title,
                                organization: event.organizationName,
                                date: event.date,
                                locationType: event.locationType,
                                isPaid: event.isPaid,
                                price: event.price,
                                organizationId: event.organizationId,
                                posterUrl: event.posterUrl,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.eventDetails,
                                    arguments: event.id,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTomorrow(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now().add(const Duration(days: 1));
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isThisWeek(DateTime? endDate) {
    if (endDate == null) return false;
    final now = DateTime.now();
    final diff = endDate.difference(now).inDays;
    return diff >= 6 && diff <= 8;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
