import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // Create review
  Future<String> createReview({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String albumId,
    required String albumName,
    required double rating,
    required String reviewText,
  }) async {
    try {
      final doc = await _firestore.collection(_collection).add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'albumId': albumId,
        'albumName': albumName,
        'rating': rating,
        'reviewText': reviewText,
        'likes': 0,
        'dislikes': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'isEdited': false,
      });
      return doc.id;
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  // Update review
  Future<void> updateReview(
    String reviewId, {
    double? rating,
    String? reviewText,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
        'isEdited': true,
      };
      if (rating != null) updates['rating'] = rating;
      if (reviewText != null) updates['reviewText'] = reviewText;

      await _firestore.collection(_collection).doc(reviewId).update(updates);
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  // Get album reviews
  Future<List<dynamic>> getAlbumReviews(String albumId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('albumId', isEqualTo: albumId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  // Get user review for album
  Future<dynamic> getUserReviewForAlbum(String userId, String albumId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('albumId', isEqualTo: albumId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return {'id': doc.id, ...doc.data()};
    } catch (e) {
      print('Error getting user review: $e');
      return null;
    }
  }

  // Get album rating stats
  Future<Map<String, dynamic>> getAlbumRatingStats(String albumId) async {
    try {
      final reviews = await getAlbumReviews(albumId);
      
      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'distribution': <int, int>{},
        };
      }

      final ratings = reviews.map((r) => (r['rating'] as num).toDouble()).toList();
      final sum = ratings.reduce((a, b) => a + b);
      final average = sum / ratings.length;

      final distribution = <int, int>{};
      for (var rating in ratings) {
        final rounded = rating.round();
        distribution[rounded] = (distribution[rounded] ?? 0) + 1;
      }

      return {
        'averageRating': average,
        'totalRatings': ratings.length,
        'distribution': distribution,
      };
    } catch (e) {
      print('Error getting rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'distribution': <int, int>{},
      };
    }
  }

  // Like review
  Future<void> likeReview(String reviewId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final likes = (data['likes'] ?? 0) as int;
      
      await _firestore.collection(_collection).doc(reviewId).update({
        'likes': likes + 1,
      });
    } catch (e) {
      print('Error liking review: $e');
      rethrow;
    }
  }

  // Dislike review
  Future<void> dislikeReview(String reviewId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final dislikes = (data['dislikes'] ?? 0) as int;
      
      await _firestore.collection(_collection).doc(reviewId).update({
        'dislikes': dislikes + 1,
      });
    } catch (e) {
      print('Error disliking review: $e');
      rethrow;
    }
  }
}
