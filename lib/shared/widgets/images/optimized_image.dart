import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimize edilmiş network image widget
/// Memory ve network kullanımını optimize eder
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableMemoryCache;
  
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableMemoryCache = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: _getMemCacheSize(width),
      memCacheHeight: _getMemCacheSize(height),
      maxWidthDiskCache: _getDiskCacheSize(width),
      maxHeightDiskCache: _getDiskCacheSize(height),
      placeholder: (context, url) => 
          placeholder ?? _buildPlaceholder(context),
      errorWidget: (context, url, error) => 
          errorWidget ?? _buildErrorWidget(context),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.grey[700]! : Colors.grey[400]!,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      child: Icon(
        Icons.music_note,
        size: (width != null && width! < 100) ? 24 : 48,
        color: isDark ? Colors.grey[700] : Colors.grey[400],
      ),
    );
  }

  /// Memory cache boyutunu hesapla (piksel cinsinden)
  /// Max 800px ile sınırla (memory tasarrufu)
  int? _getMemCacheSize(double? size) {
    if (size == null) return null;
    final pixelSize = (size * 2).toInt(); // 2x for high DPI
    return pixelSize > 800 ? 800 : pixelSize;
  }

  /// Disk cache boyutunu hesapla
  /// Max 1200px ile sınırla (storage tasarrufu)
  int? _getDiskCacheSize(double? size) {
    if (size == null) return null;
    final pixelSize = (size * 2).toInt();
    return pixelSize > 1200 ? 1200 : pixelSize;
  }
}

/// Circular optimized image (avatar için)
class CircularOptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  
  const CircularOptimizedImage({
    super.key,
    required this.imageUrl,
    this.size = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      errorWidget: _buildInitials(context),
    );
  }

  Widget _buildInitials(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? 
            (isDark ? Colors.grey[800] : Colors.grey[300]),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: isDark ? Colors.grey[600] : Colors.grey[500],
      ),
    );
  }
}

/// Square album art image
class AlbumArtImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  
  const AlbumArtImage({
    super.key,
    required this.imageUrl,
    this.size = 160,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}
