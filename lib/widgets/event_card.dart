import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../features/profile/logic/profile_controller.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../app/app_config.dart';
import '../app/routes.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String organization;
  final DateTime date;
  final String locationType;
  final bool isPaid;
  final double? price;
  final String organizationId;
  final VoidCallback onTap;
  final String? posterUrl;

  const EventCard({
    super.key,
    required this.title,
    required this.organization,
    required this.date,
    required this.locationType,
    required this.isPaid,
    this.price,
    required this.onTap,
    required this.organizationId,
    this.posterUrl,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      AppConfig.displayDateFormat,
    ).format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: (posterUrl != null && posterUrl!.isNotEmpty)
                      ? Image.network(
                          posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                ),
                // Date Badge Overlay if today/tomorrow
                if (_isToday(date) || _isTomorrow(date))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isToday(date) ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isToday(date) ? 'TODAY' : 'TOMORROW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Organization
                  Consumer<ProfileController>(
                    builder: (context, controller, _) {
                      final isSubscribed =
                          controller.profile?.subscribedOrgIds.contains(organizationId) ?? false;
                      final isOrgUser = controller.profile?.role == 'organization';

                      return Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.publicOrgProfile,
                                  arguments: organizationId,
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                child: Text(
                                  organization,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          if (!isOrgUser) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                controller.toggleSubscription(organizationId);
                                await controller.saveProfile();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isSubscribed
                                          ? 'Unsubscribed from $organization'
                                          : 'Subscribed to $organization'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  isSubscribed
                                      ? Icons.notifications_active
                                      : Icons.notifications_none,
                                  size: 16,
                                  color: isSubscribed ? AppColors.primary : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Footer (Date/Loc/Price)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formattedDate,
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? '₹${price ?? 0}' : 'FREE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid ? AppColors.primary : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.event,
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final now = DateTime.now().add(const Duration(days: 1));
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}


