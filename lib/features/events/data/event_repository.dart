import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import 'event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all approved events (for students)
  Stream<List<EventModel>> streamApprovedEvents() {
    return _firestore
        .collection(ApiEndpoints.events)
        .where('approved', isEqualTo: true)
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromDoc(doc))
              .toList(),
        );
  }

  /// Stream pending ad events (for admins)
  Stream<List<EventModel>> streamPendingAdEvents() {
    return _firestore
        .collection(ApiEndpoints.events)
        .where('promotionStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromDoc(doc))
              .toList(),
        );
  }

  /// Stream events created by an organization
  Stream<List<EventModel>> streamOrganizationEvents(
    String organizationId,
  ) {
    return _firestore
        .collection(ApiEndpoints.events)
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromDoc(doc))
              .toList(),
        );
  }

  /// Get single event by ID
  Future<EventModel?> getEventById(String eventId) async {
    final doc = await _firestore
        .collection(ApiEndpoints.events)
        .doc(eventId)
        .get();

    if (!doc.exists) return null;
    return EventModel.fromDoc(doc);
  }

  /// Create new event
  Future<void> createEvent(EventModel event) async {
    await _firestore
        .collection(ApiEndpoints.events)
        .doc(event.id)
        .set(event.toMap());
  }

  /// Update existing event
  Future<void> updateEvent(EventModel event) async {
    await _firestore
        .collection(ApiEndpoints.events)
        .doc(event.id)
        .update(event.toMap());
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    await _firestore
        .collection(ApiEndpoints.events)
        .doc(eventId)
        .delete();
  }

  /// Filter events dynamically with date ranges and organization name
  Stream<List<EventModel>> filterEvents({
    String? category,
    String? locationType,
    bool? isPaid,
    DateTime? startDate,
    DateTime? endDate,
    String? organizationNameQuery,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(ApiEndpoints.events)
            .where('approved', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (locationType != null) {
      query = query.where('locationType', isEqualTo: locationType);
    }

    if (isPaid != null) {
      query = query.where('isPaid', isEqualTo: isPaid);
    }

    // Date range filtering
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('date').snapshots().map((snapshot) {
      var events = snapshot.docs.map((doc) => EventModel.fromDoc(doc)).toList();

      // Client-side filtering for Organization Name (Firestore limitation on multiple inequalities)
      if (organizationNameQuery != null && organizationNameQuery.isNotEmpty) {
        final queryLower = organizationNameQuery.toLowerCase();
        events = events.where((event) {
          return event.organizationName.toLowerCase().contains(queryLower);
        }).toList();
      }

      return events;
    });
  }
  
  /// Get participant count for an event
  /// Returns a stream of the count of registrations for a given event
  Stream<int> getParticipantCount(String eventId) {
    return _firestore
        .collection(ApiEndpoints.registrations)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  /// Get participant count as a future (for one-time reads)
  Future<int> getParticipantCountFuture(String eventId) async {
    final snapshot = await _firestore
        .collection(ApiEndpoints.registrations)
        .where('eventId', isEqualTo: eventId)
        .get();
    return snapshot.docs.length;
  }

  /// Get events by a list of IDs (handles whereIn limit of 10)
  Future<List<EventModel>> getEventsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore whereIn is limited to 10 items
    final List<EventModel> events = [];
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    for (var chunk in chunks) {
      final snapshot = await _firestore
          .collection(ApiEndpoints.events)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      
      events.addAll(
        snapshot.docs.map((doc) => EventModel.fromDoc(doc)).toList(),
      );
    }
    
  // Sort logic could go here, or handled by caller.
    return events;
  }

  /// Get list of event IDs that a user has registered for
  Future<List<String>> getRegisteredEventIds(String userId) async {
    final snapshot = await _firestore
        .collection(ApiEndpoints.registrations)
        .where('userId', isEqualTo: userId)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()['eventId'] as String).toList();
  }

  /// Get specific registration ID for a user and event
  Future<String?> getRegistrationId(String userId, String eventId) async {
    final snapshot = await _firestore
        .collection(ApiEndpoints.registrations)
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  /// Check if user is registered
  Future<bool> isUserRegistered(String userId, String eventId) async {
    final regId = await getRegistrationId(userId, eventId);
    return regId != null;
  }

  /// Get details of a specific registration
  Future<Map<String, dynamic>?> getRegistrationDetails(String registrationId) async {
    final doc = await _firestore
        .collection(ApiEndpoints.registrations)
        .doc(registrationId)
        .get();
    
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Mark a registration as attended
  Future<void> markAttendance(String registrationId) async {
    await _firestore
        .collection(ApiEndpoints.registrations)
        .doc(registrationId)
        .update({'attended': true});
  }
}
