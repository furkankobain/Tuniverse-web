import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_bypass_auth_service.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Upload playlist cover image
  static Future<String?> uploadPlaylistCover(File imageFile, String playlistId) async {
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return null;

      // Create reference
      final ref = _storage.ref().child('playlists/$userId/$playlistId/cover.jpg');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'playlistId': playlistId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading playlist cover: $e');
      return null;
    }
  }

  /// Upload message image
  static Future<String?> uploadMessageImage({
    required String imagePath,
    required String conversationId,
  }) async {
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return null;

      final imageFile = File(imagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create reference
      final ref = _storage.ref().child(
        'messages/$conversationId/$userId/$timestamp.jpg',
      );

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'conversationId': conversationId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading message image: $e');
      return null;
    }
  }

  /// Upload user profile picture
  static Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      // Create reference
      final ref = _storage.ref().child('users/$userId/profile.jpg');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Upload profile image from path
  static Future<String?> uploadProfileImage({
    required String imagePath,
    required String userId,
  }) async {
    try {
      final imageFile = File(imagePath);
      return await uploadProfilePicture(imageFile, userId);
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Delete playlist cover image
  static Future<bool> deletePlaylistCover(String playlistId) async {
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return false;

      final ref = _storage.ref().child('playlists/$userId/$playlistId/cover.jpg');
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting playlist cover: $e');
      return false;
    }
  }

  /// Delete user profile picture
  static Future<bool> deleteProfilePicture(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

  /// Get upload progress stream
  static Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  /// Show image picker options (Gallery or Camera)
  static Future<XFile?> showImagePickerOptions() async {
    // This will be implemented in the UI layer with a modal
    return null;
  }
}
