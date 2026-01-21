import 'dart:io';
import 'package:flutter/material.dart';

import '../data/user_profile_model.dart';
import '../data/profile_repository.dart';
import '../data/storage_service.dart';

/// Controller for managing profile state
/// Handles profile loading, updating, and image uploads
class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;
  final StorageService _storageService;

  ProfileController({
    required ProfileRepository repository,
    required StorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  // State
  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _error;
  bool _hasChanges = false;

  // Getters
  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasChanges => _hasChanges;

  /// Load profile for a user
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      _profile = await _repository.getProfile(userId);
      if (_profile == null) {
        _error = 'Profile not found';
      }
      _hasChanges = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Stream profile (for real-time updates)
  Stream<UserProfileModel?> streamProfile(String userId) {
    return _repository.streamProfile(userId).map((profile) {
      _profile = profile;
      _hasChanges = false;
      notifyListeners();
      return profile;
    });
  }

  /// Update profile field
  void updateField({
    String? name,
    String? collegeName,
    String? phoneNumber,
    String? department,
    String? yearOfStudy,
    String? organizationName,
    String? officialWebsite,
    String? organizationDescription,
    String? address,
    String? contactPersonName,
    String? contactPersonPhone,
  }) {
    if (_profile == null) return;

    _profile = _profile!.copyWith(
      name: name,
      collegeName: collegeName,
      phoneNumber: phoneNumber,
      department: department,
      yearOfStudy: yearOfStudy,
      organizationName: organizationName,
      officialWebsite: officialWebsite,
      organizationDescription: organizationDescription,
      address: address,
      contactPersonName: contactPersonName,
      contactPersonPhone: contactPersonPhone,
    );

    _hasChanges = true;
    notifyListeners();
  }

  /// Update profile photo URL (called after upload)
  void updateProfilePhotoUrl(String photoUrl) {
    if (_profile == null) return;

    _profile = _profile!.copyWith(profilePhotoUrl: photoUrl);
    _hasChanges = true;
    notifyListeners();
  }

  /// Update organization logo URL (called after upload)
  void updateLogoUrl(String logoUrl) {
    if (_profile == null) return;

    _profile = _profile!.copyWith(logoUrl: logoUrl);
    _hasChanges = true;
    notifyListeners();
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto(File imageFile) async {
    if (_profile == null) {
      throw Exception('Profile not loaded');
    }

    try {
      final photoUrl = await _storageService.uploadProfilePhoto(
        userId: _profile!.uid,
        imageFile: imageFile,
        existingPhotoUrl: _profile!.profilePhotoUrl,
      );

      updateProfilePhotoUrl(photoUrl);
      return photoUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Upload organization logo
  Future<String> uploadOrganizationLogo(File imageFile) async {
    if (_profile == null) {
      throw Exception('Profile not loaded');
    }

    try {
      final logoUrl = await _storageService.uploadOrganizationLogo(
        userId: _profile!.uid,
        imageFile: imageFile,
        existingLogoUrl: _profile!.logoUrl,
      );

      updateLogoUrl(logoUrl);
      return logoUrl;
    } catch (e) {
      throw Exception('Failed to upload organization logo: $e');
    }
  }

  /// Toggle subscription to an organization
  void toggleSubscription(String organizationId) {
    if (_profile == null) return;

    final currentSubscriptions = List<String>.from(_profile!.subscribedOrgIds);
    final currentTimestamps = Map<String, DateTime>.from(_profile!.subscriptionTimestamps);

    if (currentSubscriptions.contains(organizationId)) {
      currentSubscriptions.remove(organizationId);
      currentTimestamps.remove(organizationId);
    } else {
      currentSubscriptions.add(organizationId);
      currentTimestamps[organizationId] = DateTime.now();
    }

    _profile = _profile!.copyWith(
      subscribedOrgIds: currentSubscriptions,
      subscriptionTimestamps: currentTimestamps,
    );
    _hasChanges = true;
    notifyListeners();
  }

  /// Toggle bookmark for an event
  void toggleBookmark(String eventId) {
    if (_profile == null) return;

    final currentBookmarks = List<String>.from(_profile!.bookmarkedEventIds);
    if (currentBookmarks.contains(eventId)) {
      currentBookmarks.remove(eventId);
    } else {
      currentBookmarks.add(eventId);
    }

    _profile = _profile!.copyWith(bookmarkedEventIds: currentBookmarks);
    _hasChanges = true;
    
    // Auto-save for interaction events
    saveProfile(); // Assuming we want immediate persistence for UX
    notifyListeners();
  }

  /// Toggle calendar event (added to calendar)
  void toggleCalendarEvent(String eventId) {
    if (_profile == null) return;

    final currentCalendar = List<String>.from(_profile!.calendarEventIds);
    if (currentCalendar.contains(eventId)) {
      currentCalendar.remove(eventId);
    } else {
      currentCalendar.add(eventId);
    }

    _profile = _profile!.copyWith(calendarEventIds: currentCalendar);
    _hasChanges = true;
    
    // Auto-save for interaction events
    saveProfile();
    notifyListeners();
  }

  /// Update user location
  void updateLocation(double lat, double lng) {
    if (_profile == null) return;

    _profile = _profile!.copyWith(
      latitude: lat,
      longitude: lng,
      isLocationSet: true,
    );
    _hasChanges = true;
    
    saveProfile();
    notifyListeners();
  }

  /// Save profile changes to Firestore
  Future<void> saveProfile() async {
    if (_profile == null) {
      _error = 'No profile to save';
      notifyListeners();
      return;
    }

    if (!_hasChanges) {
      return; // No changes to save
    }

    _setLoading(true);
    _error = null;

    try {
      await _repository.updateProfile(_profile!);
      _hasChanges = false;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset changes
  void resetChanges() {
    _hasChanges = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

