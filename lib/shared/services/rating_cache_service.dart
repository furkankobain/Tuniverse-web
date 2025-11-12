import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'rating_aggregation_service.dart';

class RatingCacheService {
  static const String _cachePrefix = 'rating_cache_';
  static const Duration _cacheDuration = Duration(hours: 24);

  // Cache'e rating kaydet
  static Future<void> cacheRating(
    String trackId,
    AggregatedRating rating,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + trackId;
      
      final cacheData = {
        'rating': rating.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Rating cache kaydetme hatası: $e');
    }
  }

  // Cache'den rating getir
  static Future<AggregatedRating?> getCachedRating(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + trackId;
      
      final cacheString = prefs.getString(cacheKey);
      if (cacheString == null) return null;
      
      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      // Cache süresi dolmuş mu kontrol et
      if (DateTime.now().difference(cachedTime) > _cacheDuration) {
        // Eski cache'i temizle
        await prefs.remove(cacheKey);
        return null;
      }
      
      // Cache geçerli, rating'i döndür
      return AggregatedRating.fromJson(
        cacheData['rating'] as Map<String, dynamic>,
      );
    } catch (e) {
      print('Rating cache okuma hatası: $e');
      return null;
    }
  }

  // Tüm cache'i temizle
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache temizleme hatası: $e');
    }
  }

  // Eski cache'leri temizle
  static Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final cacheString = prefs.getString(key);
          if (cacheString != null) {
            final cacheData = json.decode(cacheString) as Map<String, dynamic>;
            final timestamp = cacheData['timestamp'] as int;
            final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            
            if (DateTime.now().difference(cachedTime) > _cacheDuration) {
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      print('Eski cache temizleme hatası: $e');
    }
  }

  // Cache boyutunu kontrol et
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      return keys.where((key) => key.startsWith(_cachePrefix)).length;
    } catch (e) {
      print('Cache boyutu kontrol hatası: $e');
      return 0;
    }
  }

  // Belirli bir track'in cache durumunu kontrol et
  static Future<bool> isCached(String trackId) async {
    final cached = await getCachedRating(trackId);
    return cached != null;
  }

  // Cache'den rating getir, yoksa API'den çek ve cache'le
  static Future<AggregatedRating?> getRatingWithCache({
    required String trackId,
    required String trackName,
    required String artistName,
    int? spotifyPopularity,
  }) async {
    // Önce cache'e bak
    final cached = await getCachedRating(trackId);
    if (cached != null) {
      return cached;
    }

    // Cache'de yoksa API'den çek
    final rating = await RatingAggregationService.getAggregatedRating(
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      spotifyPopularity: spotifyPopularity,
    );

    // Yeni rating'i cache'le
    if (rating != null) {
      await cacheRating(trackId, rating);
    }

    return rating;
  }
}

// AggregatedRating için JSON serialization extension
extension AggregatedRatingJson on AggregatedRating {
  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'spotifyScore': spotifyScore,
      'lastFmScore': lastFmScore,
      'appScore': appScore,
      'sources': sources,
      'lastFmPlaycount': lastFmPlaycount,
      'lastFmListeners': lastFmListeners,
      'appRatingCount': appRatingCount,
    };
  }
}
