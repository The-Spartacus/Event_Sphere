import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_sphere/core/theme/text_styles.dart';
import 'package:event_sphere/core/theme/colors.dart';
import 'package:event_sphere/core/services/auth_service.dart';
import '../../data/event_repository.dart';
import '../../data/review_model.dart';
import 'package:event_sphere/features/profile/logic/profile_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReviewsWidget extends StatelessWidget {
  final String eventId;
  final EventRepository _repository = EventRepository();

  ReviewsWidget({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: AppTextStyles.headlineMedium,
            ),
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(context),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Add Review'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ReviewModel>>(
          stream: _repository.streamReviews(eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: AppTextStyles.body.copyWith(color: Colors.grey),
                  ),
                ),
              );
            }

            final reviews = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: review.userPhotoUrl != null
                          ? CachedNetworkImageProvider(review.userPhotoUrl!)
                          : null,
                      child: review.userPhotoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(review.userName, style: AppTextStyles.bodyBold),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < review.rating ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(review.comment, style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    final authService = context.read<AuthService>();
    final profile = context.read<ProfileController>().profile;
    
    if (authService.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add a review')),
      );
      return;
    }

    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 32,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = i + 1.0),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isEmpty) return;

                final review = ReviewModel(
                  id: '',
                  eventId: eventId,
                  userId: authService.currentUserId!,
                  userName: profile?.name ?? 'User',
                  userPhotoUrl: profile?.profilePhotoUrl,
                  rating: rating,
                  comment: commentController.text,
                  createdAt: DateTime.now(),
                );

                await _repository.addReview(eventId, review);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
