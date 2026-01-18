import 'package:flutter/material.dart';
import '../../events/data/event_model.dart';
import '../../events/data/event_repository.dart';

class MyEventsController extends ChangeNotifier {
  final EventRepository _repository;
  final String _userId;
  final List<String> _bookmarkedIds;

  MyEventsController({
    required EventRepository repository,
    required String userId,
    required List<String> bookmarkedIds,
  })  : _repository = repository,
        _userId = userId,
        _bookmarkedIds = bookmarkedIds;

  List<EventModel> _registeredEvents = [];
  List<EventModel> _pastEvents = [];
  List<EventModel> _interestedEvents = [];
  bool _isLoading = false;
  String? _error;

  List<EventModel> get registeredEvents => _registeredEvents;
  List<EventModel> get pastEvents => _pastEvents;
  List<EventModel> get interestedEvents => _interestedEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch Registered Events
      final registeredIds = await _repository.getRegisteredEventIds(_userId);
      final allRegistered = await _repository.getEventsByIds(registeredIds);

      // 2. Fetch Interested Events
      // Ensure we don't fetch duplicates if bookmarked matches registered (optional, but UI separates them)
      // Usually "Interested" implies bookmarks.
      final interested = await _repository.getEventsByIds(_bookmarkedIds);
      
      // 3. Process Registered into Upcoming vs Past
      final now = DateTime.now();
      _registeredEvents = [];
      _pastEvents = [];

      for (var event in allRegistered) {
        // Assume event.date is DateTime (converted from Timestamp in model)
        if (event.date.isBefore(now)) {
          _pastEvents.add(event);
        } else {
          _registeredEvents.add(event);
        }
      }

      // Sort by date
      _registeredEvents.sort((a, b) => a.date.compareTo(b.date));
      _pastEvents.sort((a, b) => b.date.compareTo(a.date)); // Descending for past
      
      _interestedEvents = interested;
      _interestedEvents.sort((a, b) => a.date.compareTo(b.date));

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
