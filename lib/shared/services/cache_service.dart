import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'timestamp_';
  
  // Cache duration in minutes
  static const int defaultCacheDuration = 30;
  static const int shortCacheDuration = 5;
  static const int longCacheDuration = 1440; // 24 hours

  /// Get cached data if available and not expired
  static Future<Map<String, dynamic>?> get(
    String key, {
    int cacheDurationMinutes = defaultCacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final timestampKey = _timestampPrefix + key;

      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (cachedData == null || timestamp == null) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - timestamp;
      final maxAge = cacheDurationMinutes * 60 * 1000; // Convert to milliseconds

      if (cacheAge > maxAge) {
        // Cache expired, remove it
        await remove(key);
        return null;
      }

      return json.decode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      print('CacheService.get error: $e');
      return null;
    }
  }

  /// Cache data with timestamp
  static Future<bool> set(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final timestampKey = _timestampPrefix + key;

      final jsonData = json.encode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(cacheKey, jsonData);
      await prefs.setInt(timestampKey, timestamp);

      return true;
    } catch (e) {
      print('CacheService.set error: $e');
      return false;
    }
  }

  /// Remove specific cache entry
  static Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final timestampKey = _timestampPrefix + key;

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      return true;
    } catch (e) {
      print('CacheService.remove error: $e');
      return false;
    }
  }

  /// Clear all cache
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      print('CacheService.clearAll error: $e');
      return false;
    }
  }

  /// Get cache size in bytes (approximate)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalSize = 0;

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }

      return totalSize;
    } catch (e) {
      print('CacheService.getCacheSize error: $e');
      return 0;
    }
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix)).toList();

      final info = <String, dynamic>{
        'total_entries': cacheKeys.length,
        'total_size_bytes': await getCacheSize(),
        'entries': <Map<String, dynamic>>[],
      };

      for (final cacheKey in cacheKeys) {
        final key = cacheKey.replaceFirst(_cachePrefix, '');
        final timestampKey = _timestampPrefix + key;
        final timestamp = prefs.getInt(timestampKey);
        final value = prefs.getString(cacheKey);

        if (timestamp != null && value != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          final ageMinutes = (age / 1000 / 60).round();

          info['entries'].add({
            'key': key,
            'age_minutes': ageMinutes,
            'size_bytes': value.length,
          });
        }
      }

      return info;
    } catch (e) {
      print('CacheService.getCacheInfo error: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear old cache entries (older than specified minutes)
  static Future<int> clearOldCache(int olderThanMinutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int removedCount = 0;

      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = olderThanMinutes * 60 * 1000;

      for (final key in keys) {
        if (key.startsWith(_timestampPrefix)) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final age = now - timestamp;
            if (age > maxAge) {
              final cacheKey = key.replaceFirst(_timestampPrefix, _cachePrefix);
              await prefs.remove(key);
              await prefs.remove(cacheKey);
              removedCount++;
            }
          }
        }
      }

      return removedCount;
    } catch (e) {
      print('CacheService.clearOldCache error: $e');
      return 0;
    }
  }

  /// Generate cache key from parameters
  static String generateKey(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return endpoint;
    }

    final sortedParams = params.keys.toList()..sort();
    final paramString = sortedParams
        .map((key) => '$key=${params[key]}')
        .join('&');

    return '${endpoint}_$paramString';
  }
}

/// Cache wrapper for async functions
class CachedResponse<T> {
  final T data;
  final bool fromCache;
  final DateTime? cachedAt;

  CachedResponse({
    required this.data,
    this.fromCache = false,
    this.cachedAt,
  });
}

/// Mixin for services to add caching capabilities
mixin CacheableMixin {
  Future<Map<String, dynamic>?> getCachedData(
    String key, {
    int cacheDuration = CacheService.defaultCacheDuration,
  }) async {
    return await CacheService.get(key, cacheDurationMinutes: cacheDuration);
  }

  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await CacheService.set(key, data);
  }

  Future<T> withCache<T>({
    required String cacheKey,
    required Future<T> Function() fetchFn,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    int cacheDuration = CacheService.defaultCacheDuration,
  }) async {
    // Try to get from cache first
    final cached = await getCachedData(cacheKey, cacheDuration: cacheDuration);
    if (cached != null) {
      try {
        return fromJson(cached);
      } catch (e) {
        print('Cache deserialization error: $e');
      }
    }

    // Fetch fresh data
    final data = await fetchFn();

    // Cache it
    try {
      await cacheData(cacheKey, toJson(data));
    } catch (e) {
      print('Cache serialization error: $e');
    }

    return data;
  }
}
