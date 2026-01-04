import 'package:flutter/material.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/app_config.dart';
import '../data/event_repository.dart';
import '../data/event_model.dart';

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
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

    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            event.title,
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 8),

          // Organization
          Text(
            event.organizationName,
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 16),

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

          const Spacer(),

          // Register Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registration feature coming soon'),
                  ),
                );
              },
              child: const Text('Register for Event'),
            ),
          ),
        ],
      ),
    );
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
