import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_bypass_auth_service.dart';

class UserStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's total statistics
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get total listens/plays from activities
      final listensSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'listened')
          .count()
          .get();

      // Get total ratings
      final ratingsSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'rated')
          .count()
          .get();

      // Get total reviews
      final reviewsSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'reviewed')
          .count()
          .get();

      // Get total playlists
      final playlistsSnapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      // Get following count
      final followingSnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .count()
          .get();

      // Get followers count
      final followersSnapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .count()
          .get();

      return {
        'totalListens': listensSnapshot.count ?? 0,
        'totalRatings': ratingsSnapshot.count ?? 0,
        'totalReviews': reviewsSnapshot.count ?? 0,
        'totalPlaylists': playlistsSnapshot.count ?? 0,
        'followingCount': followingSnapshot.count ?? 0,
        'followersCount': followersSnapshot.count ?? 0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalListens': 0,
        'totalRatings': 0,
        'totalReviews': 0,
        'totalPlaylists': 0,
        'followingCount': 0,
        'followersCount': 0,
      };
    }
  }

  /// Get top genres for user
  static Future<List<Map<String, dynamic>>> getTopGenres(
    String userId, {
    int limit = 10,
  }) async {
    try {
      // Get all user's activities with track info
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['listened', 'rated', 'reviewed'])
          .limit(500) // Limit to recent activities
          .get();

      // Count genres from metadata
      final genreCounts = <String, int>{};
      
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final metadata = data['metadata'] as Map<String, dynamic>?;
        
        if (metadata != null && metadata['genres'] != null) {
          final genres = metadata['genres'] as List;
          for (final genre in genres) {
            final genreStr = genre.toString();
            genreCounts[genreStr] = (genreCounts[genreStr] ?? 0) + 1;
          }
        }
      }

      // Sort by count and return top genres
      final topGenres = genreCounts.entries
          .map((entry) => {
                'genre': entry.key,
                'count': entry.value,
              })
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return topGenres.take(limit).toList();
    } catch (e) {
      print('Error getting top genres: $e');
      return [];
    }
  }

  /// Get top artists for user
  static Future<List<Map<String, dynamic>>> getTopArtists(
    String userId, {
    int limit = 10,
  }) async {
    try {
      // Get all user's activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['listened', 'rated', 'reviewed'])
          .limit(500)
          .get();

      // Count artists
      final artistCounts = <String, Map<String, dynamic>>{};
      
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final artistName = data['artistName'] as String?;
        
        if (artistName != null && artistName.isNotEmpty) {
          if (artistCounts.containsKey(artistName)) {
            artistCounts[artistName]!['count'] = 
                (artistCounts[artistName]!['count'] as int) + 1;
          } else {
            artistCounts[artistName] = {
              'artistName': artistName,
              'count': 1,
              'albumImage': data['albumImage'], // Use latest image
            };
          }
        }
      }

      // Sort by count
      final topArtists = artistCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return topArtists.take(limit).toList();
    } catch (e) {
      print('Error getting top artists: $e');
      return [];
    }
  }

  /// Get top tracks for user
  static Future<List<Map<String, dynamic>>> getTopTracks(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['listened', 'rated', 'reviewed'])
          .limit(500)
          .get();

      // Count tracks
      final trackCounts = <String, Map<String, dynamic>>{};
      
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final trackId = data['trackId'] as String?;
        final trackName = data['trackName'] as String?;
        
        if (trackId != null && trackName != null) {
          if (trackCounts.containsKey(trackId)) {
            trackCounts[trackId]!['count'] = 
                (trackCounts[trackId]!['count'] as int) + 1;
          } else {
            trackCounts[trackId] = {
              'trackId': trackId,
              'trackName': trackName,
              'artistName': data['artistName'],
              'albumImage': data['albumImage'],
              'count': 1,
            };
          }
        }
      }

      // Sort by count
      final topTracks = trackCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return topTracks.take(limit).toList();
    } catch (e) {
      print('Error getting top tracks: $e');
      return [];
    }
  }

  /// Calculate listening time (estimated from track count)
  static Future<Map<String, dynamic>> getListeningTime(String userId) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'listened')
          .get();

      final totalTracks = activitiesSnapshot.docs.length;
      // Estimate: average track is 3.5 minutes
      final totalMinutes = (totalTracks * 3.5).round();
      final totalHours = (totalMinutes / 60).round();
      final totalDays = (totalHours / 24).round();

      return {
        'totalTracks': totalTracks,
        'totalMinutes': totalMinutes,
        'totalHours': totalHours,
        'totalDays': totalDays,
      };
    } catch (e) {
      print('Error calculating listening time: $e');
      return {
        'totalTracks': 0,
        'totalMinutes': 0,
        'totalHours': 0,
        'totalDays': 0,
      };
    }
  }

  /// Get monthly stats
  static Future<Map<String, dynamic>> getMonthlyStats(
    String userId,
    DateTime month,
  ) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final listens = snapshot.docs.where((doc) => doc.data()['type'] == 'listened').length;
      final ratings = snapshot.docs.where((doc) => doc.data()['type'] == 'rated').length;
      final reviews = snapshot.docs.where((doc) => doc.data()['type'] == 'reviewed').length;

      return {
        'month': month,
        'listens': listens,
        'ratings': ratings,
        'reviews': reviews,
        'total': listens + ratings + reviews,
      };
    } catch (e) {
      print('Error getting monthly stats: $e');
      return {
        'month': month,
        'listens': 0,
        'ratings': 0,
        'reviews': 0,
        'total': 0,
      };
    }
  }

  /// Get yearly stats
  static Future<Map<String, dynamic>> getYearlyStats(
    String userId,
    int year,
  ) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .get();

      final listens = snapshot.docs.where((doc) => doc.data()['type'] == 'listened').length;
      final ratings = snapshot.docs.where((doc) => doc.data()['type'] == 'rated').length;
      final reviews = snapshot.docs.where((doc) => doc.data()['type'] == 'reviewed').length;

      // Get monthly breakdown
      final monthlyData = <int, Map<String, int>>{};
      for (var month = 1; month <= 12; month++) {
        monthlyData[month] = {
          'listens': 0,
          'ratings': 0,
          'reviews': 0,
        };
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final month = date.month;
          final type = data['type'] as String?;
          
          if (type == 'listened') {
            monthlyData[month]!['listens'] = monthlyData[month]!['listens']! + 1;
          } else if (type == 'rated') {
            monthlyData[month]!['ratings'] = monthlyData[month]!['ratings']! + 1;
          } else if (type == 'reviewed') {
            monthlyData[month]!['reviews'] = monthlyData[month]!['reviews']! + 1;
          }
        }
      }

      return {
        'year': year,
        'listens': listens,
        'ratings': ratings,
        'reviews': reviews,
        'total': listens + ratings + reviews,
        'monthlyData': monthlyData,
      };
    } catch (e) {
      print('Error getting yearly stats: $e');
      return {
        'year': year,
        'listens': 0,
        'ratings': 0,
        'reviews': 0,
        'total': 0,
        'monthlyData': {},
      };
    }
  }

  /// Get recent activity summary (last 7 days)
  static Future<Map<String, int>> getRecentActivity(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final listens = snapshot.docs.where((doc) => doc.data()['type'] == 'listened').length;
      final ratings = snapshot.docs.where((doc) => doc.data()['type'] == 'rated').length;
      final reviews = snapshot.docs.where((doc) => doc.data()['type'] == 'reviewed').length;

      return {
        'listens': listens,
        'ratings': ratings,
        'reviews': reviews,
        'total': listens + ratings + reviews,
      };
    } catch (e) {
      print('Error getting recent activity: $e');
      return {
        'listens': 0,
        'ratings': 0,
        'reviews': 0,
        'total': 0,
      };
    }
  }

  /// Get average rating given by user
  static Future<double> getAverageRating(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['rated', 'reviewed'])
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final rating = doc.data()['rating'] as double?;
        if (rating != null) {
          totalRating += rating;
          count++;
        }
      }

      return count > 0 ? totalRating / count : 0.0;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  /// Check if user is active (had activity in last 7 days)
  static Future<bool> isUserActive(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user is active: $e');
      return false;
    }
  }
}
