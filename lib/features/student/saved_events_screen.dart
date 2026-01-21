import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:event_sphere/features/profile/logic/profile_controller.dart';
import 'package:event_sphere/features/events/data/event_repository.dart';
import 'package:event_sphere/features/events/data/event_model.dart';
import 'package:event_sphere/widgets/event_card.dart';
import 'package:event_sphere/core/theme/colors.dart';
import 'package:event_sphere/core/theme/text_styles.dart';
import 'package:event_sphere/app/routes.dart';

class SavedEventsScreen extends StatefulWidget {
  const SavedEventsScreen({super.key});

  @override
  State<SavedEventsScreen> createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  final EventRepository _eventRepository = EventRepository();
  bool _isLoading = true;
  List<EventModel> _savedEvents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    final profileController = context.read<ProfileController>();
    final savedIds = profileController.profile?.bookmarkedEventIds ?? [];

    if (savedIds.isEmpty) {
      if (mounted) {
        setState(() {
          _savedEvents = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final events = await _eventRepository.getEventsByIds(savedIds);
      if (mounted) {
        setState(() {
          _savedEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load saved events';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Events'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.body),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadSavedEvents();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_savedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No saved events yet',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Events you bookmark will appear here.',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedEvents,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _savedEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = _savedEvents[index];
          return EventCard(
            title: event.title,
            organization: event.organizationName,
            date: event.date,
            locationType: event.locationType,
            isPaid: event.isPaid,
            price: event.price,
            organizationId: event.organizationId,
            posterUrl: event.posterUrl,
            onTap: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.eventDetails,
                arguments: event.id,
              );
              // Refresh logic here if they un-bookmarked it
              if (mounted) {
                // Check if still bookmarked in controller
                final isBookmarked = context
                    .read<ProfileController>()
                    .profile
                    ?.bookmarkedEventIds
                    .contains(event.id) ?? false;
                
                if (!isBookmarked) {
                   _loadSavedEvents(); // Reload list to remove it
                }
              }
            },
          );
        },
      ),
    );
  }
}
