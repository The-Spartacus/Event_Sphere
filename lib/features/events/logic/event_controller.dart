import 'dart:async';
import 'package:flutter/material.dart';

import '../data/event_model.dart';
import '../data/event_repository.dart';

class EventController extends ChangeNotifier {
  final EventRepository _repository;

  EventController(this._repository);

  // State
  List<EventModel> _filteredEvents = []; // Exposed to UI
  List<EventModel> _allStreamedEvents = []; // Raw data from DB
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Filters
  String? _category;
  String? _locationType;
  bool? _isPaid;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _organizationName;

  StreamSubscription<List<EventModel>>? _subscription;

  // Getters
  List<EventModel> get events => _filteredEvents;
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
        _allStreamedEvents = data;
        _refilter(); // Apply local search/filters
        _error = null;
        _setLoading(false);
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
      },
    );
  }

  /// Search events interactively
  void searchEvents(String query) {
    _searchQuery = query;
    _refilter();
  }

  // Admin / Ads
  List<EventModel> _pendingAdEvents = [];
  List<EventModel> get pendingAdEvents => _pendingAdEvents;
  StreamSubscription<List<EventModel>>? _adSubscription;

  /// Load pending ad events (for admin)
  void loadPendingAdEvents() {
    _setLoading(true);
    _adSubscription?.cancel();
    _adSubscription = _repository.streamPendingAdEvents().listen(
      (data) {
        _pendingAdEvents = data;
        _setLoading(false); // Notify listeners
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
      },
    );
  }

  Future<void> approveAd(EventModel event) async {
    try {
      final updated = event.copyWith(promotionStatus: 'approved');
      await _repository.updateEvent(updated);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectAd(EventModel event) async {
    try {
      final updated = event.copyWith(promotionStatus: 'rejected');
      await _repository.updateEvent(updated);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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
            _allStreamedEvents = data;
            _refilter(); 
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
    _searchQuery = '';
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

  /// Update existing event
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

  void _refilter() {
    if (_searchQuery.isEmpty) {
      _filteredEvents = List.from(_allStreamedEvents);
    } else {
      final queryLower = _searchQuery.toLowerCase();
      _filteredEvents = _allStreamedEvents.where((event) {
        final title = event.title.toLowerCase();
        final org = event.organizationName.toLowerCase();
        final loc = (event.location ?? '').toLowerCase();
        final desc = (event.description ?? '').toLowerCase();
        return title.contains(queryLower) ||
               org.contains(queryLower) ||
               loc.contains(queryLower) ||
               desc.contains(queryLower);
      }).toList();
    }

    // Sort: Promoted events first, then by date logic
    // Actually, streamApprovedEvents orders by date.
    // We want promoted events at the TOP.
    _filteredEvents.sort((a, b) {
      final aPromoted = a.promotionStatus == 'approved';
      final bPromoted = b.promotionStatus == 'approved';

      if (aPromoted && !bPromoted) return -1;
      if (!aPromoted && bPromoted) return 1;
      
      // Keep original date order (assuming they were sorted by date)
      // Since sort is stable or we can rely on index if needed, but here simple comparison is enough.
      return a.date.compareTo(b.date);
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _adSubscription?.cancel();
    super.dispose();
  }
}
  