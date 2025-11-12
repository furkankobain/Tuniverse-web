import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/music_review.dart';
import 'firebase_service.dart';

class FirestoreReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'reviews';
  static const String _ratingsCollection = 'ratings';

  // ==================== REVIEWS ====================

  /// Create a new review
  static Future<String?> createReview(MusicReview review) async {
    try {
      final docRef = await _firestore.collection(_reviewsCollection).add({
        ...review.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also create/update rating
      await _saveRating(
        userId: review.userId,
        trackId: review.trackId,
        rating: review.rating,
      );

      return docRef.id;
    } catch (e) {
      print('Error creating review: $e');
      return null;
    }
  }

  /// Update an existing review
  static Future<bool> updateReview(String reviewId, MusicReview review) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'reviewText': review.reviewText,
        'rating': review.rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update rating
      await _saveRating(
        userId: review.userId,
        trackId: review.trackId,
        rating: review.rating,
      );

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  static Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  /// Get reviews for a track
  static Stream<List<MusicReview>> getTrackReviews(String trackId) {
    return _firestore
        .collection(_reviewsCollection)
        .where('trackId', isEqualTo: trackId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicReview.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Get user's reviews
  static Stream<List<MusicReview>> getUserReviews(String userId) {
    return _firestore
        .collection(_reviewsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicReview.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Like a review
  static Future<bool> likeReview(String reviewId) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'likes': FieldValue.arrayUnion([userId]),
        'dislikes': FieldValue.arrayRemove([userId]),
      });

      return true;
    } catch (e) {
      print('Error liking review: $e');
      return false;
    }
  }

  // ==================== RATINGS ====================

  /// Save or update a rating
  static Future<bool> _saveRating({
    required String userId,
    required String trackId,
    required double rating,
  }) async {
    try {
      final ratingId = '${userId}_$trackId';
      
      await _firestore.collection(_ratingsCollection).doc(ratingId).set({
        'userId': userId,
        'trackId': trackId,
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving rating: $e');
      return false;
    }
  }

  /// Get user's rating for a track
  static Future<double?> getUserRating(String userId, String trackId) async {
    try {
      final ratingId = '${userId}_$trackId';
      final doc = await _firestore.collection(_ratingsCollection).doc(ratingId).get();

      if (!doc.exists) return null;

      return (doc.data()?['rating'] as num?)?.toDouble();
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  /// Get average rating for a track
  static Future<Map<String, dynamic>> getTrackRatingStats(String trackId) async {
    try {
      final query = await _firestore
          .collection(_ratingsCollection)
          .where('trackId', isEqualTo: trackId)
          .get();

      if (query.docs.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double sum = 0;
      int count = 0;
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in query.docs) {
        final rating = (doc.data()['rating'] as num).toDouble();
        sum += rating;
        count++;
        distribution[rating.round()] = (distribution[rating.round()] ?? 0) + 1;
      }

      return {
        'average': sum / count,
        'count': count,
        'distribution': distribution,
      };
    } catch (e) {
      print('Error getting track rating stats: $e');
      return {'average': 0.0, 'count': 0};
    }
  }
}
