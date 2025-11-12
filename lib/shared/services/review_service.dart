import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/music_review.dart';
import '../models/review_reply.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _reviewsCollection = 'music_reviews';
  static const String _repliesCollection = 'review_replies';

  /// Toggle like on a review
  static Future<void> toggleLike(String reviewId, String userId) async {
    try {
      final reviewRef = _firestore.collection(_reviewsCollection).doc(reviewId);
      final reviewDoc = await reviewRef.get();
      
      if (!reviewDoc.exists) return;
      
      final review = MusicReview.fromFirestore(reviewDoc);
      final likedBy = List<String>.from(review.likedBy);
      final dislikedBy = List<String>.from(review.dislikedBy);
      
      // If already liked, remove like
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        // Add like and remove dislike if exists
        likedBy.add(userId);
        dislikedBy.remove(userId);
      }
      
      await reviewRef.update({
        'likedBy': likedBy,
        'dislikedBy': dislikedBy,
        'likeCount': likedBy.length,
        'dislikeCount': dislikedBy.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Toggle dislike on a review
  static Future<void> toggleDislike(String reviewId, String userId) async {
    try {
      final reviewRef = _firestore.collection(_reviewsCollection).doc(reviewId);
      final reviewDoc = await reviewRef.get();
      
      if (!reviewDoc.exists) return;
      
      final review = MusicReview.fromFirestore(reviewDoc);
      final likedBy = List<String>.from(review.likedBy);
      final dislikedBy = List<String>.from(review.dislikedBy);
      
      // If already disliked, remove dislike
      if (dislikedBy.contains(userId)) {
        dislikedBy.remove(userId);
      } else {
        // Add dislike and remove like if exists
        dislikedBy.add(userId);
        likedBy.remove(userId);
      }
      
      await reviewRef.update({
        'likedBy': likedBy,
        'dislikedBy': dislikedBy,
        'likeCount': likedBy.length,
        'dislikeCount': dislikedBy.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling dislike: $e');
      rethrow;
    }
  }

  /// Add a reply to a review
  static Future<String> addReply({
    required String reviewId,
    required String userId,
    required String username,
    String? userAvatar,
    required String replyText,
    String? replyToUserId,
    String? replyToUsername,
  }) async {
    try {
      final reply = ReviewReply(
        id: '',
        reviewId: reviewId,
        userId: userId,
        username: username,
        userAvatar: userAvatar,
        replyText: replyText,
        replyToUserId: replyToUserId,
        replyToUsername: replyToUsername,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final replyRef = await _firestore
          .collection(_repliesCollection)
          .add(reply.toFirestore());

      // Increment reply count on review
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'replyCount': FieldValue.increment(1),
      });

      return replyRef.id;
    } catch (e) {
      print('Error adding reply: $e');
      rethrow;
    }
  }

  /// Get replies for a review
  static Future<List<ReviewReply>> getReplies(String reviewId) async {
    try {
      final snapshot = await _firestore
          .collection(_repliesCollection)
          .where('reviewId', isEqualTo: reviewId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ReviewReply.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting replies: $e');
      return [];
    }
  }

  /// Stream replies for a review (real-time)
  static Stream<List<ReviewReply>> streamReplies(String reviewId) {
    return _firestore
        .collection(_repliesCollection)
        .where('reviewId', isEqualTo: reviewId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewReply.fromFirestore(doc))
            .toList());
  }

  /// Toggle like on a reply
  static Future<void> toggleReplyLike(String replyId, String userId) async {
    try {
      final replyRef = _firestore.collection(_repliesCollection).doc(replyId);
      final replyDoc = await replyRef.get();
      
      if (!replyDoc.exists) return;
      
      final reply = ReviewReply.fromFirestore(replyDoc);
      final likedBy = List<String>.from(reply.likedBy);
      
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      
      await replyRef.update({
        'likedBy': likedBy,
        'likeCount': likedBy.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling reply like: $e');
      rethrow;
    }
  }

  /// Delete a reply
  static Future<void> deleteReply(String reviewId, String replyId) async {
    try {
      await _firestore.collection(_repliesCollection).doc(replyId).delete();

      // Decrement reply count on review
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'replyCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error deleting reply: $e');
      rethrow;
    }
  }

  /// Edit a reply
  static Future<void> editReply(String replyId, String newText) async {
    try {
      await _firestore.collection(_repliesCollection).doc(replyId).update({
        'replyText': newText,
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error editing reply: $e');
      rethrow;
    }
  }

  /// Create a new review
  static Future<String> createReview({
    required String userId,
    required String username,
    String? userAvatar,
    required String trackId,
    required String trackName,
    required String artists,
    String? albumImage,
    int? rating,
    required String reviewText,
    bool containsSpoiler = false,
    List<String> tags = const [],
  }) async {
    try {
      final review = MusicReview(
        id: '',
        userId: userId,
        username: username,
        userAvatar: userAvatar,
        trackId: trackId,
        trackName: trackName,
        artists: artists,
        albumImage: albumImage,
        rating: rating,
        reviewText: reviewText,
        containsSpoiler: containsSpoiler,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final reviewRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toFirestore());

      return reviewRef.id;
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  /// Get reviews for a track
  static Future<List<MusicReview>> getTrackReviews(String trackId) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('trackId', isEqualTo: trackId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MusicReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting track reviews: $e');
      return [];
    }
  }

  /// Stream reviews (real-time feed)
  static Stream<List<MusicReview>> streamReviews({
    int limit = 20,
    String? userId,
  }) {
    Query query = _firestore
        .collection(_reviewsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => MusicReview.fromFirestore(doc))
        .toList());
  }

  /// Delete a review
  static Future<void> deleteReview(String reviewId) async {
    try {
      // Delete the review
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();

      // Delete all replies
      final replies = await _firestore
          .collection(_repliesCollection)
          .where('reviewId', isEqualTo: reviewId)
          .get();

      final batch = _firestore.batch();
      for (var doc in replies.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  /// Edit a review
  static Future<void> editReview(String reviewId, String newText) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'reviewText': newText,
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error editing review: $e');
      rethrow;
    }
  }
}
