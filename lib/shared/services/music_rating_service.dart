import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/music_rating.dart';

class MusicRatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'music_ratings';

  /// Add or update a music rating
  static Future<String> saveRating({
    required String trackId,
    required String trackName,
    required String artists,
    required String albumName,
    String? albumImage,
    required int rating,
    String? review,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if rating already exists
      final existingRating = await getRatingByTrackId(trackId);
      
      if (existingRating != null) {
        // Update existing rating
        final updatedRating = existingRating.copyWith(
          rating: rating,
          review: review,
          tags: tags,
          updatedAt: DateTime.now(),
        );
        
        await _firestore
            .collection(_collection)
            .doc(existingRating.id)
            .update(updatedRating.toFirestore());
        
        return existingRating.id;
      } else {
        // Create new rating
        final newRating = MusicRating(
          id: '', // Will be set by Firestore
          userId: user.uid,
          trackId: trackId,
          trackName: trackName,
          artists: artists,
          albumName: albumName,
          albumImage: albumImage,
          rating: rating,
          review: review,
          tags: tags ?? [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final docRef = await _firestore
            .collection(_collection)
            .add(newRating.toFirestore());
        
        return docRef.id;
      }
    } catch (e) {
      // print( // Debug log removed'Error saving rating: $e');
      rethrow;
    }
  }

  /// Get rating for a specific track by current user
  static Future<MusicRating?> getRatingByTrackId(String trackId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('trackId', isEqualTo: trackId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return MusicRating.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      // print( // Debug log removed'Error getting rating: $e');
      return null;
    }
  }

  /// Get all ratings by current user
  static Future<List<MusicRating>> getUserRatings({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => MusicRating.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print( // Debug log removed'Error getting user ratings: $e');
      return [];
    }
  }

  /// Get ratings by rating value
  static Future<List<MusicRating>> getRatingsByRating(
    int rating, {
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('rating', isEqualTo: rating)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => MusicRating.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print( // Debug log removed'Error getting ratings by rating: $e');
      return [];
    }
  }

  /// Delete a rating
  static Future<bool> deleteRating(String ratingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verify ownership
      final doc = await _firestore.collection(_collection).doc(ratingId).get();
      if (!doc.exists || doc.data()?['userId'] != user.uid) {
        return false;
      }

      await _firestore.collection(_collection).doc(ratingId).delete();
      return true;
    } catch (e) {
      // print( // Debug log removed'Error deleting rating: $e');
      return false;
    }
  }

  /// Get user's rating statistics
  static Future<Map<String, dynamic>> getUserRatingStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();

      final ratings = querySnapshot.docs
          .map((doc) => MusicRating.fromFirestore(doc))
          .toList();

      if (ratings.isEmpty) {
        return {
          'totalRatings': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final totalRatings = ratings.length;
      final averageRating = ratings.map((r) => r.rating).reduce((a, b) => a + b) / totalRatings;
      
      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        ratingDistribution[rating.rating] = (ratingDistribution[rating.rating] ?? 0) + 1;
      }

      return {
        'totalRatings': totalRatings,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      // print( // Debug log removed'Error getting rating stats: $e');
      return {};
    }
  }

  /// Search ratings by track name or artist
  static Future<List<MusicRating>> searchRatings(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();

      final ratings = querySnapshot.docs
          .map((doc) => MusicRating.fromFirestore(doc))
          .toList();

      // Filter by search query (case insensitive)
      final lowercaseQuery = query.toLowerCase();
      return ratings.where((rating) {
        return rating.trackName.toLowerCase().contains(lowercaseQuery) ||
               rating.artists.toLowerCase().contains(lowercaseQuery) ||
               rating.albumName.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      // print( // Debug log removed'Error searching ratings: $e');
      return [];
    }
  }

  /// Get recent ratings (last 7 days)
  static Future<List<MusicRating>> getRecentRatings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MusicRating.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print( // Debug log removed'Error getting recent ratings: $e');
      return [];
    }
  }
}
