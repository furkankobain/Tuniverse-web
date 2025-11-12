import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_item.dart';
import 'firebase_bypass_auth_service.dart';

enum ActivityType {
  listened,
  rated,
  reviewed,
  addedToPlaylist,
  followedUser,
  createdPlaylist,
  sharedTrack,
}

class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

  /// Create a new activity
  static Future<bool> createActivity({
    required ActivityType type,
    String? trackId,
    String? trackName,
    String? artistName,
    String? albumId,
    String? albumName,
    String? albumImage,
    String? playlistId,
    String? playlistName,
    String? targetUserId,
    double? rating,
    String? reviewText,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) return false;

      final activity = {
        'userId': currentUser.userId,
        'username': currentUser.username,
        'displayName': currentUser.displayName,
        'userPhotoUrl': null, // Can be added later
        'type': type.name,
        'trackId': trackId,
        'trackName': trackName,
        'artistName': artistName,
        'albumId': albumId,
        'albumName': albumName,
        'albumImage': albumImage,
        'playlistId': playlistId,
        'playlistName': playlistName,
        'targetUserId': targetUserId,
        'rating': rating,
        'reviewText': reviewText,
        'metadata': metadata,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collection).add(activity);
      return true;
    } catch (e) {
      print('Error creating activity: $e');
      return false;
    }
  }

  /// Get activities for a specific user
  static Stream<List<ActivityItem>> getUserActivities(String userId, {int limit = 50}) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityItem.fromFirestore(doc);
      }).toList();
    });
  }

  /// Get feed activities (all public activities)
  static Stream<List<ActivityItem>> getFeedActivities({int limit = 50}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityItem.fromFirestore(doc);
      }).toList();
    });
  }

  /// Get activities from followed users
  static Stream<List<ActivityItem>> getFollowingActivities(
    List<String> followingUserIds, {
    int limit = 50,
  }) {
    if (followingUserIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', whereIn: followingUserIds.take(10).toList()) // Firestore limit
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityItem.fromFirestore(doc);
      }).toList();
    });
  }

  /// Get popular activities (sorted by engagement)
  static Future<List<ActivityItem>> getPopularActivities({
    int limit = 50,
    Duration timeWindow = const Duration(days: 7),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(timeWindow);
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to filter and sort
          .get();

      final activities = snapshot.docs.map((doc) {
        return ActivityItem.fromFirestore(doc);
      }).toList();

      // Sort by engagement score (likes + comments)
      activities.sort((a, b) {
        final scoreA = a.likeCount + (a.commentCount * 2); // Comments worth more
        final scoreB = b.likeCount + (b.commentCount * 2);
        return scoreB.compareTo(scoreA);
      });

      return activities.take(limit).toList();
    } catch (e) {
      print('Error getting popular activities: $e');
      return [];
    }
  }

  /// Like an activity
  static Future<bool> likeActivity(String activityId, String userId) async {
    try {
      final activityRef = _firestore.collection(_collection).doc(activityId);
      final likesRef = activityRef.collection('likes').doc(userId);

      // Check if already liked
      final likeDoc = await likesRef.get();
      if (likeDoc.exists) {
        // Unlike
        await likesRef.delete();
        await activityRef.update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likesRef.set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await activityRef.update({
          'likeCount': FieldValue.increment(1),
        });
      }

      return true;
    } catch (e) {
      print('Error liking activity: $e');
      return false;
    }
  }

  /// Check if user liked an activity
  static Future<bool> hasUserLiked(String activityId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection(_collection)
          .doc(activityId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  /// Add comment to activity
  static Future<bool> addComment({
    required String activityId,
    required String userId,
    required String username,
    required String commentText,
  }) async {
    try {
      final activityRef = _firestore.collection(_collection).doc(activityId);
      final commentsRef = activityRef.collection('comments');

      await commentsRef.add({
        'userId': userId,
        'username': username,
        'commentText': commentText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await activityRef.update({
        'commentCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  /// Get comments for an activity
  static Stream<List<Map<String, dynamic>>> getComments(String activityId) {
    return _firestore
        .collection(_collection)
        .doc(activityId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Delete an activity (only by owner)
  static Future<bool> deleteActivity(String activityId, String userId) async {
    try {
      final activityDoc = await _firestore.collection(_collection).doc(activityId).get();
      
      if (!activityDoc.exists) return false;
      
      final activityData = activityDoc.data();
      if (activityData?['userId'] != userId) return false; // Not owner

      await _firestore.collection(_collection).doc(activityId).delete();
      return true;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }

  /// Get activity count for user
  static Future<int> getUserActivityCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting activity count: $e');
      return 0;
    }
  }

  /// Track listened activity
  static Future<bool> trackListen({
    required String trackId,
    required String trackName,
    required String artistName,
    String? albumId,
    String? albumName,
    String? albumImage,
  }) async {
    return await createActivity(
      type: ActivityType.listened,
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      albumId: albumId,
      albumName: albumName,
      albumImage: albumImage,
    );
  }

  /// Track rated activity
  static Future<bool> trackRating({
    required String trackId,
    required String trackName,
    required String artistName,
    required double rating,
    String? albumId,
    String? albumName,
    String? albumImage,
  }) async {
    return await createActivity(
      type: ActivityType.rated,
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      albumId: albumId,
      albumName: albumName,
      albumImage: albumImage,
      rating: rating,
    );
  }

  /// Track review activity
  static Future<bool> trackReview({
    required String trackId,
    required String trackName,
    required String artistName,
    required double rating,
    required String reviewText,
    String? albumId,
    String? albumName,
    String? albumImage,
  }) async {
    return await createActivity(
      type: ActivityType.reviewed,
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      albumId: albumId,
      albumName: albumName,
      albumImage: albumImage,
      rating: rating,
      reviewText: reviewText,
    );
  }
}
