import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import 'package:event_sphere/features/events/data/event_repository.dart';
import 'package:event_sphere/features/events/data/event_model.dart';
import 'package:event_sphere/core/theme/colors.dart';
import 'package:event_sphere/core/theme/text_styles.dart';
import 'package:event_sphere/app/app_config.dart';
import 'package:event_sphere/app/routes.dart';
import 'package:event_sphere/widgets/event_card.dart';
import 'package:event_sphere/features/profile/logic/profile_controller.dart';

class CalendarScreen extends StatefulWidget {
  final bool showAppBar;
  const CalendarScreen({super.key, this.showAppBar = true});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventRepository _repository = EventRepository();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Store events grouped by day
  Map<DateTime, List<EventModel>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    // Normalize day to midnight for matching
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _eventsByDay[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Use Watch to react to profile changes without Consumer complexity
    final profileController = context.watch<ProfileController>();
    final calendarIds = profileController.profile?.calendarEventIds ?? [];

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Event Calendar'),
      ) : null,
      body: StreamBuilder<List<EventModel>>(
        stream: _repository.getEventsByIdsStream(calendarIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            _groupEvents(snapshot.data!);
          } else {
            _eventsByDay = {};
          }

          return Column(
            children: [
              TableCalendar<EventModel>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildEventList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No events scheduled for this day',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
    );
  }

  void _groupEvents(List<EventModel> events) {
    final Map<DateTime, List<EventModel>> grouped = {};
    for (var event in events) {
      final date = DateTime(event.date.year, event.date.month, event.date.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(event);
    }
    _eventsByDay = grouped;
  }
}
