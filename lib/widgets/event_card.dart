import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../app/app_config.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String organization;
  final DateTime date;
  final String locationType;
  final bool isPaid;
  final double? price;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.organization,
    required this.date,
    required this.locationType,
    required this.isPaid,
    this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      AppConfig.displayDateFormat,
    ).format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: AppTextStyles.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Organization
            Text(
              organization,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),

            // Meta row
            Row(
              children: [
                _MetaChip(
                  icon: Icons.calendar_today,
                  label: formattedDate,
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.location_on,
                  label: locationType.toUpperCase(),
                ),
                const Spacer(),
                _PriceChip(
                  isPaid: isPaid,
                  price: price,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final bool isPaid;
  final double? price;

  const _PriceChip({
    required this.isPaid,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? '₹${price ?? 0}' : 'FREE',
        style: AppTextStyles.bodyBold.copyWith(
          color: isPaid ? AppColors.warning : AppColors.success,
        ),
      ),
    );
  }
}
