import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import 'user_profile_model.dart';

/// Repository for profile data operations
/// Handles all Firestore operations related to user profiles
class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user profile by user ID
  Future<UserProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(ApiEndpoints.users)
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return UserProfileModel.fromDoc(doc);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Stream user profile (for real-time updates)
  Stream<UserProfileModel?> streamProfile(String userId) {
    return _firestore
        .collection(ApiEndpoints.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromDoc(doc);
    });
  }

  /// Update user profile
  /// Only updates allowed fields (excludes email, role, uid, createdAt, verified)
  Future<void> updateProfile(UserProfileModel profile) async {
    try {
      // Get update map (excludes immutable fields)
      final updateData = profile.toUpdateMap();

      await _firestore
          .collection(ApiEndpoints.users)
          .doc(profile.uid)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(ApiEndpoints.users)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}

