import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../app/app_config.dart';
import '../events/data/event_model.dart';
import '../events/data/event_repository.dart';
import '../events/logic/event_controller.dart';

/// Screen for editing events
/// Only allows editing if:
/// 1. User is the event creator (organizationId matches current user)
/// 2. Event is not yet approved (approved == false)
/// Editable fields: title, date, start/end time, location, price, certificate availability
/// Immutable fields: organizationId, organizationName, createdAt, approved
class EditEventScreen extends StatefulWidget {
  final String eventId;

  const EditEventScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();

  EventModel? _originalEvent;
  bool _isLoading = true;
  String? _error;
  
  String _category = AppConstants.eventCategories.first;
  String _locationType = AppConstants.locationOnline;
  bool _isPaid = false;
  bool _certificateProvided = false;
  double? _price;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  /// Load event data and verify edit permissions
  Future<void> _loadEvent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final event = await EventRepository().getEventById(widget.eventId);
      
      if (event == null) {
        setState(() {
          _error = 'Event not found';
          _isLoading = false;
        });
        return;
      }

      // Security check: Verify user is the creator
      final authService = context.read<AuthService>();
      final currentUserId = authService.currentUserId;
      
      if (currentUserId != event.organizationId) {
        setState(() {
          _error = 'You do not have permission to edit this event';
          _isLoading = false;
        });
        return;
      }

      // Security check: Verify event is not approved
      if (event.approved) {
        setState(() {
          _error = 'Cannot edit approved events. Please contact admin for changes.';
          _isLoading = false;
        });
        return;
      }

      // Load event data into form
      _originalEvent = event;
      _titleController.text = event.title;
      _locationController.text = event.location;
      _durationController.text = event.duration;
      _category = event.category;
      _locationType = event.locationType;
      _isPaid = event.isPaid;
      _price = event.price;
      _certificateProvided = event.certificateProvided;
      _selectedDate = event.date;
      _selectedStartTime = TimeOfDay.fromDateTime(event.startTime);
      _selectedEndTime = TimeOfDay.fromDateTime(event.endTime);

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading event: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Event')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Event')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          if (_originalEvent != null && !_originalEvent!.approved)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _hasChanges ? _saveEvent : null,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Security notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only unapproved events can be edited. Changes will require re-approval.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (_) => _markAsChanged(),
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
                  onChanged: (v) {
                    setState(() => _category = v!);
                    _markAsChanged();
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _locationType,
                  items: const [
                    DropdownMenuItem(
                      value: AppConstants.locationOnline,
                      child: Text('Online'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.locationOffline,
                      child: Text('Offline'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.locationHybrid,
                      child: Text('Hybrid'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _locationType = v!);
                    _markAsChanged();
                  },
                  decoration: const InputDecoration(labelText: 'Location Type'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (_) => _markAsChanged(),
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
                        _markAsChanged();
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Event Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
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
                              _markAsChanged();
                              // Reset end time if invalid
                              if (_selectedEndTime != null) {
                                final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
                                final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
                                if (endMinutes <= startMinutes) {
                                  _selectedEndTime = null;
                                }
                              }
                            });
                          }
                        },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _selectedStartTime == null
                          ? 'Select start time'
                          : _selectedStartTime!.format(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Event End Time Picker
                InkWell(
                  onTap: _selectedStartTime == null
                      ? null
                      : () async {
                          final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
                          final minEndTime = TimeOfDay(
                            hour: startMinutes ~/ 60,
                            minute: (startMinutes % 60) + 1,
                          );
                          
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedEndTime ?? minEndTime,
                            helpText: 'Select End Time (must be after start)',
                          );
                          if (pickedTime != null) {
                            final pickedMinutes = pickedTime.hour * 60 + pickedTime.minute;
                            if (pickedMinutes > startMinutes) {
                              setState(() {
                                _selectedEndTime = pickedTime;
                                _markAsChanged();
                              });
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('End time must be after start time'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _selectedEndTime == null
                          ? 'Select end time'
                          : _selectedEndTime!.format(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Duration (e.g., 2 hours)'),
                  onChanged: (_) => _markAsChanged(),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Paid Event'),
                  value: _isPaid,
                  onChanged: (v) {
                    setState(() {
                      _isPaid = v;
                      if (!v) _price = null;
                      _markAsChanged();
                    });
                  },
                ),
                if (_isPaid)
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    initialValue: _price?.toString(),
                    onChanged: (v) {
                      _price = double.tryParse(v);
                      _markAsChanged();
                    },
                  ),
                SwitchListTile(
                  title: const Text('Certificate Provided'),
                  value: _certificateProvided,
                  onChanged: (v) {
                    setState(() {
                      _certificateProvided = v;
                      _markAsChanged();
                    });
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _saveEvent : null,
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_originalEvent == null) return;

    // Validate date and time
    if (_selectedDate == null || _selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and times')),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    if (startDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event date and time cannot be in the past')),
      );
      return;
    }

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      // Create updated event with immutable fields preserved
      final updatedEvent = _originalEvent!.copyWith(
        title: _titleController.text.trim(),
        category: _category,
        locationType: _locationType,
        location: _locationController.text,
        date: _selectedDate!,
        startTime: startDateTime,
        endTime: endDateTime,
        duration: _durationController.text,
        isPaid: _isPaid,
        price: _price,
        certificateProvided: _certificateProvided,
        // Note: approved, organizationId, organizationName, createdAt remain unchanged
      );

      final eventController = context.read<EventController>();
      await eventController.updateEvent(updatedEvent);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated successfully 🎉'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating event: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

