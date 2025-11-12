import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

/// Social interactions service - likes, comments, sharing
class SocialInteractionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== LIKE SYSTEM ====================
  
  /// Like a review
  static Future<bool> likeReview(String reviewId, String userId) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      
      await reviewRef.update({
        'likes': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
      
      return true;
    } catch (e) {
      print('Error liking review: $e');
      return false;
    }
  }

  /// Unlike a review
  static Future<bool> unlikeReview(String reviewId, String userId) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      
      await reviewRef.update({
        'likes': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
      
      return true;
    } catch (e) {
      print('Error unliking review: $e');
      return false;
    }
  }

  /// Check if user liked a review
  static Future<bool> hasLikedReview(String reviewId, String userId) async {
    try {
      final doc = await _firestore.collection('reviews').doc(reviewId).get();
      final likes = List<String>.from(doc.data()?['likes'] ?? []);
      return likes.contains(userId);
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  /// Like a playlist
  static Future<bool> likePlaylist(String playlistId, String userId) async {
    try {
      final playlistRef = _firestore.collection('playlists').doc(playlistId);
      
      await playlistRef.update({
        'likes': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
      
      return true;
    } catch (e) {
      print('Error liking playlist: $e');
      return false;
    }
  }

  /// Unlike a playlist
  static Future<bool> unlikePlaylist(String playlistId, String userId) async {
    try {
      final playlistRef = _firestore.collection('playlists').doc(playlistId);
      
      await playlistRef.update({
        'likes': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
      
      return true;
    } catch (e) {
      print('Error unliking playlist: $e');
      return false;
    }
  }

  // ==================== COMMENT SYSTEM ====================
  
  /// Add comment to review
  static Future<String?> addComment({
    required String reviewId,
    required String userId,
    required String username,
    required String content,
  }) async {
    try {
      final commentRef = _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('comments')
          .doc();
      
      await commentRef.set({
        'id': commentRef.id,
        'reviewId': reviewId,
        'userId': userId,
        'username': username,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likeCount': 0,
      });
      
      // Update comment count on review
      await _firestore.collection('reviews').doc(reviewId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      return commentRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Get comments for review
  static Stream<List<Map<String, dynamic>>> getReviewComments(String reviewId) {
    return _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Delete comment
  static Future<bool> deleteComment(String reviewId, String commentId) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('comments')
          .doc(commentId)
          .delete();
      
      // Update comment count
      await _firestore.collection('reviews').doc(reviewId).update({
        'commentCount': FieldValue.increment(-1),
      });
      
      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Like a comment
  static Future<bool> likeComment(String reviewId, String commentId, String userId) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
      
      return true;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  // ==================== SOCIAL MEDIA SHARE ====================
  
  /// Share review to social media
  static Future<void> shareReview({
    required String trackName,
    required String artistName,
    required String reviewText,
    required int rating,
  }) async {
    try {
      final text = '''
🎵 $trackName - $artistName
⭐ ${rating}/5

$reviewText

#Tuniverse #MusicReview
''';
      
      await Share.share(
        text,
        subject: 'My review of $trackName',
      );
    } catch (e) {
      print('Error sharing review: $e');
    }
  }

  /// Share playlist to social media
  static Future<void> sharePlaylist({
    required String playlistName,
    required String trackCount,
    String? description,
  }) async {
    try {
      final text = '''
🎵 Check out my playlist: $playlistName
📀 $trackCount tracks

${description ?? ''}

#Tuniverse #Playlist
''';
      
      await Share.share(
        text,
        subject: 'My playlist: $playlistName',
      );
    } catch (e) {
      print('Error sharing playlist: $e');
    }
  }

  /// Share track
  static Future<void> shareTrack({
    required String trackName,
    required String artistName,
    String? spotifyUrl,
  }) async {
    try {
      final text = '''
🎵 $trackName - $artistName

${spotifyUrl ?? ''}

#Tuniverse #NowPlaying
''';
      
      await Share.share(
        text,
        subject: '$trackName - $artistName',
      );
    } catch (e) {
      print('Error sharing track: $e');
    }
  }

  /// Share to Twitter (X)
  static String getTwitterShareUrl({
    required String text,
    List<String> hashtags = const [],
  }) {
    final hashtagString = hashtags.join(',');
    final encodedText = Uri.encodeComponent(text);
    return 'https://twitter.com/intent/tweet?text=$encodedText&hashtags=$hashtagString';
  }

  /// Share to Instagram (opens Instagram app)
  static String getInstagramUrl() {
    return 'instagram://'; // Opens Instagram app
  }
}
