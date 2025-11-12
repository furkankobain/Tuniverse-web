import 'package:cloud_firestore/cloud_firestore.dart';
import 'lastfm_service.dart';

/// Aggregated rating data from multiple sources
class AggregatedRating {
  final double overall;           // 0-10 scale
  final double? spotifyScore;     // From Spotify popularity (0-10)
  final double? lastFmScore;      // From Last.fm data (0-10)
  final double? appScore;         // From app users (0-10)
  final int? appRatingCount;      // Number of ratings in app
  final int? lastFmPlaycount;
  final int? lastFmListeners;
  final List<String> sources;    // Which sources contributed

  AggregatedRating({
    required this.overall,
    this.spotifyScore,
    this.lastFmScore,
    this.appScore,
    this.appRatingCount,
    this.lastFmPlaycount,
    this.lastFmListeners,
    required this.sources,
  });

  factory AggregatedRating.fromJson(Map<String, dynamic> json) {
    return AggregatedRating(
      overall: json['overall'] as double,
      spotifyScore: json['spotifyScore'] as double?,
      lastFmScore: json['lastFmScore'] as double?,
      appScore: json['appScore'] as double?,
      sources: List<String>.from(json['sources'] as List),
      lastFmPlaycount: json['lastFmPlaycount'] as int?,
      lastFmListeners: json['lastFmListeners'] as int?,
      appRatingCount: json['appRatingCount'] as int?,
    );
  }

  String get displayRating => overall.toStringAsFixed(1);
  
  String get ratingBreakdown {
    final parts = <String>[];
    if (spotifyScore != null) parts.add('Spotify: ${spotifyScore!.toStringAsFixed(1)}');
    if (lastFmScore != null) parts.add('Last.fm: ${lastFmScore!.toStringAsFixed(1)}');
    if (appScore != null) parts.add('Community: ${appScore!.toStringAsFixed(1)}');
    return parts.join(' • ');
  }

  /// Get confidence level based on number of sources
  String get confidenceLevel {
    if (sources.length >= 3) return 'High';
    if (sources.length == 2) return 'Medium';
    return 'Low';
  }
}

class RatingAggregationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get aggregated rating for a track
  static Future<AggregatedRating?> getAggregatedRating({
    required String trackId,
    required String trackName,
    required String artistName,
    int? spotifyPopularity,
  }) async {
    final sources = <String>[];
    double? spotifyScore;
    double? lastFmScore;
    double? appScore;
    int? appRatingCount;
    int? lastFmPlaycount;
    int? lastFmListeners;

    // 1. Spotify Score (from popularity 0-100 -> 0-10)
    if (spotifyPopularity != null && spotifyPopularity > 0) {
      spotifyScore = (spotifyPopularity / 10.0).clamp(0, 10);
      sources.add('Spotify');
    }

    // 2. Last.fm Score
    try {
      final lastFmData = await LastFmService.getTrackInfo(
        artist: artistName,
        track: trackName,
      );

      if (lastFmData != null) {
        lastFmPlaycount = lastFmData['playcount'] as int?;
        lastFmListeners = lastFmData['listeners'] as int?;

        if (lastFmPlaycount != null && lastFmListeners != null) {
          lastFmScore = LastFmService.calculateRating(
            playcount: lastFmPlaycount,
            listeners: lastFmListeners,
          );
          sources.add('Last.fm');
        }
      }
    } catch (e) {
      print('Last.fm error: $e');
    }

    // 3. App Score (from Firestore)
    try {
      final ratingsSnapshot = await _firestore
          .collection('music_ratings')
          .where('trackId', isEqualTo: trackId)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        final ratings = ratingsSnapshot.docs
            .map((doc) => (doc.data()['rating'] as int?) ?? 0)
            .where((rating) => rating > 0)
            .toList();

        if (ratings.isNotEmpty) {
          final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          appScore = (avgRating * 2.0).clamp(0, 10); // Convert 0-5 to 0-10
          appRatingCount = ratings.length;
          sources.add('Community');
        }
      }
    } catch (e) {
      print('App ratings error: $e');
    }

    // Calculate overall score with weighted average
    final overall = _calculateWeightedAverage(
      spotifyScore: spotifyScore,
      lastFmScore: lastFmScore,
      appScore: appScore,
      appRatingCount: appRatingCount,
    );

    return AggregatedRating(
      overall: overall,
      spotifyScore: spotifyScore,
      lastFmScore: lastFmScore,
      appScore: appScore,
      appRatingCount: appRatingCount,
      lastFmPlaycount: lastFmPlaycount,
      lastFmListeners: lastFmListeners,
      sources: sources,
    );
  }

  /// Calculate weighted average of scores
  static double _calculateWeightedAverage({
    double? spotifyScore,
    double? lastFmScore,
    double? appScore,
    int? appRatingCount,
  }) {
    if (spotifyScore == null && lastFmScore == null && appScore == null) {
      return 0.0;
    }

    double totalWeight = 0.0;
    double weightedSum = 0.0;

    // Spotify weight: 30%
    if (spotifyScore != null) {
      const weight = 0.3;
      weightedSum += spotifyScore * weight;
      totalWeight += weight;
    }

    // Last.fm weight: 40% (most reliable for play data)
    if (lastFmScore != null) {
      const weight = 0.4;
      weightedSum += lastFmScore * weight;
      totalWeight += weight;
    }

    // App score weight: 30-70% based on count (more ratings = more weight)
    if (appScore != null && appRatingCount != null) {
      // Dynamic weight based on number of ratings
      // 10+ ratings = 70%, 5-9 ratings = 50%, 1-4 ratings = 30%
      double weight;
      if (appRatingCount >= 10) {
        weight = 0.7;
      } else if (appRatingCount >= 5) {
        weight = 0.5;
      } else {
        weight = 0.3;
      }

      weightedSum += appScore * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return 0.0;

    // Normalize
    final normalized = weightedSum / totalWeight;
    return normalized.clamp(0, 10);
  }

  /// Get cached rating or fetch new one
  static Future<AggregatedRating> getCachedTrackRating({
    required String trackId,
    required String trackName,
    required String artistName,
    int? spotifyPopularity,
    Duration cacheDuration = const Duration(hours: 24),
  }) async {
    // Check cache first
    try {
      final cacheDoc = await _firestore
          .collection('rating_cache')
          .doc(trackId)
          .get();

      if (cacheDoc.exists) {
        final data = cacheDoc.data()!;
        final cachedAt = (data['cachedAt'] as Timestamp).toDate();

        if (DateTime.now().difference(cachedAt) < cacheDuration) {
          // Cache is still valid
          return AggregatedRating(
            overall: (data['overall'] as num).toDouble(),
            spotifyScore: (data['spotifyScore'] as num?)?.toDouble(),
            lastFmScore: (data['lastFmScore'] as num?)?.toDouble(),
            appScore: (data['appScore'] as num?)?.toDouble(),
            appRatingCount: data['appRatingCount'] as int?,
            lastFmPlaycount: data['lastFmPlaycount'] as int?,
            lastFmListeners: data['lastFmListeners'] as int?,
            sources: List<String>.from(data['sources'] ?? []),
          );
        }
      }
    } catch (e) {
      print('Cache read error: $e');
    }

    // Fetch fresh data
    final rating = await getAggregatedRating(
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      spotifyPopularity: spotifyPopularity,
    );

    if (rating == null) {
      // Return default rating if fetch failed
      return AggregatedRating(
        overall: 0.0,
        sources: [],
      );
    }

    // Update cache
    try {
      await _firestore.collection('rating_cache').doc(trackId).set({
        'trackId': trackId,
        'overall': rating.overall,
        'spotifyScore': rating.spotifyScore,
        'lastFmScore': rating.lastFmScore,
        'appScore': rating.appScore,
        'appRatingCount': rating.appRatingCount,
        'lastFmPlaycount': rating.lastFmPlaycount,
        'lastFmListeners': rating.lastFmListeners,
        'sources': rating.sources,
        'cachedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Cache write error: $e');
    }

    return rating;
  }

  /// Clear rating cache for a specific track
  static Future<void> clearTrackCache(String trackId) async {
    try {
      await _firestore.collection('rating_cache').doc(trackId).delete();
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// Clear all old cache entries (older than duration)
  static Future<void> clearOldCache({
    Duration olderThan = const Duration(days: 7),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);
      final oldEntries = await _firestore
          .collection('rating_cache')
          .where('cachedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldEntries.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleared ${oldEntries.docs.length} old cache entries');
    } catch (e) {
      print('Cache cleanup error: $e');
    }
  }
}
