import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user's music statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      final ratingsSnapshot = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return _getEmptyStatistics();
      }

      final ratings = ratingsSnapshot.docs.map((doc) => doc.data()).toList();
      
      return {
        'totalRatings': ratings.length,
        'averageRating': _calculateAverageRating(ratings),
        'ratingDistribution': _calculateRatingDistribution(ratings),
        'topArtists': _getTopArtists(ratings),
        'topAlbums': _getTopAlbums(ratings),
        'topGenres': _getTopGenres(ratings),
        'recentActivity': _getRecentActivity(ratings),
        'monthlyStats': _getMonthlyStats(ratings),
        'yearlyStats': _getYearlyStats(ratings),
        'mostUsedTags': _getMostUsedTags(ratings),
        'ratingTrends': _getRatingTrends(ratings),
      };
    } catch (e) {
      return _getEmptyStatistics();
    }
  }

  /// Calculate average rating
  static double _calculateAverageRating(List<Map<String, dynamic>> ratings) {
    if (ratings.isEmpty) return 0.0;
    
    final total = ratings.fold<double>(0, (totalSum, rating) => totalSum + (rating['rating'] ?? 0).toDouble());
    return total / ratings.length;
  }

  /// Calculate rating distribution
  static Map<String, int> _calculateRatingDistribution(List<Map<String, dynamic>> ratings) {
    final distribution = <String, int>{};
    
    for (int i = 1; i <= 5; i++) {
      distribution[i.toString()] = 0;
    }
    
    for (final rating in ratings) {
      final ratingValue = rating['rating'] ?? 0;
      if (ratingValue >= 1 && ratingValue <= 5) {
        distribution[ratingValue.toString()] = (distribution[ratingValue.toString()] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  /// Get top artists
  static List<Map<String, dynamic>> _getTopArtists(List<Map<String, dynamic>> ratings) {
    final artistMap = <String, Map<String, dynamic>>{};
    
    for (final rating in ratings) {
      final artistName = rating['artists']?.toString() ?? 'Bilinmeyen Sanatçı';
      
      if (!artistMap.containsKey(artistName)) {
        artistMap[artistName] = {
          'name': artistName,
          'count': 0,
          'totalRating': 0.0,
          'averageRating': 0.0,
        };
      }
      
      final artist = artistMap[artistName]!;
      artist['count'] = (artist['count'] as int) + 1;
      artist['totalRating'] = (artist['totalRating'] as double) + (rating['rating'] ?? 0).toDouble();
    }
    
    // Calculate average ratings
    for (final artist in artistMap.values) {
      artist['averageRating'] = (artist['totalRating'] as double) / (artist['count'] as int);
    }
    
    final artists = artistMap.values.toList();
    artists.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return artists.take(10).toList();
  }

  /// Get top albums
  static List<Map<String, dynamic>> _getTopAlbums(List<Map<String, dynamic>> ratings) {
    final albumMap = <String, Map<String, dynamic>>{};
    
    for (final rating in ratings) {
      final albumName = rating['albumName']?.toString() ?? 'Bilinmeyen Albüm';
      final artistName = rating['artists']?.toString() ?? 'Bilinmeyen Sanatçı';
      final albumKey = '$albumName - $artistName';
      
      if (!albumMap.containsKey(albumKey)) {
        albumMap[albumKey] = {
          'name': albumName,
          'artist': artistName,
          'count': 0,
          'totalRating': 0.0,
          'averageRating': 0.0,
          'image': rating['albumImage'],
        };
      }
      
      final album = albumMap[albumKey]!;
      album['count'] = (album['count'] as int) + 1;
      album['totalRating'] = (album['totalRating'] as double) + (rating['rating'] ?? 0).toDouble();
    }
    
    // Calculate average ratings
    for (final album in albumMap.values) {
      album['averageRating'] = (album['totalRating'] as double) / (album['count'] as int);
    }
    
    final albums = albumMap.values.toList();
    albums.sort((a, b) => (b['averageRating'] as double).compareTo(a['averageRating'] as double));
    
    return albums.take(10).toList();
  }

  /// Get top genres (based on tags)
  static List<Map<String, dynamic>> _getTopGenres(List<Map<String, dynamic>> ratings) {
    final genreMap = <String, int>{};
    
    for (final rating in ratings) {
      final tags = List<String>.from(rating['tags'] ?? []);
      for (final tag in tags) {
        genreMap[tag] = (genreMap[tag] ?? 0) + 1;
      }
    }
    
    final genres = genreMap.entries
        .map((entry) => {'name': entry.key, 'count': entry.value})
        .toList();
    
    genres.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return genres.take(10).toList();
  }

  /// Get recent activity
  static List<Map<String, dynamic>> _getRecentActivity(List<Map<String, dynamic>> ratings) {
    final recentRatings = List<Map<String, dynamic>>.from(ratings);
    
    recentRatings.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    
    return recentRatings.take(10).toList();
  }

  /// Get monthly statistics
  static List<Map<String, dynamic>> _getMonthlyStats(List<Map<String, dynamic>> ratings) {
    final monthlyMap = <String, Map<String, dynamic>>{};
    
    for (final rating in ratings) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
      
      if (!monthlyMap.containsKey(monthKey)) {
        monthlyMap[monthKey] = {
          'month': monthKey,
          'count': 0,
          'totalRating': 0.0,
          'averageRating': 0.0,
        };
      }
      
      final month = monthlyMap[monthKey]!;
      month['count'] = (month['count'] as int) + 1;
      month['totalRating'] = (month['totalRating'] as double) + (rating['rating'] ?? 0).toDouble();
    }
    
    // Calculate average ratings
    for (final month in monthlyMap.values) {
      month['averageRating'] = (month['totalRating'] as double) / (month['count'] as int);
    }
    
    final months = monthlyMap.values.toList();
    months.sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
    
    return months.take(12).toList(); // Last 12 months
  }

  /// Get yearly statistics
  static List<Map<String, dynamic>> _getYearlyStats(List<Map<String, dynamic>> ratings) {
    final yearlyMap = <String, Map<String, dynamic>>{};
    
    for (final rating in ratings) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final yearKey = createdAt.year.toString();
      
      if (!yearlyMap.containsKey(yearKey)) {
        yearlyMap[yearKey] = {
          'year': yearKey,
          'count': 0,
          'totalRating': 0.0,
          'averageRating': 0.0,
        };
      }
      
      final year = yearlyMap[yearKey]!;
      year['count'] = (year['count'] as int) + 1;
      year['totalRating'] = (year['totalRating'] as double) + (rating['rating'] ?? 0).toDouble();
    }
    
    // Calculate average ratings
    for (final year in yearlyMap.values) {
      year['averageRating'] = (year['totalRating'] as double) / (year['count'] as int);
    }
    
    final years = yearlyMap.values.toList();
    years.sort((a, b) => (a['year'] as String).compareTo(b['year'] as String));
    
    return years;
  }

  /// Get most used tags
  static List<Map<String, dynamic>> _getMostUsedTags(List<Map<String, dynamic>> ratings) {
    final tagMap = <String, int>{};
    
    for (final rating in ratings) {
      final tags = List<String>.from(rating['tags'] ?? []);
      for (final tag in tags) {
        tagMap[tag] = (tagMap[tag] ?? 0) + 1;
      }
    }
    
    final tags = tagMap.entries
        .map((entry) => {'name': entry.key, 'count': entry.value})
        .toList();
    
    tags.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return tags.take(15).toList();
  }

  /// Get rating trends
  static Map<String, dynamic> _getRatingTrends(List<Map<String, dynamic>> ratings) {
    final trends = <String, dynamic>{};
    
    // Calculate trends for last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentRatings = ratings.where((rating) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return createdAt.isAfter(thirtyDaysAgo);
    }).toList();
    
    final oldRatings = ratings.where((rating) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return createdAt.isBefore(thirtyDaysAgo);
    }).toList();
    
    final recentAvg = recentRatings.isEmpty ? 0.0 : 
        recentRatings.fold<double>(0, (totalSum, rating) => totalSum + (rating['rating'] ?? 0).toDouble()) / recentRatings.length;
    
    final oldAvg = oldRatings.isEmpty ? 0.0 : 
        oldRatings.fold<double>(0, (totalSum, rating) => totalSum + (rating['rating'] ?? 0).toDouble()) / oldRatings.length;
    
    trends['recentAverage'] = recentAvg;
    trends['oldAverage'] = oldAvg;
    trends['trend'] = recentAvg - oldAvg; // Positive means improving, negative means declining
    trends['recentCount'] = recentRatings.length;
    trends['oldCount'] = oldRatings.length;
    
    return trends;
  }

  /// Get empty statistics for new users
  static Map<String, dynamic> _getEmptyStatistics() {
    return {
      'totalRatings': 0,
      'averageRating': 0.0,
      'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      'topArtists': <Map<String, dynamic>>[],
      'topAlbums': <Map<String, dynamic>>[],
      'topGenres': <Map<String, dynamic>>[],
      'recentActivity': <Map<String, dynamic>>[],
      'monthlyStats': <Map<String, dynamic>>[],
      'yearlyStats': <Map<String, dynamic>>[],
      'mostUsedTags': <Map<String, dynamic>>[],
      'ratingTrends': {
        'recentAverage': 0.0,
        'oldAverage': 0.0,
        'trend': 0.0,
        'recentCount': 0,
        'oldCount': 0,
      },
    };
  }

  /// Get listening insights
  static Future<Map<String, dynamic>> getListeningInsights() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      final ratingsSnapshot = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return {
          'totalListeningTime': 0,
          'favoriteTimeOfDay': 'Öğlen',
          'mostActiveDay': 'Pazartesi',
          'discoveryRate': 0.0,
          'consistencyScore': 0.0,
        };
      }

      final ratings = ratingsSnapshot.docs.map((doc) => doc.data()).toList();
      
      return {
        'totalListeningTime': _calculateTotalListeningTime(ratings),
        'favoriteTimeOfDay': _getFavoriteTimeOfDay(ratings),
        'mostActiveDay': _getMostActiveDay(ratings),
        'discoveryRate': _calculateDiscoveryRate(ratings),
        'consistencyScore': _calculateConsistencyScore(ratings),
      };
    } catch (e) {
      return {};
    }
  }

  static int _calculateTotalListeningTime(List<Map<String, dynamic>> ratings) {
    // Estimate 3 minutes per rated song
    return ratings.length * 3;
  }

  static String _getFavoriteTimeOfDay(List<Map<String, dynamic>> ratings) {
    final hourCounts = <int, int>{};
    
    for (final rating in ratings) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final hour = createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return 'Öğlen';
    
    final favoriteHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    if (favoriteHour >= 6 && favoriteHour < 12) return 'Sabah';
    if (favoriteHour >= 12 && favoriteHour < 18) return 'Öğlen';
    if (favoriteHour >= 18 && favoriteHour < 22) return 'Akşam';
    return 'Gece';
  }

  static String _getMostActiveDay(List<Map<String, dynamic>> ratings) {
    final dayCounts = <int, int>{};
    
    for (final rating in ratings) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final weekday = createdAt.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }
    
    if (dayCounts.isEmpty) return 'Pazartesi';
    
    final mostActiveDay = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[mostActiveDay - 1];
  }

  static double _calculateDiscoveryRate(List<Map<String, dynamic>> ratings) {
    if (ratings.length < 2) return 0.0;
    
    final sortedRatings = List<Map<String, dynamic>>.from(ratings);
    sortedRatings.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return aTime.compareTo(bTime);
    });
    
    int newArtists = 0;
    final seenArtists = <String>{};
    
    for (final rating in sortedRatings) {
      final artist = rating['artists']?.toString() ?? '';
      if (!seenArtists.contains(artist)) {
        newArtists++;
        seenArtists.add(artist);
      }
    }
    
    return (newArtists / ratings.length) * 100;
  }

  static double _calculateConsistencyScore(List<Map<String, dynamic>> ratings) {
    if (ratings.length < 7) return 0.0;
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final recentRatings = ratings.where((rating) {
      final createdAt = (rating['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return createdAt.isAfter(sevenDaysAgo);
    }).length;
    
    return (recentRatings / 7) * 100; // Score out of 100
  }
}
