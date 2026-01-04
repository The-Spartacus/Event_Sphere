import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../logic/event_controller.dart';
import '../data/event_repository.dart';
import '../../../widgets/event_card.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

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
          title: const Text('Events'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.eventFilter,
                );
              },
            ),
          ],
        ),
        body: Consumer<EventController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.error != null) {
              return Center(
                child: Text(
                  controller.error!,
                  style: AppTextStyles.body,
                ),
              );
            }

            if (controller.events.isEmpty) {
              return Center(
                child: Text(
                  'No events available',
                  style: AppTextStyles.body,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.events.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = controller.events[index];

                return EventCard(
                  title: event.title,
                  organization: event.organizationName,
                  date: event.date,
                  locationType: event.locationType,
                  isPaid: event.isPaid,
                  price: event.price,
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
    );
  }
}
