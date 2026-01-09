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
  });

  /// Create EventModel from Firestore document
  /// Handles backward compatibility: if startTime/endTime are missing, uses date with default times
  factory EventModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final date = (data['date'] as Timestamp).toDate();
    
    // Handle backward compatibility: if startTime/endTime exist, use them; otherwise derive from date
    DateTime startTime;
    DateTime endTime;
    
    if (data['startTime'] != null && data['endTime'] != null) {
      // New format: separate date, startTime, and endTime
      startTime = (data['startTime'] as Timestamp).toDate();
      endTime = (data['endTime'] as Timestamp).toDate();
    } else {
      // Legacy format: derive start/end from date field
      // Default to 9 AM start, 5 PM end for backward compatibility
      startTime = DateTime(
        date.year,
        date.month,
        date.day,
        9,
        0,
      );
      endTime = DateTime(
        date.year,
        date.month,
        date.day,
        17,
        0,
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
  /// Stores date, startTime, and endTime as Firestore Timestamps for proper querying
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
    };
  }

  /// Copy helper for creating modified instances
  /// Ensures organizationId, organizationName, createdAt, and id remain immutable
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
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      organizationId: organizationId, // Immutable: cannot change owner
      organizationName: organizationName, // Immutable: cannot change owner name
      category: category ?? this.category,
      locationType: locationType ?? this.locationType,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      certificateProvided:
          certificateProvided ?? this.certificateProvided,
      registrationLimit:
          registrationLimit ?? this.registrationLimit,
      approved: approved ?? this.approved, // Typically set by admin, but allowed for flexibility
      createdAt: createdAt, // Immutable: creation timestamp never changes
    );
  }
}
