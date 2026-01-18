import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../app/app_config.dart';
import '../../app/routes.dart';
import '../events/data/event_model.dart';
import '../events/logic/event_controller.dart';
import '../profile/logic/profile_controller.dart';
import '../profile/data/storage_service.dart';

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
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _venueController = TextEditingController();
  final _seatLimitController = TextEditingController();
  final _featureController = TextEditingController();

  String _category = AppConstants.eventCategories.first;
  String _locationType = AppConstants.locationOnline;
  bool _isPaid = false;
  bool _certificateProvided = false;
  double? _price;
  
  // New Fields
  DateTime? _registrationDeadline;

  // Date and time fields
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  // New fields
  File? _posterImage;
  final List<String> _features = [];
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _posterImage = File(pickedFile.path);
      });
    }
  }

  void _addFeature() {
    final text = _featureController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _features.add(text);
        _featureController.clear();
      });
    }
  }

  void _removeFeature(String feature) {
    setState(() {
      _features.remove(feature);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final eventController = context.read<EventController>();
    final profileController = context.watch<ProfileController>();
    final isVerified = profileController.profile?.verified == true;

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
                if (!isVerified)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(AppConfig.borderRadius),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your organization is not verified yet. You cannot create events until approved.',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Poster Image Upload
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(AppConfig.borderRadius),
                      border: Border.all(color: Colors.grey.shade300),
                      image: _posterImage != null
                          ? DecorationImage(
                              image: FileImage(_posterImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _posterImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Upload Event Poster',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
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
                  decoration: const InputDecoration(labelText: 'Location/City'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Detailed Venue
                if (_locationType != AppConstants.locationOnline) ...[
                   TextFormField(
                    controller: _venueController,
                    decoration: const InputDecoration(labelText: 'Detailed Venue (Hall/Room)'),
                    validator: (v) => v == null || v.isEmpty ? 'Required for offline events' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mapsLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Google Maps Link',
                       prefixIcon: Icon(Icons.map),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                ],

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

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectedDate == null
                            ? null
                            : () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      _selectedStartTime ?? TimeOfDay.now(),
                                  helpText: 'Start Time',
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    _selectedStartTime = pickedTime;
                                    if (_selectedEndTime != null) {
                                      final startMinutes =
                                          _selectedStartTime!.hour * 60 +
                                              _selectedStartTime!.minute;
                                      final endMinutes =
                                          _selectedEndTime!.hour * 60 +
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
                            errorText:
                                _selectedStartTime == null ? 'Required' : null,
                          ),
                          child: Text(
                            _selectedStartTime == null
                                ? '--:--'
                                : _selectedStartTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectedStartTime == null
                            ? null
                            : () async {
                                final startMinutes = _selectedStartTime!.hour * 60 +
                                    _selectedStartTime!.minute;
                                final minEndTime = TimeOfDay(
                                  hour: startMinutes ~/ 60,
                                  minute: (startMinutes % 60) + 1,
                                );

                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedEndTime ?? minEndTime,
                                  helpText: 'End Time',
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
                                                'End time must be after start')),
                                      );
                                    }
                                  }
                                }
                              },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            errorText:
                                _selectedEndTime == null ? 'Required' : null,
                          ),
                          child: Text(
                            _selectedEndTime == null
                                ? '--:--'
                                : _selectedEndTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g., 3 hours, 2 days',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Registration/Info Link (Optional)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),
                
                // Registration Deadline
                 InkWell(
                  onTap: () async {
                    if (_selectedDate == null) {
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select Event Date first')),
                        );
                        return;
                    }
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _registrationDeadline ?? now,
                      firstDate: now,
                      lastDate: _selectedDate!, // Cannot be after event
                      helpText: 'Select Registration Deadline',
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _registrationDeadline = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Registration Deadline',
                      suffixIcon: const Icon(Icons.timer_off_outlined),
                      errorText: _registrationDeadline == null ? null : null, // Optional
                      hintText: 'Optional'
                    ),
                    child: Text(
                      _registrationDeadline == null
                          ? 'Set Deadline (Optional)'
                          : '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year}',
                      style: TextStyle(
                        color: _registrationDeadline == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Seat Limit
                 TextFormField(
                  controller: _seatLimitController,
                   decoration: const InputDecoration(
                    labelText: 'Seat Limit / Capacity',
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Key Features
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Key Features (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _features
                          .map((f) => Chip(
                                label: Text(f),
                                onDeleted: () => _removeFeature(f),
                              ))
                          .toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _featureController,
                            decoration: const InputDecoration(
                              hintText: 'Add a feature point',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.blue),
                          onPressed: _addFeature,
                        ),
                      ],
                    ),
                  ],
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
                    onPressed: !isVerified || _isUploading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                             if (_selectedDate == null ||
                                _selectedStartTime == null ||
                                _selectedEndTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select date and times')),
                              );
                              return;
                            }
                            
                            // Deadline Validation
                            if (_registrationDeadline != null && _registrationDeadline!.isAfter(_selectedDate!)) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Registration deadline cannot be after event date')),
                              );
                              return;
                            }

                            final uid = authService.currentUserId;
                            if (uid == null) return;

                            setState(() => _isUploading = true);

                            try {
                              // Generate ID
                              final eventId = const Uuid().v4();
                              
                              // Upload Poster
                              String? posterUrl;
                              if (_posterImage != null) {
                                posterUrl = await context
                                    .read<StorageService>()
                                    .uploadEventPoster(
                                      eventId: eventId,
                                      imageFile: _posterImage!,
                                    );
                              }
                              
                              // Construct DateTimes
                              final eventDate = _selectedDate!;
                              final startDateTime = DateTime(
                                eventDate.year, eventDate.month, eventDate.day,
                                _selectedStartTime!.hour, _selectedStartTime!.minute,
                              );
                              final endDateTime = DateTime(
                                eventDate.year, eventDate.month, eventDate.day,
                                _selectedEndTime!.hour, _selectedEndTime!.minute,
                              );

                              // Create Event
                              final event = EventModel(
                                id: eventId,
                                title: _titleController.text.trim(),
                                organizationId: uid,
                                organizationName: profileController.profile?.name ?? 'Organization',
                                category: _category,
                                locationType: _locationType,
                                location: _locationController.text,
                                date: eventDate,
                                startTime: startDateTime,
                                endTime: endDateTime,
                                duration: _durationController.text,
                                isPaid: _isPaid,
                                price: _price,
                                certificateProvided: _certificateProvided,
                                registrationLimit: int.tryParse(_seatLimitController.text),
                                approved: true, // Auto-approved for verified orgs
                                createdAt: DateTime.now(),
                                posterUrl: posterUrl,
                                description: _descriptionController.text.trim(),
                                keyFeatures: _features,
                                registrationLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
                                venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
                                googleMapsLink: _mapsLinkController.text.trim().isEmpty ? null : _mapsLinkController.text.trim(),
                                registrationDeadline: _registrationDeadline,

                              );

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
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            } finally {
                              if (mounted) setState(() => _isUploading = false);
                            }
                          },
                    child: _isUploading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        ) 
                      : const Text('Create Event'),
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
    _descriptionController.dispose();
    _linkController.dispose();
    _mapsLinkController.dispose();
    _venueController.dispose();
    _seatLimitController.dispose();
    _featureController.dispose();
    super.dispose();
  }
}
