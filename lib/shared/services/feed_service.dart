import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_item.dart';
import 'firebase_bypass_auth_service.dart';

/// Service for fetching and managing activity feed
/// Gets activities from followed users and global feed
class FeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get feed for current user (activities from followed users)
  static Future<List<ActivityItem>> getFollowingFeed({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return [];

      // Get list of users that current user follows
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .get();

      if (followingSnapshot.docs.isEmpty) {
        return [];
      }

      final followingUserIds = followingSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

      // Add current user to see own activities
      followingUserIds.add(currentUserId);

      // Fetch activities from followed users
      Query query = _firestore
          .collection('activities')
          .where('userId', whereIn: followingUserIds)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final activitiesSnapshot = await query.get();

      return activitiesSnapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching following feed: $e');
      return [];
    }
  }

  /// Get global feed (all public activities)
  static Future<List<ActivityItem>> getGlobalFeed({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('activities')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final activitiesSnapshot = await query.get();

      return activitiesSnapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching global feed: $e');
      return [];
    }
  }

  /// Get popular feed (activities sorted by engagement)
  static Future<List<ActivityItem>> getPopularFeed({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Get activities from last 7 days sorted by likes + comments
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      Query query = _firestore
          .collection('activities')
          .where('isPublic', isEqualTo: true)
          .where('createdAt', isGreaterThan: oneWeekAgo)
          .orderBy('createdAt', descending: true)
          .orderBy('likesCount', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final activitiesSnapshot = await query.get();

      return activitiesSnapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching popular feed: $e');
      // Fallback to global feed if composite index not ready
      return getGlobalFeed(limit: limit, lastDocument: lastDocument);
    }
  }

  /// Get user's own activities
  static Future<List<ActivityItem>> getUserActivities({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final activitiesSnapshot = await query.get();

      return activitiesSnapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user activities: $e');
      return [];
    }
  }

  /// Create a new activity (for reviews, playlist creation, etc.)
  static Future<bool> createActivity({
    required String type, // 'review', 'playlist', 'favorite', etc.
    required String contentId,
    required Map<String, dynamic> contentData,
    String? reviewText,
    double? rating,
    bool isPublic = true,
  }) async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return false;

      // Get user info
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();

      await _firestore.collection('activities').add({
        'userId': currentUserId,
        'username': userData?['username'] ?? 'User',
        'userPhotoUrl': userData?['photoUrl'],
        'type': type,
        'contentId': contentId,
        'contentData': contentData,
        'reviewText': reviewText,
        'rating': rating,
        'isPublic': isPublic,
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error creating activity: $e');
      return false;
    }
  }

  /// Like an activity
  static Future<bool> likeActivity(String activityId) async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return false;

      final activityRef = _firestore.collection('activities').doc(activityId);
      final likeRef = activityRef.collection('likes').doc(currentUserId);

      // Check if already liked
      final likeDoc = await likeRef.get();
      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await activityRef.update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'userId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await activityRef.update({
          'likesCount': FieldValue.increment(1),
        });
      }

      return true;
    } catch (e) {
      print('Error liking activity: $e');
      return false;
    }
  }

  /// Check if current user liked an activity
  static Future<bool> hasLiked(String activityId) async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return false;

      final likeDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .collection('likes')
          .doc(currentUserId)
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
    required String commentText,
  }) async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return false;

      // Get user info
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();

      final activityRef = _firestore.collection('activities').doc(activityId);

      await activityRef.collection('comments').add({
        'userId': currentUserId,
        'username': userData?['username'] ?? 'User',
        'userPhotoUrl': userData?['photoUrl'],
        'text': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await activityRef.update({
        'commentsCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  /// Get comments for an activity
  static Stream<QuerySnapshot> getComments(String activityId) {
    return _firestore
        .collection('activities')
        .doc(activityId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Delete activity
  static Future<bool> deleteActivity(String activityId) async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return false;

      final activityDoc = await _firestore.collection('activities').doc(activityId).get();
      
      // Check if user owns this activity
      if (activityDoc.data()?['userId'] != currentUserId) {
        return false;
      }

      await _firestore.collection('activities').doc(activityId).delete();
      return true;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }
}
