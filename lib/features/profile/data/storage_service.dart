import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Service for handling Cloudinary Storage operations
/// Used for uploading profile photos and organization logos
class StorageService {
  // TODO: Replace with your actual Cloudinary credentials
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dcagxzjpu', 
    'event_sphere', 
    cache: false,
  );

  StorageService() {
    print('StorageService initialized. Cloud: dcagxzjpu, Preset: event_sphere');
  }

  /// Upload profile photo for a user
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
    String? existingPhotoUrl, // Cloudinary doesn't easily support delete by URL without public_id, so we mostly ignore this for now for unsigned
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path, 
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo to Cloudinary: $e');
    }
  }

  /// Upload organization logo
  /// Returns the download URL of the uploaded image
  Future<String> uploadOrganizationLogo({
    required String userId,
    required File imageFile,
    String? existingLogoUrl,
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload organization logo to Cloudinary: $e');
    }
  }

  /// Upload event poster
  /// Returns the download URL of the uploaded image
  Future<String> uploadEventPoster({
    required String eventId,
    required File imageFile,
    String? existingPosterUrl,
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
           imageFile.path,
           resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Cloudinary Error: ${e.message}');
      print('Cloudinary Response: ${e.responseString}');
      throw Exception('Cloudinary Upload Failed: ${e.message} - ${e.responseString}');
    } catch (e) {
      print('Unknown Error: $e');
      try {
        // Attempt to inspect DioException response if present
        if ((e as dynamic).response != null) {
          print('Cloudinary/Dio Response Data: ${(e as dynamic).response.data}');
        }
      } catch (_) {}
      throw Exception('Failed to upload: $e');
    }
  }

  /// Delete a file from storage by URL
  /// Note: Unsigned deletion is generally not supported for security reasons in client-side Cloudinary.
  /// This is a stub to match the previous interface.
  Future<void> deleteFile(String fileUrl) async {
    // Cloudinary client-side libraries typically don't allow delete for unsigned uploads
    // We would need a backend signature to do this securey.
    // For now, we will just log it.
    print('StorageService.deleteFile: Deletion is not supported with unsigned Cloudinary presets. File URL: $fileUrl');
  }
}
