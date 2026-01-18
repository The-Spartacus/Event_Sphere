import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../profile/logic/profile_controller.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/app_config.dart';
import '../data/event_repository.dart';
import '../data/event_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/routes.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventRepository _repository = EventRepository();

  EventModel? _event;
  bool _isLoading = true;

  String? _error;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _repository.getEventById(widget.eventId);
      if (!mounted) return;

      setState(() {
        _event = event;

        _isLoading = false;
      });
      _checkRegistration();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }

  }

  Future<void> _checkRegistration() async {
    if (_event == null) return;
    
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;
    if (userId != null) {
      final isReg = await _repository.isUserRegistered(userId, _event!.id);
      if (mounted) {
        setState(() => _isRegistered = isReg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          Consumer<ProfileController>(
            builder: (context, controller, _) {
              final isBookmarked = controller.profile?.bookmarkedEventIds
                      .contains(widget.eventId) ??
                  false;
              
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: isBookmarked ? Colors.red : null,
                ),
                onPressed: () {
                  controller.toggleBookmark(widget.eventId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBookmarked
                          ? 'Removed from favorites'
                          : 'Added to favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (_event != null) {
                Share.share(
                  'Check out ${_event!.title} by ${_event!.organizationName} on EventSphere! \n${_event!.registrationLink ?? ''}',
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: AppTextStyles.body,
                  ),
                )
              : _event == null
                  ? Center(
                      child: Text(
                        'Event not found',
                        style: AppTextStyles.body,
                      ),
                    )
                  : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final event = _event!;
    final hasPoster = event.posterUrl != null && event.posterUrl!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster Image
          if (hasPoster)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: DecorationImage(
                  image: NetworkImage(event.posterUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Countdown Timer (Premium Feature)
                if (_isUpcomingSoon(event.date))
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Starts in ${_getTimeUntil(event.startTime)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Title
                Text(
                  event.title,
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: 8),

                // Organization
                InkWell(
                  onTap: () {
                     Navigator.pushNamed(
                        context,
                        AppRoutes.publicOrgProfile,
                        arguments: event.organizationId,
                      );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          event.organizationName,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primary, 
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date and Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${event.date.day}/${event.date.month}/${event.date.year}',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${TimeOfDay.fromDateTime(event.startTime).format(context)} - ${TimeOfDay.fromDateTime(event.endTime).format(context)}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Engagement Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map),
                        label: const Text('Map'),
                        onPressed: () async {
                          // Simple map search query
                          final query = Uri.encodeComponent(event.location);
                          final googleMapsUrl = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=$query');
                          if (await canLaunchUrl(googleMapsUrl)) {
                            await launchUrl(googleMapsUrl);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open maps')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.alarm),
                        label: const Text('Remind Me'),
                        onPressed: () {
                          // Simulation for local notifications
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reminder set for 1 hour before event'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                 const SizedBox(height: 24),

                // Category & Location
                _InfoRow(
                  label: 'Category',
                  value: event.category,
                ),
                _InfoRow(
                  label: 'Location',
                  value:
                      '${event.locationType.toUpperCase()} • ${event.location}',
                ),
                _InfoRow(
                  label: 'Duration',
                  value: event.duration,
                ),
                const SizedBox(height: 12),

                // Paid / Free
                Row(
                  children: [
                    Chip(
                      label: Text(
                        event.isPaid
                            ? '${AppConstants.paid} ₹${event.price ?? 0}'
                            : AppConstants.free,
                      ),
                      backgroundColor: event.isPaid
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    if (event.certificateProvided)
                      Chip(
                        label: const Text('Certificate'),
                        backgroundColor:
                            AppColors.primary.withOpacity(0.1),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                if (event.description != null && event.description!.isNotEmpty) ...[
                  Text(
                    'About Event',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                ],

                // Key Features
                if (event.keyFeatures != null && event.keyFeatures!.isNotEmpty) ...[
                  Text(
                    'Key Features',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  ...event.keyFeatures!.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, 
                              size: 20, 
                              color: AppColors.primary
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                ],


                // Register / View Ticket Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isRegistered 
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.ticket,
                            arguments: event,
                          );
                        }
                      : () async {
                      final link = event.registrationLink;
                      if (link != null && link.isNotEmpty) {
                        final uri = Uri.parse(link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch link')),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No registration link provided'),
                          ),
                        );
                      }
                    },
                    style: _isRegistered ? ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ) : null,
                    child: Text(_isRegistered ? 'View Ticket' : 'Register for Event'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  bool _isUpcomingSoon(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    return !diff.isNegative && diff.inHours < 48; // Show if within 48 hours
  }

  String _getTimeUntil(DateTime startTime) {
    final now = DateTime.now();
    final diff = startTime.difference(now);
    if (diff.inDays > 0) {
      return '${diff.inDays} days';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours';
    } else {
      return '${diff.inMinutes} mins';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodyBold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
