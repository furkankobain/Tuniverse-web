import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Service for managing follow/follower relationships
/// Instagram/TikTok style follow system with requests
class FollowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Follow a user (if public) or send follow request (if private)
  static Future<bool> followUser(String targetUserId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Check if target user's account is private
      final targetUserDoc = await _firestore.collection('users').doc(targetUserId).get();
      final isPrivate = targetUserDoc.data()?['isPrivate'] ?? false;

      if (isPrivate) {
        // Send follow request
        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('follow_requests')
            .doc(currentUserId)
            .set({
          'requesterId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        // Add to current user's sent requests
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('sent_requests')
            .doc(targetUserId)
            .set({
          'targetUserId': targetUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        return true;
      } else {
        // Public account - follow immediately
        await _acceptFollow(currentUserId, targetUserId);
        return true;
      }
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Remove from following list
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .delete();

      // Remove from target's followers list
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      // Update counts
      await _updateFollowCounts(currentUserId, targetUserId, isFollow: false);

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Accept a follow request
  static Future<bool> acceptFollowRequest(String requesterId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _acceptFollow(requesterId, currentUserId);

      // Remove from requests
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('follow_requests')
          .doc(requesterId)
          .delete();

      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('sent_requests')
          .doc(currentUserId)
          .delete();

      return true;
    } catch (e) {
      print('Error accepting follow request: $e');
      return false;
    }
  }

  /// Reject a follow request
  static Future<bool> rejectFollowRequest(String requesterId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Remove from requests
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('follow_requests')
          .doc(requesterId)
          .delete();

      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('sent_requests')
          .doc(currentUserId)
          .delete();

      return true;
    } catch (e) {
      print('Error rejecting follow request: $e');
      return false;
    }
  }

  /// Cancel a sent follow request
  static Future<bool> cancelFollowRequest(String targetUserId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Remove from target's requests
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('follow_requests')
          .doc(currentUserId)
          .delete();

      // Remove from current user's sent requests
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sent_requests')
          .doc(targetUserId)
          .delete();

      return true;
    } catch (e) {
      print('Error canceling follow request: $e');
      return false;
    }
  }

  /// Helper: Accept a follow (create follow relationship)
  static Future<void> _acceptFollow(String followerId, String followingId) async {
    // Add to follower's following list
    await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .set({
      'userId': followingId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add to following's followers list
    await _firestore
        .collection('users')
        .doc(followingId)
        .collection('followers')
        .doc(followerId)
        .set({
      'userId': followerId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update counts
    await _updateFollowCounts(followerId, followingId, isFollow: true);
  }

  /// Update follower/following counts
  static Future<void> _updateFollowCounts(
    String followerId,
    String followingId, {
    required bool isFollow,
  }) async {
    final increment = isFollow ? 1 : -1;

    // Update follower's following count
    await _firestore.collection('users').doc(followerId).update({
      'followingCount': FieldValue.increment(increment),
    });

    // Update following's followers count
    await _firestore.collection('users').doc(followingId).update({
      'followersCount': FieldValue.increment(increment),
    });
  }

  /// Check if current user is following a user
  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if following: $e');
      return false;
    }
  }

  /// Check if a follow request is pending
  static Future<bool> hasRequestPending(String targetUserId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sent_requests')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking request status: $e');
      return false;
    }
  }

  /// Get follow requests stream
  static Stream<List<Map<String, dynamic>>> getFollowRequests() {
    final currentUserId = FirebaseService.auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('follow_requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final requests = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final requesterId = doc.data()['requesterId'];
        
        // Fetch requester details
        final requesterDoc = await _firestore
            .collection('users')
            .doc(requesterId)
            .get();

        if (requesterDoc.exists) {
          requests.add({
            'requesterId': requesterId,
            'username': requesterDoc.data()?['username'] ?? 'Unknown',
            'avatarUrl': requesterDoc.data()?['avatarUrl'],
            'timestamp': doc.data()['timestamp'],
          });
        }
      }

      return requests;
    });
  }

  /// Get followers list
  static Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  /// Get following list
  static Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  /// Get follower count
  static Future<int> getFollowerCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['followersCount'] ?? 0;
    } catch (e) {
      print('Error getting follower count: $e');
      return 0;
    }
  }

  /// Get following count
  static Future<int> getFollowingCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['followingCount'] ?? 0;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  /// Check if two users follow each other (mutual follow)
  static Future<bool> areMutualFollowers(String userId1, String userId2) async {
    try {
      final doc1 = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('following')
          .doc(userId2)
          .get();

      final doc2 = await _firestore
          .collection('users')
          .doc(userId2)
          .collection('following')
          .doc(userId1)
          .get();

      return doc1.exists && doc2.exists;
    } catch (e) {
      print('Error checking mutual follow: $e');
      return false;
    }
  }

  /// Get mutual followers (users who both follow each other)
  static Future<List<String>> getMutualFollowers(String userId) async {
    try {
      final followers = await getFollowers(userId);
      final following = await getFollowing(userId);

      // Find intersection
      return followers.where((id) => following.contains(id)).toList();
    } catch (e) {
      print('Error getting mutual followers: $e');
      return [];
    }
  }

  /// Toggle account privacy
  static Future<bool> toggleAccountPrivacy() async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final isPrivate = userDoc.data()?['isPrivate'] ?? false;

      await _firestore.collection('users').doc(currentUserId).update({
        'isPrivate': !isPrivate,
      });

      return true;
    } catch (e) {
      print('Error toggling account privacy: $e');
      return false;
    }
  }

  /// Remove a follower
  static Future<bool> removeFollower(String followerId) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Remove from current user's followers
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .doc(followerId)
          .delete();

      // Remove from follower's following
      await _firestore
          .collection('users')
          .doc(followerId)
          .collection('following')
          .doc(currentUserId)
          .delete();

      // Update counts
      await _updateFollowCounts(followerId, currentUserId, isFollow: false);

      return true;
    } catch (e) {
      print('Error removing follower: $e');
      return false;
    }
  }
}
