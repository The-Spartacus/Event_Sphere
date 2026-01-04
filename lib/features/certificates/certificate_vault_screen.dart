import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../app/app_config.dart';
import 'certificate_model.dart';
import 'certificate_viewer.dart';

class CertificateVaultScreen extends StatelessWidget {
  const CertificateVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(ApiEndpoints.certificates)
            .where('userId', isEqualTo: userId)
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No certificates available',
                style: AppTextStyles.body,
              ),
            );
          }

          final certificates = snapshot.data!.docs
              .map((doc) => CertificateModel.fromDoc(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            itemCount: certificates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cert = certificates[index];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConfig.borderRadius),
                ),
                tileColor: AppColors.surface,
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Certificate ${index + 1}',
                  style: AppTextStyles.bodyBold,
                ),
                subtitle: Text(
                  'Issued on ${cert.uploadedAt.toLocal()}',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificateViewer(
                        fileUrl: cert.fileUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
