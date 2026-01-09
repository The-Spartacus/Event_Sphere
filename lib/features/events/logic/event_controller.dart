import 'dart:async';
import 'package:flutter/material.dart';

import '../data/event_model.dart';
import '../data/event_repository.dart';

class EventController extends ChangeNotifier {
  final EventRepository _repository;

  EventController(this._repository);

  // State
  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _category;
  String? _locationType;
  bool? _isPaid;

  StreamSubscription<List<EventModel>>? _subscription;

  // Getters
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all approved events
  void loadEvents() {
    _setLoading(true);

    _subscription?.cancel();
    _subscription = _repository.streamApprovedEvents().listen(
      (data) {
        _events = data;
        _error = null;
        _setLoading(false);
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
      },
    );
  }

  /// Apply filters
  void applyFilters({
    String? category,
    String? locationType,
    bool? isPaid,
  }) {
    _category = category;
    _locationType = locationType;
    _isPaid = isPaid;

    _setLoading(true);
    _subscription?.cancel();

    _subscription = _repository
        .filterEvents(
          category: _category,
          locationType: _locationType,
          isPaid: _isPaid,
        )
        .listen(
          (data) {
            _events = data;
            _error = null;
            _setLoading(false);
          },
          onError: (e) {
            _error = e.toString();
            _setLoading(false);
          },
        );
  }

  /// Clear filters
  void clearFilters() {
    _category = null;
    _locationType = null;
    _isPaid = null;
    loadEvents();
  }

  /// Create event (organization)
  Future<void> createEvent(EventModel event) async {
    try {
      _setLoading(true);
      await _repository.createEvent(event);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  /// Update existing event (organization, only unapproved events)
  /// Security: Should be validated at repository/Firestore rules level
  Future<void> updateEvent(EventModel event) async {
    try {
      _setLoading(true);
      await _repository.updateEvent(event);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      _setLoading(true);
      await _repository.deleteEvent(eventId);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
  