import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/theme/text_styles.dart';

class ParticipantsScreen extends StatelessWidget {
  final String eventId;

  const ParticipantsScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(ApiEndpoints.registrations)
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No participants yet',
                style: AppTextStyles.body,
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data();
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['userId'] ?? 'Student'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
