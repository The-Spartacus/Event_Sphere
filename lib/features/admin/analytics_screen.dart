import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/theme/text_styles.dart';
import '../../app/app_config.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<int> _count(String collection) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Statistics',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 24),

            _StatTile(
              label: 'Total Users',
              future: _count(ApiEndpoints.users),
            ),
            _StatTile(
              label: 'Organizations',
              future: _count(ApiEndpoints.organizations),
            ),
            _StatTile(
              label: 'Events',
              future: _count(ApiEndpoints.events),
            ),
            _StatTile(
              label: 'Certificates Issued',
              future: _count(ApiEndpoints.certificates),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final Future<int> future;

  const _StatTile({
    required this.label,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyBold,
                ),
              ),
              Text(
                snapshot.hasData ? snapshot.data.toString() : '...',
                style: AppTextStyles.body,
              ),
            ],
          ),
        );
      },
    );
  }
}
