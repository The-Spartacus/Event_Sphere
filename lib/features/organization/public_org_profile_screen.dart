import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../app/app_config.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/user_profile_model.dart';
import '../events/data/event_repository.dart';
import '../events/data/event_model.dart';
import '../../widgets/event_card.dart';
import '../../app/routes.dart';

class PublicOrgProfileScreen extends StatelessWidget {
  final String organizationId;

  const PublicOrgProfileScreen({
    super.key,
    required this.organizationId,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Profile')),
      body: FutureBuilder<UserProfileModel?>(
        future: context.read<ProfileRepository>().getProfile(organizationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Organization not found'));
          }

          final org = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Logo and Name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: org.logoUrl != null
                            ? NetworkImage(org.logoUrl!)
                            : null,
                        child: org.logoUrl == null
                            ? Icon(Icons.business,
                                size: 50, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        org.organizationName ?? org.name,
                        style: AppTextStyles.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (org.verified == true) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Organization',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.blue),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                if (org.organizationDescription != null &&
                    org.organizationDescription!.isNotEmpty) ...[
                  Text('About', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    org.organizationDescription!,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                ],

                // Contact Info
                Text('Contact Information', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 16),
                _ContactRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: org.email,
                  onTap: () => _launchUrl('mailto:${org.email}'),
                ),
                if (org.officialWebsite != null &&
                    org.officialWebsite!.isNotEmpty)
                  _ContactRow(
                    icon: Icons.language,
                    label: 'Website',
                    value: org.officialWebsite!,
                    onTap: () => _launchUrl(org.officialWebsite!),
                  ),
                if (org.address != null && org.address!.isNotEmpty)
                  _ContactRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: org.address!,
                  ),
                if (org.contactPersonName != null &&
                    org.contactPersonName!.isNotEmpty)
                  _ContactRow(
                    icon: Icons.person,
                    label: 'Contact Person',
                    value: '${org.contactPersonName!} ${org.contactPersonPhone != null ? "(${org.contactPersonPhone})" : ""}',
                  ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Events List
                Text('Upcoming Events', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 16),
                StreamBuilder<List<EventModel>>(
                  stream: EventRepository().streamOrganizationEvents(organizationId),
                  builder: (context, eventSnapshot) {
                    if (eventSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final events = eventSnapshot.data ?? [];
                    // Filter mainly approved events for students viewing
                    // But if fetching raw stream, logic might need filtering. 
                    // Assuming streamOrganizationEvents returns all, we should filter safe.
                    // Ideally we should use a method that returns approved events for org.
                    // But for now, let's just filter client side.
                    final approvedEvents = events.where((e) => e.approved).toList();

                    if (approvedEvents.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No upcoming events'),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: approvedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                         final event = approvedEvents[index];
                         return EventCard(
                           title: event.title,
                           organization: event.organizationName,
                           date: event.date,
                           locationType: event.locationType,
                           isPaid: event.isPaid,
                           price: event.price,
                           organizationId: event.organizationId,
                           // Disable recursion or handle it gracefully
                           onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.eventDetails,
                                arguments: event.id,
                              );
                           },
                         );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        color: onTap != null ? AppColors.primary : null,
                        decoration: onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
