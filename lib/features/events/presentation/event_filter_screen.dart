import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../app/app_config.dart';
import '../logic/event_controller.dart';

class EventFilterScreen extends StatefulWidget {
  const EventFilterScreen({super.key});

  @override
  State<EventFilterScreen> createState() => _EventFilterScreenState();
}

class _EventFilterScreenState extends State<EventFilterScreen> {
  String? _selectedCategory;
  String? _selectedLocation;
  bool? _isPaid;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<EventController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Events'),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: AppTextStyles.title),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: AppConstants.eventCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              decoration:
                  const InputDecoration(hintText: 'Select category'),
            ),

            const SizedBox(height: 24),
            Text('Location Type', style: AppTextStyles.title),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
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
              onChanged: (value) {
                setState(() => _selectedLocation = value);
              },
              decoration:
                  const InputDecoration(hintText: 'Select location'),
            ),

            const SizedBox(height: 24),
            Text('Price Type', style: AppTextStyles.title),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(
                _isPaid == true ? 'Paid Events' : 'Free Events',
                style: AppTextStyles.body,
              ),
              value: _isPaid ?? false,
              onChanged: (value) {
                setState(() => _isPaid = value);
              },
              activeColor: AppColors.primary,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  controller.applyFilters(
                    category: _selectedCategory,
                    locationType: _selectedLocation,
                    isPaid: _isPaid,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
