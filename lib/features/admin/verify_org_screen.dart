import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../app/app_config.dart';

import 'widgets/admin_drawer.dart';

class VerifyOrgScreen extends StatelessWidget {
  const VerifyOrgScreen({super.key});

  Future<void> _updateVerification(
    String orgId,
    bool verified,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Update organizations collection
    final orgRef = FirebaseFirestore.instance
        .collection(ApiEndpoints.organizations)
        .doc(orgId);
    batch.update(orgRef, {'verified': verified});
    
    // Update users collection (so the Org User actually gets the status)
    final userRef = FirebaseFirestore.instance
        .collection(ApiEndpoints.users)
        .doc(orgId);
    batch.update(userRef, {'verified': verified});

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(ApiEndpoints.organizations)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No organizations found',
              style: AppTextStyles.body,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data();
            final verified = data['verified'] == true;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConfig.borderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Organization',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          verified ? 'Verified' : 'Pending',
                        ),
                        backgroundColor: verified
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                      ),
                      const Spacer(),
                      if (!verified)
                        ElevatedButton(
                          onPressed: () async {
                            await _updateVerification(
                              doc.id,
                              true,
                            );
                          },
                          child: const Text('Approve'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
