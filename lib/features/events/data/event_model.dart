import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String organizationId;
  final String organizationName;
  final String category;
  final String locationType; // online | offline | hybrid
  final String location;
  final DateTime date;
  final String duration;
  final bool isPaid;
  final double? price;
  final bool certificateProvided;
  final int? registrationLimit;
  final bool approved;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.organizationId,
    required this.organizationName,
    required this.category,
    required this.locationType,
    required this.location,
    required this.date,
    required this.duration,
    required this.isPaid,
    this.price,
    required this.certificateProvided,
    this.registrationLimit,
    required this.approved,
    required this.createdAt,
  });

  /// Create EventModel from Firestore document
  factory EventModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      organizationId: data['organizationId'] ?? '',
      organizationName: data['organizationName'] ?? '',
      category: data['category'] ?? '',
      locationType: data['locationType'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      duration: data['duration'] ?? '',
      isPaid: data['isPaid'] ?? false,
      price: data['price'] != null
          ? (data['price'] as num).toDouble()
          : null,
      certificateProvided: data['certificateProvided'] ?? false,
      registrationLimit: data['registrationLimit'],
      approved: data['approved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert EventModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'category': category,
      'locationType': locationType,
      'location': location,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'isPaid': isPaid,
      'price': price,
      'certificateProvided': certificateProvided,
      'registrationLimit': registrationLimit,
      'approved': approved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy helper
  EventModel copyWith({
    String? title,
    String? category,
    String? locationType,
    String? location,
    DateTime? date,
    String? duration,
    bool? isPaid,
    double? price,
    bool? certificateProvided,
    int? registrationLimit,
    bool? approved,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      organizationId: organizationId,
      organizationName: organizationName,
      category: category ?? this.category,
      locationType: locationType ?? this.locationType,
      location: location ?? this.location,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      certificateProvided:
          certificateProvided ?? this.certificateProvided,
      registrationLimit:
          registrationLimit ?? this.registrationLimit,
      approved: approved ?? this.approved,
      createdAt: createdAt,
    );
  }
}
