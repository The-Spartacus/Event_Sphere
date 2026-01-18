import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../app/routes.dart';
import '../events/logic/event_controller.dart';
import '../events/data/event_repository.dart';
import '../events/data/event_model.dart';
import '../../widgets/event_card.dart';
import '../../core/services/auth_service.dart';
import '../profile/logic/profile_controller.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < 4) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventController>(
      create: (_) {
        final controller = EventController(EventRepository());
        controller.loadEvents();
        return controller;
      },
      child: Scaffold(
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
        endDrawer: Drawer(
          child: Consumer2<ProfileController, ThemeProvider>(
            builder: (context, profileController, themeProvider, _) {
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
                      Navigator.pop(context);
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
                ],
              );
            },
          ),
        ),
        body: Consumer<EventController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = controller.events;
            if (events.isEmpty) {
              return const Center(child: Text('No events available'));
            }

            // Simple "Featured" logic: Take first 5 events or randomize
            final featuredEvents = events.take(5).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 16),
                  
                  // Rolling Banner
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: featuredEvents.length,
                      itemBuilder: (context, index) {
                        return _BannerCard(event: featuredEvents[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      featuredEvents.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Categories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Browse by Category',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.eventCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = AppConstants.eventCategories[index];
                        return ActionChip(
                          label: Text(category),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: AppColors.border),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.categoryEvents,
                              arguments: category,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Favorites Section (Subscribed Events)
                  Consumer<ProfileController>(
                    builder: (context, profileController, _) {
                      final userProfile = profileController.profile;
                      if (userProfile == null) return const SizedBox.shrink();

                      final subscribedIds = userProfile.subscribedOrgIds;
                      if (subscribedIds.isEmpty) return const SizedBox.shrink();

                      final subscribedEvents = controller.events.where((element) {
                        if (!subscribedIds.contains(element.organizationId)) {
                          return false;
                        }
                        // Only show upcoming events
                        if (element.date.isBefore(
                            DateTime.now().subtract(const Duration(days: 1)))) {
                          return false;
                        }

                        // Show only events created after subscription
                        final subTime = userProfile
                            .subscriptionTimestamps[element.organizationId];
                        if (subTime != null) {
                          return element.createdAt.isAfter(subTime);
                        }
                        return true; // Legacy: show all if no timestamp
                      }).toList();

                      if (subscribedEvents.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  'Subscribed',
                                  style: AppTextStyles.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 300, // Adjust height as needed for EventCard
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: subscribedEvents.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final event = subscribedEvents[index];
                                return SizedBox(
                                  width: 200, // Fixed width for horizontal items
                                  child: EventCard(
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
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                  
                  // Featured Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Featured Events',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Featured Events List
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: featuredEvents.length,
                    itemBuilder: (context, index) {
                      final event = featuredEvents[index];
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
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final EventModel event;

  const _BannerCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.eventDetails,
          arguments: event.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          image: (event.posterUrl != null && event.posterUrl!.isNotEmpty)
              ? DecorationImage(
                  image: NetworkImage(event.posterUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
          gradient: (event.posterUrl != null && event.posterUrl!.isNotEmpty)
              ? null
              : LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.title,
                      style: AppTextStyles.title.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.date.toString().split(' ')[0], // Simple date format
                      style: AppTextStyles.body.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
