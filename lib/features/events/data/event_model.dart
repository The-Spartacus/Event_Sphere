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
  final DateTime startTime; // Event start time (Firestore-safe Timestamp)
  final DateTime endTime; // Event end time (Firestore-safe Timestamp)
  final String duration;
  final bool isPaid;
  final double? price;
  final bool certificateProvided;
  final int? registrationLimit;
  final bool approved;
  final DateTime createdAt;

  // New fields
  final String? posterUrl;
  final String? description;
  final List<String>? keyFeatures;
  final String? registrationLink;

  
  // Premium Features
  final String? venue;
  final String? googleMapsLink;
  final DateTime? registrationDeadline;
  final int views;
  final List<String> interestedUserIds;

  // Promotion/Ad Features
  final String promotionStatus; // none, pending, approved, rejected
  final String promotionTarget; // none, district, global

  EventModel({
    required this.id,
    required this.title,
    required this.organizationId,
    required this.organizationName,
    required this.category,
    required this.locationType,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isPaid,
    this.price,
    required this.certificateProvided,
    this.registrationLimit,
    required this.approved,
    required this.createdAt,
    this.posterUrl,
    this.description,
    this.keyFeatures,
    this.registrationLink,

    this.venue,
    this.googleMapsLink,
    this.registrationDeadline,
    this.views = 0,
    this.interestedUserIds = const [],
    this.promotionStatus = 'none',
    this.promotionTarget = 'none',
  });

  factory EventModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final date = (data['date'] as Timestamp).toDate();
    
    DateTime startTime;
    DateTime endTime;
    
    if (data['startTime'] != null && data['endTime'] != null) {
      startTime = (data['startTime'] as Timestamp).toDate();
      endTime = (data['endTime'] as Timestamp).toDate();
    } else {
      startTime = DateTime(
        date.year, date.month, date.day, 9, 0,
      );
      endTime = DateTime(
        date.year, date.month, date.day, 17, 0,
      );
    }
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      organizationId: data['organizationId'] ?? '',
      organizationName: data['organizationName'] ?? '',
      category: data['category'] ?? '',
      locationType: data['locationType'] ?? '',
      location: data['location'] ?? '',
      date: date,
      startTime: startTime,
      endTime: endTime,
      duration: data['duration'] ?? '',
      isPaid: data['isPaid'] ?? false,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      certificateProvided: data['certificateProvided'] ?? false,
      registrationLimit: data['registrationLimit'],
      approved: data['approved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      posterUrl: data['posterUrl'],
      description: data['description'],
      keyFeatures: data['keyFeatures'] != null
          ? List<String>.from(data['keyFeatures'])
          : null,
      registrationLink: data['registrationLink'],
      venue: data['venue'],
      googleMapsLink: data['googleMapsLink'],
      registrationDeadline: data['registrationDeadline'] != null
          ? (data['registrationDeadline'] as Timestamp).toDate()
          : null,
      views: data['views'] ?? 0,
      interestedUserIds: data['interestedUserIds'] != null
          ? List<String>.from(data['interestedUserIds'])
          : [],
      promotionStatus: data['promotionStatus'] ?? 'none',
      promotionTarget: data['promotionTarget'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'category': category,
      'locationType': locationType,
      'location': location,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'duration': duration,
      'isPaid': isPaid,
      'price': price,
      'certificateProvided': certificateProvided,
      'registrationLimit': registrationLimit,
      'approved': approved,
      'createdAt': Timestamp.fromDate(createdAt),
      'posterUrl': posterUrl,
      'description': description,
      'keyFeatures': keyFeatures,
      'registrationLink': registrationLink,
      'venue': venue,
      'googleMapsLink': googleMapsLink,
      'registrationDeadline': registrationDeadline != null
          ? Timestamp.fromDate(registrationDeadline!)
          : null,
      'views': views,
      'interestedUserIds': interestedUserIds,
      'promotionStatus': promotionStatus,
      'promotionTarget': promotionTarget,
    };
  }

  EventModel copyWith({
    String? title,
    String? category,
    String? locationType,
    String? location,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? duration,
    bool? isPaid,
    double? price,
    bool? certificateProvided,
    int? registrationLimit,
    bool? approved,
    String? posterUrl,
    String? description,
    List<String>? keyFeatures,

    String? registrationLink,
    String? venue,
    String? googleMapsLink,
    DateTime? registrationDeadline,
    int? views,
    List<String>? interestedUserIds,
    String? promotionStatus,
    String? promotionTarget,
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
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      certificateProvided: certificateProvided ?? this.certificateProvided,
      registrationLimit: registrationLimit ?? this.registrationLimit,
      approved: approved ?? this.approved,
      createdAt: createdAt,
      posterUrl: posterUrl ?? this.posterUrl,
      description: description ?? this.description,
      keyFeatures: keyFeatures ?? this.keyFeatures,
      registrationLink: registrationLink ?? this.registrationLink,
      venue: venue ?? this.venue,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      views: views ?? this.views,
      interestedUserIds: interestedUserIds ?? this.interestedUserIds,
      promotionStatus: promotionStatus ?? this.promotionStatus,
      promotionTarget: promotionTarget ?? this.promotionTarget,
    );
  }
}
