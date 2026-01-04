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

  /// Filter events dynamically
  Stream<List<EventModel>> filterEvents({
    String? category,
    String? locationType,
    bool? isPaid,
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

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromDoc(doc))
              .toList(),
        );
  }
}
