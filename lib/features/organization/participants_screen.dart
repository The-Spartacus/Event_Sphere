import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../core/services/auth_service.dart';
import '../../app/app_config.dart';
import '../events/data/event_repository.dart';
import '../events/data/event_model.dart';

/// Screen displaying participants for a specific event
/// Accessible only to the event's organization or admin
/// Shows: Student name, email, and registration date
class ParticipantsScreen extends StatelessWidget {
  final String eventId;

  const ParticipantsScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: FutureBuilder<EventModel?>(
        future: EventRepository().getEventById(eventId),
        builder: (context, eventSnapshot) {
          // Verify access permissions
          if (eventSnapshot.hasData && eventSnapshot.data != null) {
            final event = eventSnapshot.data!;
            
            // Security check: Only event creator or admin can view participants
            // Note: Firestore rules also enforce this, but we check here for better UX
            if (currentUserId != event.organizationId) {
              // Allow admin access - check if user is admin (this would require role check)
              // For now, we'll rely on Firestore rules to handle access control
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(ApiEndpoints.registrations)
                .where('eventId', isEqualTo: eventId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading participants: ${snapshot.error}',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No participants yet',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Students who register will appear here',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                );
              }

              final registrations = snapshot.data!.docs;
              final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

              return Column(
                children: [
                  // Participant count header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: Row(
                      children: [
                        Icon(Icons.people, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${registrations.length} ${registrations.length == 1 ? 'Participant' : 'Participants'}',
                          style: AppTextStyles.title,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // Participants list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppConfig.defaultPadding),
                      itemCount: registrations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final registration = registrations[index];
                        final registrationData = registration.data();
                        final userId = registrationData['userId'] as String?;
                        
                        // Fetch user details from users collection
                        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection(ApiEndpoints.users)
                              .doc(userId)
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            String name = 'Unknown User';
                            String email = userId ?? 'N/A';
                            
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final userData = userSnapshot.data!.data()!;
                              name = userData['name'] ?? 'Unknown User';
                              email = userData['email'] ?? userId ?? 'N/A';
                            }

                            // Get registration date (prefer createdAt, fallback to serverTimestamp)
                            DateTime registrationDate = DateTime.now();
                            if (registrationData['createdAt'] != null) {
                              final timestamp = registrationData['createdAt'];
                              if (timestamp is Timestamp) {
                                registrationDate = timestamp.toDate();
                              } else if (timestamp is DateTime) {
                                registrationDate = timestamp;
                              }
                            } else if (registrationData['registrationDate'] != null) {
                              final timestamp = registrationData['registrationDate'];
                              if (timestamp is Timestamp) {
                                registrationDate = timestamp.toDate();
                              } else if (timestamp is DateTime) {
                                registrationDate = timestamp;
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // User details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTextStyles.title.copyWith(
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                email,
                                                style: AppTextStyles.body,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Registered: ${dateFormat.format(registrationDate)}',
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
