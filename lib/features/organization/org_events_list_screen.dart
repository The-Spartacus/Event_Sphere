import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../app/app_config.dart';
import '../../app/routes.dart';
import '../events/data/event_model.dart';
import '../events/data/event_repository.dart';

/// Screen displaying all events created by the logged-in organization
/// Shows approval status, date & time, and participant count
/// Real-time updates via Firestore streams
class OrgEventsListScreen extends StatelessWidget {
  const OrgEventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final organizationId = authService.currentUserId;

    if (organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Events')),
        body: const Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createEvent);
            },
            tooltip: 'Create Event',
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventRepository().streamOrganizationEvents(organizationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTextStyles.body,
              ),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events yet',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first event to get started',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.createEvent);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Event'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(
                event: event,
                onTap: () {
                  // Navigate to edit screen for unapproved events, details for approved
                  if (!event.approved) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.editEvent,
                      arguments: event.id,
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetails,
                      arguments: event.id,
                    );
                  }
                },
                onViewParticipants: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.participants,
                    arguments: event.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Event card widget showing event details, approval status, and participant count
class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onViewParticipants;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onViewParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          border: Border.all(
            color: event.approved
                ? Colors.green.withOpacity(0.3)
                : AppColors.border,
            width: event.approved ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Approval Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: AppTextStyles.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _ApprovalBadge(approved: event.approved),
              ],
            ),
            const SizedBox(height: 12),
            
            // Category
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: AppColors.border),
                const SizedBox(width: 4),
                Text(
                  event.category,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Date and Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.border),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(event.date),
                  style: AppTextStyles.body,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: AppColors.border),
                const SizedBox(width: 4),
                Text(
                  '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                  style: AppTextStyles.body,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Location Type
            Row(
              children: [
                Icon(
                  _getLocationIcon(event.locationType),
                  size: 16,
                  color: AppColors.border,
                ),
                const SizedBox(width: 4),
                Text(
                  event.locationType.toUpperCase(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.border,
                  ),
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.border,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Participant Count and Actions
            StreamBuilder<int>(
              stream: EventRepository().getParticipantCount(event.id),
              builder: (context, countSnapshot) {
                final participantCount = countSnapshot.data ?? 0;
                return Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$participantCount ${participantCount == 1 ? 'participant' : 'participants'}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (event.approved || participantCount > 0)
                      TextButton.icon(
                        onPressed: onViewParticipants,
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Participants'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getLocationIcon(String locationType) {
    switch (locationType.toLowerCase()) {
      case 'online':
        return Icons.videocam;
      case 'offline':
        return Icons.location_on;
      case 'hybrid':
        return Icons.merge_type;
      default:
        return Icons.location_on;
    }
  }
}

/// Approval status badge widget
class _ApprovalBadge extends StatelessWidget {
  final bool approved;

  const _ApprovalBadge({required this.approved});

  @override
  Widget build(BuildContext context) {
    if (approved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Approved',
              style: AppTextStyles.caption.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Pending',
              style: AppTextStyles.caption.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }
}

