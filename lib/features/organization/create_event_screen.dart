import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../app/app_config.dart';
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
                  decoration:
                      const InputDecoration(labelText: 'Event Title'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
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
                  decoration:
                      const InputDecoration(labelText: 'Category'),
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
                  onChanged: (v) =>
                      setState(() => _locationType = v!),
                  decoration:
                      const InputDecoration(labelText: 'Location Type'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  decoration:
                      const InputDecoration(labelText: 'Location'),
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
                    decoration:
                        const InputDecoration(labelText: 'Price'),
                    onChanged: (v) =>
                        _price = double.tryParse(v),
                  ),

                SwitchListTile(
                  title: const Text('Certificate Provided'),
                  value: _certificateProvided,
                  onChanged: (v) =>
                      setState(() => _certificateProvided = v),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      // 🔴 FIX 1: NEVER allow empty organizationId
                      final uid = authService.currentUserId;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User not authenticated'),
                          ),
                        );
                        return;
                      }

                      // 🔍 DEBUG (temporary)
                      debugPrint('DEBUG UID: $uid');

                      final event = EventModel(
                        id: const Uuid().v4(),
                        title: _titleController.text.trim(),

                        // ✅ FIXED
                        organizationId: uid,

                        organizationName: 'Organization',
                        category: _category,
                        locationType: _locationType,
                        location: _locationController.text,
                        date: DateTime.now(),
                        duration: _durationController.text,
                        isPaid: _isPaid,
                        price: _price,
                        certificateProvided: _certificateProvided,
                        registrationLimit: null,

                        // 🔒 REQUIRED BY RULES
                        approved: false,
                        createdAt: DateTime.now(),
                      );

                      // 🔍 DEBUG (temporary)
                      debugPrint(
                          'DEBUG ORG ID IN EVENT: ${event.organizationId}');
                      debugPrint(
                          'DEBUG APPROVED: ${event.approved}');

                      await eventController.createEvent(event);

                      if (!mounted) return;
                      Navigator.pop(context);
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
}
