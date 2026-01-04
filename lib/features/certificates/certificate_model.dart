import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String id;
  final String eventId;
  final String userId;
  final String organizationId;
  final String fileUrl;
  final DateTime uploadedAt;

  CertificateModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.organizationId,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory CertificateModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CertificateModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      organizationId: data['organizationId'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'organizationId': organizationId,
      'fileUrl': fileUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
