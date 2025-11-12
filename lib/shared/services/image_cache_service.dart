import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Image caching and optimization service
/// Handles image loading, caching, compression and memory management
class ImageCacheService {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'tuniverse_image_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: 'tuniverse_image_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Get optimized cached network image widget
  static Widget getCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool fadeIn = true,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeIn ? const Duration(milliseconds: 300) : Duration.zero,
      cacheManager: _cacheManager,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }

  /// Get album art with standard size
  static Widget getAlbumArt({
    required String imageUrl,
    double size = 300,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final widget = getCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: widget,
      );
    }

    return widget;
  }

  /// Get optimized list thumbnail
  static Widget getListThumbnail({
    required String imageUrl,
    double size = 60,
  }) {
    return getCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  /// Preload images for better UX
  static Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await _cacheManager.downloadFile(url);
      } catch (e) {
        print('Error preloading image: $url - $e');
      }
    }
  }

  /// Clear all cached images
  static Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final tuniverseCache = Directory('${cacheDir.path}/tuniverse_image_cache');
      
      if (!await tuniverseCache.exists()) return 0;

      int totalSize = 0;
      await for (final file in tuniverseCache.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  /// Clear old cache files (older than 30 days)
  static Future<void> clearOldCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final tuniverseCache = Directory('${cacheDir.path}/tuniverse_image_cache');
      
      if (!await tuniverseCache.exists()) return;

      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));

      await for (final file in tuniverseCache.list(recursive: true)) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoff)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error clearing old cache: $e');
    }
  }

  /// Format cache size for display
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Default placeholder widget
  static Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Default error widget
  static Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.music_note,
        color: Colors.grey[400],
        size: 40,
      ),
    );
  }

  /// Check if image is cached
  static Future<bool> isCached(String imageUrl) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(imageUrl);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Remove specific image from cache
  static Future<void> removeFromCache(String imageUrl) async {
    try {
      await _cacheManager.removeFile(imageUrl);
    } catch (e) {
      print('Error removing from cache: $e');
    }
  }

  /// Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final size = await getCacheSize();
      final cacheDir = await getTemporaryDirectory();
      final tuniverseCache = Directory('${cacheDir.path}/tuniverse_image_cache');
      
      int fileCount = 0;
      if (await tuniverseCache.exists()) {
        await for (final file in tuniverseCache.list(recursive: true)) {
          if (file is File) fileCount++;
        }
      }

      return {
        'size': size,
        'formattedSize': formatCacheSize(size),
        'fileCount': fileCount,
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {
        'size': 0,
        'formattedSize': '0 B',
        'fileCount': 0,
      };
    }
  }
}

/// Memory management for images
class ImageMemoryManager {
  /// Clear image cache from memory
  static void clearMemoryCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Set memory cache size (in MB)
  static void setMemoryCacheSize(int megabytes) {
    imageCache.maximumSizeBytes = megabytes * 1024 * 1024;
  }

  /// Get current memory cache size
  static int getCurrentMemoryCacheSize() {
    return imageCache.currentSizeBytes;
  }

  /// Get max memory cache size
  static int getMaxMemoryCacheSize() {
    return imageCache.maximumSizeBytes;
  }

  /// Optimize for low memory devices
  static void optimizeForLowMemory() {
    // Reduce cache sizes
    imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB
    imageCache.maximumSize = 50; // 50 images
  }

  /// Optimize for high memory devices
  static void optimizeForHighMemory() {
    // Increase cache sizes
    imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200 MB
    imageCache.maximumSize = 200; // 200 images
  }

  /// Get cache stats
  static Map<String, dynamic> getCacheStats() {
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'liveImageCount': imageCache.liveImageCount,
      'pendingImageCount': imageCache.pendingImageCount,
    };
  }
}
