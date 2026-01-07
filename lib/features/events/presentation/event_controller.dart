import 'package:flutter/material.dart';
import '../data/event_model.dart';

class EventController extends ChangeNotifier {
  Future<void> createEvent(EventModel event) async {
    // TEMP: just simulate creation
    await Future.delayed(const Duration(seconds: 1));
  }
}
