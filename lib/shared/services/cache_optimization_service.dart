import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Cache optimization service for performance improvements
class CacheOptimizationService {
  // Cache size limits
  static const int maxImageCacheSize = 100 * 1024 * 1024; // 100 MB
  static const int maxDataCacheSize = 50 * 1024 * 1024;   // 50 MB
  static const int maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds
  
  // Cache stats
  static final ValueNotifier<CacheStats> cacheStats = 
      ValueNotifier<CacheStats>(CacheStats(
    imageSize: 0,
    dataSize: 0,
    totalSize: 0,
    itemCount: 0,
  ));

  // ==================== IMAGE CACHING ====================

  /// Cache image from URL
  static Future<String?> cacheImage(String url, String identifier) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Create unique filename from identifier
      final filename = identifier.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${cacheDir.path}/$filename.jpg';

      // Check if already cached
      final file = File(filePath);
      if (await file.exists()) {
        // Update access time
        await _updateAccessTime(filePath);
        return filePath;
      }

      // Download and cache
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        // Save metadata
        await _saveCacheMetadata(filePath, {
          'url': url,
          'identifier': identifier,
          'size': response.bodyBytes.length,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'lastAccessed': DateTime.now().millisecondsSinceEpoch,
        });

        await _updateCacheStats();
        return filePath;
      }

      return null;
    } catch (e) {
      print('Error caching image: $e');
      return null;
    }
  }

  /// Get cached image path
  static Future<String?> getCachedImage(String identifier) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filename = identifier.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${directory.path}/image_cache/$filename.jpg';

      final file = File(filePath);
      if (await file.exists()) {
        await _updateAccessTime(filePath);
        return filePath;
      }

      return null;
    } catch (e) {
      print('Error getting cached image: $e');
      return null;
    }
  }

  /// Clear expired image cache
  static Future<void> clearExpiredImageCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      
      if (!await cacheDir.exists()) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      
      await for (final file in cacheDir.list()) {
        if (file is File) {
          final metadata = await _getCacheMetadata(file.path);
          if (metadata != null) {
            final cachedAt = metadata['cachedAt'] as int;
            if (now - cachedAt > maxCacheAge) {
              await file.delete();
              await _removeCacheMetadata(file.path);
            }
          }
        }
      }

      await _updateCacheStats();
    } catch (e) {
      print('Error clearing expired image cache: $e');
    }
  }

  // ==================== DATA CACHING ====================

  /// Cache API response data
  static Future<void> cacheData(String key, dynamic data, {int? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cacheEntry = {
        'data': data,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'ttl': ttl,
      };

      await prefs.setString('cache_$key', jsonEncode(cacheEntry));
      await _updateCacheStats();
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  /// Get cached data
  static Future<dynamic> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_$key');
      
      if (cached == null) return null;

      final cacheEntry = jsonDecode(cached);
      final cachedAt = cacheEntry['cachedAt'] as int;
      final ttl = cacheEntry['ttl'] as int?;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if expired
      if (ttl != null && now - cachedAt > ttl * 1000) {
        await prefs.remove('cache_$key');
        return null;
      }

      return cacheEntry['data'];
    } catch (e) {
      print('Error getting cached data: $e');
      return null;
    }
  }

  /// Clear data cache
  static Future<void> clearDataCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
      
      for (final key in keys) {
        await prefs.remove(key);
      }

      await _updateCacheStats();
    } catch (e) {
      print('Error clearing data cache: $e');
    }
  }

  // ==================== PRELOADING ====================

  /// Preload popular tracks
  static Future<void> preloadPopularTracks(List<Map<String, dynamic>> tracks) async {
    try {
      // Preload album covers
      for (final track in tracks.take(20)) {
        final albumCover = track['album']?['images']?[0]?['url'];
        if (albumCover != null) {
          await cacheImage(albumCover, track['id']);
        }
      }

      // Cache track data
      await cacheData('popular_tracks', tracks, ttl: 3600); // 1 hour TTL
    } catch (e) {
      print('Error preloading popular tracks: $e');
    }
  }

  /// Preload user profile data
  static Future<void> preloadUserProfile(String userId) async {
    try {
      // This would fetch and cache user profile, reviews, playlists, etc.
      // Implementation would depend on your actual data fetching methods
      
      await cacheData('user_profile_$userId', {
        'preloaded': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, ttl: 1800); // 30 minutes TTL
    } catch (e) {
      print('Error preloading user profile: $e');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Get cache statistics
  static Future<CacheStats> getCacheStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Calculate image cache size
      final imageCacheDir = Directory('${directory.path}/image_cache');
      int imageSize = 0;
      int imageCount = 0;
      
      if (await imageCacheDir.exists()) {
        await for (final file in imageCacheDir.list()) {
          if (file is File) {
            imageSize += await file.length();
            imageCount++;
          }
        }
      }

      // Calculate data cache size
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getKeys().where((k) => k.startsWith('cache_'));
      int dataSize = 0;
      
      for (final key in cacheKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          dataSize += value.length;
        }
      }

      final stats = CacheStats(
        imageSize: imageSize,
        dataSize: dataSize,
        totalSize: imageSize + dataSize,
        itemCount: imageCount + cacheKeys.length,
      );

      cacheStats.value = stats;
      return stats;
    } catch (e) {
      print('Error getting cache stats: $e');
      return CacheStats(imageSize: 0, dataSize: 0, totalSize: 0, itemCount: 0);
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    try {
      // Clear image cache
      final directory = await getApplicationDocumentsDirectory();
      final imageCacheDir = Directory('${directory.path}/image_cache');
      
      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
      }

      // Clear data cache
      await clearDataCache();

      // Clear metadata
      final prefs = await SharedPreferences.getInstance();
      final metadataKeys = prefs.getKeys().where((k) => k.startsWith('cache_meta_'));
      for (final key in metadataKeys) {
        await prefs.remove(key);
      }

      await _updateCacheStats();
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  /// Optimize cache (remove old/least used items)
  static Future<void> optimizeCache() async {
    try {
      await clearExpiredImageCache();
      await _enforceImageCacheLimit();
      await _enforceDataCacheLimit();
      await _updateCacheStats();
    } catch (e) {
      print('Error optimizing cache: $e');
    }
  }

  /// Enforce image cache size limit
  static Future<void> _enforceImageCacheLimit() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      
      if (!await cacheDir.exists()) return;

      // Get all files with metadata
      final files = <FileWithMetadata>[];
      
      await for (final file in cacheDir.list()) {
        if (file is File) {
          final metadata = await _getCacheMetadata(file.path);
          final size = await file.length();
          
          files.add(FileWithMetadata(
            path: file.path,
            size: size,
            lastAccessed: metadata?['lastAccessed'] ?? 0,
          ));
        }
      }

      // Calculate total size
      final totalSize = files.fold<int>(0, (sum, f) => sum + f.size);

      if (totalSize > maxImageCacheSize) {
        // Sort by last accessed (least recent first)
        files.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

        // Remove files until under limit
        int currentSize = totalSize;
        for (final fileInfo in files) {
          if (currentSize <= maxImageCacheSize) break;

          final file = File(fileInfo.path);
          await file.delete();
          await _removeCacheMetadata(fileInfo.path);
          currentSize -= fileInfo.size;
        }
      }
    } catch (e) {
      print('Error enforcing image cache limit: $e');
    }
  }

  /// Enforce data cache size limit
  static Future<void> _enforceDataCacheLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
      
      // Calculate total size
      int totalSize = 0;
      final cacheEntries = <CacheEntryInfo>[];
      
      for (final key in cacheKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          final size = value.length;
          totalSize += size;
          
          try {
            final entry = jsonDecode(value);
            cacheEntries.add(CacheEntryInfo(
              key: key,
              size: size,
              cachedAt: entry['cachedAt'] ?? 0,
            ));
          } catch (_) {}
        }
      }

      if (totalSize > maxDataCacheSize) {
        // Sort by cached time (oldest first)
        cacheEntries.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));

        // Remove entries until under limit
        int currentSize = totalSize;
        for (final entry in cacheEntries) {
          if (currentSize <= maxDataCacheSize) break;

          await prefs.remove(entry.key);
          currentSize -= entry.size;
        }
      }
    } catch (e) {
      print('Error enforcing data cache limit: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Save cache metadata
  static Future<void> _saveCacheMetadata(String filePath, Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cache_meta_${filePath.hashCode}';
    await prefs.setString(key, jsonEncode(metadata));
  }

  /// Get cache metadata
  static Future<Map<String, dynamic>?> _getCacheMetadata(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cache_meta_${filePath.hashCode}';
      final metadata = prefs.getString(key);
      
      if (metadata != null) {
        return jsonDecode(metadata);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove cache metadata
  static Future<void> _removeCacheMetadata(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cache_meta_${filePath.hashCode}';
    await prefs.remove(key);
  }

  /// Update access time
  static Future<void> _updateAccessTime(String filePath) async {
    final metadata = await _getCacheMetadata(filePath);
    if (metadata != null) {
      metadata['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
      await _saveCacheMetadata(filePath, metadata);
    }
  }

  /// Update cache stats
  static Future<void> _updateCacheStats() async {
    await getCacheStats();
  }
}

// ==================== MODELS ====================

/// Cache statistics model
class CacheStats {
  final int imageSize;
  final int dataSize;
  final int totalSize;
  final int itemCount;

  CacheStats({
    required this.imageSize,
    required this.dataSize,
    required this.totalSize,
    required this.itemCount,
  });

  String get imageSizeFormatted => _formatBytes(imageSize);
  String get dataSizeFormatted => _formatBytes(dataSize);
  String get totalSizeFormatted => _formatBytes(totalSize);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// File with metadata helper class
class FileWithMetadata {
  final String path;
  final int size;
  final int lastAccessed;

  FileWithMetadata({
    required this.path,
    required this.size,
    required this.lastAccessed,
  });
}

/// Cache entry info helper class
class CacheEntryInfo {
  final String key;
  final int size;
  final int cachedAt;

  CacheEntryInfo({
    required this.key,
    required this.size,
    required this.cachedAt,
  });
}
