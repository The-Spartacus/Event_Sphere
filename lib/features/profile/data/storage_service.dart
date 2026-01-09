import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Service for handling Firebase Storage operations
/// Used for uploading profile photos and organization logos
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload profile photo for a user
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
    String? existingPhotoUrl, // If updating, delete old photo
  }) async {
    try {
      // Delete existing photo if updating
      if (existingPhotoUrl != null && existingPhotoUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingPhotoUrl).delete();
        } catch (e) {
          // Ignore errors when deleting old photo (might not exist)
          print('Error deleting old photo: $e');
        }
      }

      // Create unique filename
      final fileName = 'profile_${_uuid.v4()}.jpg';
      final ref = _storage
          .ref()
          .child('profiles')
          .child(userId)
          .child('photo')
          .child(fileName);

      // Upload file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Upload organization logo
  /// Returns the download URL of the uploaded image
  Future<String> uploadOrganizationLogo({
    required String userId,
    required File imageFile,
    String? existingLogoUrl, // If updating, delete old logo
  }) async {
    try {
      // Delete existing logo if updating
      if (existingLogoUrl != null && existingLogoUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingLogoUrl).delete();
        } catch (e) {
          // Ignore errors when deleting old logo (might not exist)
          print('Error deleting old logo: $e');
        }
      }

      // Create unique filename
      final fileName = 'logo_${_uuid.v4()}.jpg';
      final ref = _storage
          .ref()
          .child('profiles')
          .child(userId)
          .child('logo')
          .child(fileName);

      // Upload file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload organization logo: $e');
    }
  }

  /// Delete a file from storage by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}

