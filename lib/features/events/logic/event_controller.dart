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
  // Filters
  String? _category;
  String? _locationType;
  bool? _isPaid;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _organizationName;

  StreamSubscription<List<EventModel>>? _subscription;

  // Getters
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filter Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get organizationName => _organizationName;

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
    DateTime? startDate,
    DateTime? endDate,
    String? organizationName,
  }) {
    _category = category ?? _category;
    _locationType = locationType ?? _locationType;
    // We treat explicit null as "clear filter" for bool, but here we might need tri-state
    // If exposed via UI, usually we pass the new value or null to keep existing.
    // For simplicity, let's assume we replace if provided, or keep if null.
    // However, the original code looked like it replaced everything. 
    // Let's stick to the pattern: update state, then query.
    
    if (category != null) _category = category;
    if (locationType != null) _locationType = locationType;
    if (isPaid != null) _isPaid = isPaid;
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    if (organizationName != null) _organizationName = organizationName;

    _runFilterQuery();
  }

  /// Helper: Filter Today
  void filterToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _applyDateRange(start, end);
  }

  /// Helper: Filter Tomorrow
  void filterTomorrow() {
    final now = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _applyDateRange(start, end);
  }

  /// Helper: Filter This Week
  void filterThisWeek() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now.add(const Duration(days: 7));
    _applyDateRange(start, end);
  }

  void _applyDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _runFilterQuery();
  }

  /// Helper: Search by College
  void searchByCollege(String query) {
    _organizationName = query;
    _runFilterQuery();
  }

  void _runFilterQuery() {
    _setLoading(true);
    _subscription?.cancel();

    _subscription = _repository
        .filterEvents(
          category: _category,
          locationType: _locationType,
          isPaid: _isPaid,
          startDate: _startDate,
          endDate: _endDate,
          organizationNameQuery: _organizationName,
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
    _startDate = null;
    _endDate = null;
    _organizationName = null;
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
  