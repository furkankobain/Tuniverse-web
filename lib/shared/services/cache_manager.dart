import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'image_cache_service.dart';
import 'rating_cache_service.dart';
import 'cache_optimization_service.dart';

/// Unified Cache Manager
/// Coordinates all cache services and provides centralized management
class CacheManager {
  /// Get total cache size across all services
  static Future<int> getTotalCacheSize() async {
    try {
      int total = 0;
      
      // Data cache
      total += await CacheService.getCacheSize();
      
      // Image cache
      total += await ImageCacheService.getCacheSize();
      
      // Rating cache (approximate)
      final ratingCount = await RatingCacheService.getCacheSize();
      total += ratingCount * 1024; // Estimate 1KB per rating
      
      return total;
    } catch (e) {
      debugPrint('Error getting total cache size: $e');
      return 0;
    }
  }

  /// Clear all caches
  static Future<bool> clearAllCaches() async {
    try {
      await Future.wait([
        CacheService.clearAll(),
        ImageCacheService.clearCache(),
        RatingCacheService.clearAllCache(),
        CacheOptimizationService.clearDataCache(),
      ]);
      
      debugPrint('✅ All caches cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing caches: $e');
      return false;
    }
  }

  /// Clear expired/old caches
  static Future<int> clearOldCaches({int olderThanMinutes = 1440}) async {
    try {
      int removedCount = 0;
      
      // Clear old data cache
      removedCount += await CacheService.clearOldCache(olderThanMinutes);
      
      // Clear old image cache
      await ImageCacheService.clearOldCache();
      
      // Clear expired rating cache
      await RatingCacheService.cleanExpiredCache();
      
      debugPrint('✅ Removed $removedCount old cache entries');
      return removedCount;
    } catch (e) {
      debugPrint('❌ Error clearing old caches: $e');
      return 0;
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final dataSize = await CacheService.getCacheSize();
      final imageSize = await ImageCacheService.getCacheSize();
      final ratingCount = await RatingCacheService.getCacheSize();
      final dataCacheInfo = await CacheService.getCacheInfo();
      
      return {
        'total_size': dataSize + imageSize + (ratingCount * 1024),
        'data_cache_size': dataSize,
        'image_cache_size': imageSize,
        'rating_cache_count': ratingCount,
        'data_cache_entries': dataCacheInfo['total_entries'] ?? 0,
        'formatted_total': _formatBytes(dataSize + imageSize + (ratingCount * 1024)),
        'formatted_data': _formatBytes(dataSize),
        'formatted_image': _formatBytes(imageSize),
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {
        'total_size': 0,
        'formatted_total': '0 B',
      };
    }
  }

  /// Auto-cleanup: Run periodic cache maintenance
  static Future<void> performMaintenance() async {
    try {
      debugPrint('🧹 Starting cache maintenance...');
      
      // Clear caches older than 7 days
      await clearOldCaches(olderThanMinutes: 7 * 24 * 60);
      
      // Check total cache size
      final totalSize = await getTotalCacheSize();
      final maxSize = 200 * 1024 * 1024; // 200 MB max
      
      if (totalSize > maxSize) {
        debugPrint('⚠️ Cache size exceeded limit, clearing all...');
        await clearAllCaches();
      }
      
      debugPrint('✅ Cache maintenance completed');
    } catch (e) {
      debugPrint('❌ Error in cache maintenance: $e');
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
