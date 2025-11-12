import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's profile document reference
  static DocumentReference _getUserProfileDoc() {
    final userId = FirebaseService.auth.currentUser?.uid;
    if (userId == null) {
      return _firestore.collection('users').doc('_unauthenticated_');
    }
    return _firestore.collection('users').doc(userId);
  }

  /// Get pinned tracks (max 4)
  static Future<List<Map<String, dynamic>>> getPinnedTracks() async {
    try {
      final doc = await _getUserProfileDoc().get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final pinnedTracks = data?['pinnedTracks'] as List? ?? [];
        return pinnedTracks.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting pinned tracks: $e');
      return [];
    }
  }

  /// Set pinned tracks (max 4)
  static Future<bool> setPinnedTracks(List<Map<String, dynamic>> tracks) async {
    try {
      if (tracks.length > 4) {
        tracks = tracks.sublist(0, 4);
      }

      await _getUserProfileDoc().set({
        'pinnedTracks': tracks,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error setting pinned tracks: $e');
      return false;
    }
  }

  /// Add track to pinned (if less than 4)
  static Future<bool> addPinnedTrack(Map<String, dynamic> track) async {
    try {
      final currentPinned = await getPinnedTracks();
      
      // Check if already pinned
      final trackId = track['id'] as String;
      if (currentPinned.any((t) => t['id'] == trackId)) {
        return false; // Already pinned
      }

      // Check if at max capacity
      if (currentPinned.length >= 4) {
        return false; // Already has 4 pinned tracks
      }

      currentPinned.add({
        'id': trackId,
        'name': track['name'],
        'artists': track['artists'],
        'album': track['album'],
        'preview_url': track['preview_url'],
        'external_urls': track['external_urls'],
      });

      return await setPinnedTracks(currentPinned);
    } catch (e) {
      print('Error adding pinned track: $e');
      return false;
    }
  }

  /// Remove track from pinned
  static Future<bool> removePinnedTrack(String trackId) async {
    try {
      final currentPinned = await getPinnedTracks();
      currentPinned.removeWhere((t) => t['id'] == trackId);
      return await setPinnedTracks(currentPinned);
    } catch (e) {
      print('Error removing pinned track: $e');
      return false;
    }
  }

  /// Check if track is pinned
  static Future<bool> isTrackPinned(String trackId) async {
    try {
      final pinnedTracks = await getPinnedTracks();
      return pinnedTracks.any((t) => t['id'] == trackId);
    } catch (e) {
      print('Error checking if track is pinned: $e');
      return false;
    }
  }

  /// Add a review/note
  static Future<bool> addReview({
    required String trackId,
    required String trackName,
    required List artists,
    required Map<String, dynamic> album,
    required double rating,
    String? note,
  }) async {
    try {
      final reviewData = {
        'trackId': trackId,
        'trackName': trackName,
        'artists': artists,
        'album': album,
        'rating': rating,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
'userId': FirebaseService.auth.currentUser?.uid,
      };

      await _getUserProfileDoc()
          .collection('reviews')
          .doc(trackId)
          .set(reviewData);

      return true;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  /// Get recent reviews
  static Stream<List<Map<String, dynamic>>> getRecentReviews({int limit = 10}) {
    return _getUserProfileDoc()
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get review for a specific track
  static Future<Map<String, dynamic>?> getReviewForTrack(String trackId) async {
    try {
      final doc = await _getUserProfileDoc()
          .collection('reviews')
          .doc(trackId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        data?['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting review: $e');
      return null;
    }
  }

  /// Update profile stats
  static Future<bool> updateStats({
    int? totalReviews,
    int? totalFavorites,
    int? totalListeningTime,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (totalReviews != null) updates['totalReviews'] = totalReviews;
      if (totalFavorites != null) updates['totalFavorites'] = totalFavorites;
      if (totalListeningTime != null) updates['totalListeningTime'] = totalListeningTime;
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _getUserProfileDoc().set(updates, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      print('Error updating stats: $e');
      return false;
    }
  }

  /// Get profile stats
  static Future<Map<String, int>> getStats() async {
    try {
      final doc = await _getUserProfileDoc().get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'totalReviews': data?['totalReviews'] ?? 0,
          'totalFavorites': data?['totalFavorites'] ?? 0,
          'totalListeningTime': data?['totalListeningTime'] ?? 0,
          'followers': data?['followers'] ?? 0,
          'following': data?['following'] ?? 0,
        };
      }
      return {
        'totalReviews': 0,
        'totalFavorites': 0,
        'totalListeningTime': 0,
        'followers': 0,
        'following': 0,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {
        'totalReviews': 0,
        'totalFavorites': 0,
        'totalListeningTime': 0,
        'followers': 0,
        'following': 0,
      };
    }
  }

  /// Update bio
  static Future<bool> updateBio(String bio) async {
    try {
      await _getUserProfileDoc().set({
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error updating bio: $e');
      return false;
    }
  }

  /// Get bio
  static Future<String?> getBio() async {
    try {
      final doc = await _getUserProfileDoc().get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['bio'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting bio: $e');
      return null;
    }
  }
}
