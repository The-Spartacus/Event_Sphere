import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../events/data/event_repository.dart';
import '../events/data/event_model.dart';
import 'logic/my_events_controller.dart';
import '../profile/logic/profile_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/event_card.dart';
import '../../app/routes.dart';
import 'calendar_screen.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access dependencies to create controller
    final authService = context.read<AuthService>();
    final profileController = context.read<ProfileController>();
    final userId = authService.currentUserId ?? '';
    final bookmarkedIds = profileController.profile?.bookmarkedEventIds ?? [];

    return ChangeNotifierProvider<MyEventsController>(
      create: (_) {
        final controller = MyEventsController(
          repository: EventRepository(),
          userId: userId,
          bookmarkedIds: bookmarkedIds,
        );
        controller.loadData();
        return controller;
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
             title: Text(
              'My Events',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Registered'),
                Tab(text: 'Interested'),
                Tab(text: 'Calendar'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          body: Consumer<MyEventsController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error != null) {
                return Center(child: Text('Error: ${controller.error}'));
              }

              return TabBarView(
                children: [
                  _EventList(events: controller.registeredEvents, emptyMessage: 'No registered events'),
                  _EventList(events: controller.interestedEvents, emptyMessage: 'No bookmarked events'),
                  const CalendarScreen(showAppBar: false),
                  _EventList(events: controller.pastEvents, emptyMessage: 'No past events'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<EventModel> events;
  final String emptyMessage;

  const _EventList({
    required this.events,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: AppTextStyles.body.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          title: event.title,
          organization: event.organizationName,
          date: event.date,
          locationType: event.locationType,
          isPaid: event.isPaid,
          price: event.price,
          organizationId: event.organizationId,
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
  }
}
