import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../events/logic/event_controller.dart';
import '../events/data/event_repository.dart';
import '../../core/theme/text_styles.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventController(EventRepository())..loadEvents(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: Consumer<EventController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // In a real app, we'd query a separate 'notifications' collection.
            // Here, we simulate notifications by showing the most recent 10 events.
            final recentEvents = controller.events.take(10).toList();

            if (recentEvents.isEmpty) {
              return const Center(child: Text('No new notifications'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recentEvents.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final event = recentEvents[index];
                final timeAgo = _getTimeAgo(event.createdAt);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: event.posterUrl != null 
                        ? NetworkImage(event.posterUrl!) 
                        : null,
                    child: event.posterUrl == null 
                        ? const Icon(Icons.event_note) 
                        : null,
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(
                          text: 'New Event: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: event.title),
                      ],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('By ${event.organizationName}'),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (event.id == null) return;
                    // Navigate to event details
                     Navigator.pushNamed(
                      context,
                      '/events/details', // Hardcoded or use AppRoutes if imported
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

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
