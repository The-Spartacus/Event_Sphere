import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../app/app_config.dart';
import '../../app/routes.dart';
import '../events/data/event_model.dart';
import '../events/logic/event_controller.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();

  String _category = AppConstants.eventCategories.first;
  String _locationType = AppConstants.locationOnline;
  bool _isPaid = false;
  bool _certificateProvided = false;
  double? _price;

  // Date and time fields with validation
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final eventController = context.read<EventController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: AppConstants.eventCategories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _locationType,
                  items: const [
                    DropdownMenuItem(
                        value: AppConstants.locationOnline,
                        child: Text('Online')),
                    DropdownMenuItem(
                        value: AppConstants.locationOffline,
                        child: Text('Offline')),
                    DropdownMenuItem(
                        value: AppConstants.locationHybrid,
                        child: Text('Hybrid')),
                  ],
                  onChanged: (v) => setState(() => _locationType = v!),
                  decoration: const InputDecoration(labelText: 'Location Type'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),

                // Event Date Picker
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final firstDate = DateTime(now.year, now.month, now.day);
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? firstDate,
                      firstDate: firstDate,
                      lastDate: DateTime(now.year + 5),
                      helpText: 'Select Event Date',
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                        // Reset times when date changes to avoid confusion
                        if (_selectedStartTime != null ||
                            _selectedEndTime != null) {
                          _selectedStartTime = null;
                          _selectedEndTime = null;
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Event Date',
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorText: _selectedDate == null ? 'Required' : null,
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Event Start Time Picker
                InkWell(
                  onTap: _selectedDate == null
                      ? null
                      : () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedStartTime ?? TimeOfDay.now(),
                            helpText: 'Select Start Time',
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _selectedStartTime = pickedTime;
                              // Reset end time if it's before or equal to start time
                              if (_selectedEndTime != null) {
                                final startMinutes =
                                    _selectedStartTime!.hour * 60 +
                                        _selectedStartTime!.minute;
                                final endMinutes = _selectedEndTime!.hour * 60 +
                                    _selectedEndTime!.minute;
                                if (endMinutes <= startMinutes) {
                                  _selectedEndTime = null;
                                }
                              }
                            });
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      suffixIcon: const Icon(Icons.access_time),
                      errorText: _selectedStartTime == null ? 'Required' : null,
                    ),
                    child: Text(
                      _selectedStartTime == null
                          ? 'Select start time'
                          : _selectedStartTime!.format(context),
                      style: TextStyle(
                        color: _selectedStartTime == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Event End Time Picker
                InkWell(
                  onTap: _selectedStartTime == null
                      ? null
                      : () async {
                          // End time must be after start time
                          final startMinutes = _selectedStartTime!.hour * 60 +
                              _selectedStartTime!.minute;
                          final minEndTime = TimeOfDay(
                            hour: startMinutes ~/ 60,
                            minute: (startMinutes % 60) +
                                1, // At least 1 minute after start
                          );

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedEndTime ?? minEndTime,
                            helpText: 'Select End Time (must be after start)',
                          );
                          if (pickedTime != null) {
                            final pickedMinutes =
                                pickedTime.hour * 60 + pickedTime.minute;
                            if (pickedMinutes > startMinutes) {
                              setState(() {
                                _selectedEndTime = pickedTime;
                              });
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'End time must be after start time'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      suffixIcon: const Icon(Icons.access_time),
                      errorText: _selectedEndTime == null ? 'Required' : null,
                    ),
                    child: Text(
                      _selectedEndTime == null
                          ? 'Select end time'
                          : _selectedEndTime!.format(context),
                      style: TextStyle(
                        color: _selectedEndTime == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Paid Event'),
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                ),
                if (_isPaid)
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    onChanged: (v) => _price = double.tryParse(v),
                  ),
                SwitchListTile(
                  title: const Text('Certificate Provided'),
                  value: _certificateProvided,
                  onChanged: (v) => setState(() => _certificateProvided = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validate form fields
                      if (!_formKey.currentState!.validate()) return;

                      // Validate date and time fields
                      if (_selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select event date')),
                        );
                        return;
                      }

                      if (_selectedStartTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select start time')),
                        );
                        return;
                      }

                      if (_selectedEndTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select end time')),
                        );
                        return;
                      }

                      // Validate that date/time is not in the past
                      final now = DateTime.now();
                      final eventDate = _selectedDate!;
                      final startDateTime = DateTime(
                        eventDate.year,
                        eventDate.month,
                        eventDate.day,
                        _selectedStartTime!.hour,
                        _selectedStartTime!.minute,
                      );
                      final endDateTime = DateTime(
                        eventDate.year,
                        eventDate.month,
                        eventDate.day,
                        _selectedEndTime!.hour,
                        _selectedEndTime!.minute,
                      );

                      if (startDateTime.isBefore(now)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Event date and time cannot be in the past')),
                        );
                        return;
                      }

                      // Validate end time is after start time (extra check)
                      if (endDateTime.isBefore(startDateTime) ||
                          endDateTime.isAtSameMomentAs(startDateTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('End time must be after start time')),
                        );
                        return;
                      }

                      final uid = authService.currentUserId;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('User not authenticated')),
                        );
                        return;
                      }

                      // Create event with proper date and time handling
                      final event = EventModel(
                        id: const Uuid().v4(),
                        title: _titleController.text.trim(),
                        organizationId: uid,
                        organizationName: 'Organization',
                        category: _category,
                        locationType: _locationType,
                        location: _locationController.text,
                        date:
                            eventDate, // Event date (date only, for filtering)
                        startTime:
                            startDateTime, // Full DateTime with start time
                        endTime: endDateTime, // Full DateTime with end time
                        duration: _durationController.text,
                        isPaid: _isPaid,
                        price: _price,
                        certificateProvided: _certificateProvided,
                        registrationLimit: null,
                        approved: true,
                        createdAt: DateTime.now(),
                      );

                      try {
                        await eventController.createEvent(event);

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Event created successfully 🎉')),
                        );

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.orgHome,
                          (route) => false,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error creating event: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Create Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
