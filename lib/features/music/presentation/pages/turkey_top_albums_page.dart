import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';

class TurkeyTopAlbumsPage extends ConsumerStatefulWidget {
  const TurkeyTopAlbumsPage({super.key});

  @override
  ConsumerState<TurkeyTopAlbumsPage> createState() => _TurkeyTopAlbumsPageState();
}

class _TurkeyTopAlbumsPageState extends ConsumerState<TurkeyTopAlbumsPage> {
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);
    
    try {
      final albums = await EnhancedSpotifyService.getTurkeyTopAlbums(limit: 50);
      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Türkiye\'nin Popüler Albümleri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.accentBlue.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _buildAlbumsGrid(isDark),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Popüler albümler yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid(bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return _buildAlbumCard(album, index + 1, isDark);
      },
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, int rank, bool isDark) {
    final imageUrl = (album['images'] as List?)?.isNotEmpty == true
        ? album['images'][0]['url']
        : null;
    final artistNames = (album['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    return GestureDetector(
      onTap: () {
        // Navigate to album details
      },
      child: Container(
        decoration: isDark 
            ? ModernDesignSystem.darkGlassmorphism
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                boxShadow: ModernDesignSystem.mediumShadow,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Album Cover with Rank Badge
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: imageUrl == null ? ModernDesignSystem.blueGradient : null,
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? const Center(
                            child: Icon(
                              Icons.album_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          )
                        : null,
                  ),
                  // Rank Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: rank <= 10 
                            ? ModernDesignSystem.sunsetGradient
                            : LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Album Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? 'Unknown Album',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artistNames,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.6)
                          : ModernDesignSystem.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${album['total_tracks'] ?? 0} şarkı',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      if (album['release_date'] != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatReleaseDate(album['release_date']),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReleaseDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      // Handle different date formats (YYYY-MM-DD, YYYY-MM, YYYY)
      final parts = dateString.split('-');
      if (parts.isEmpty) return dateString;
      
      final year = parts[0];
      if (parts.length == 1) return year;
      
      final month = parts.length > 1 ? parts[1] : '';
      if (parts.length == 2) return '$month/$year';
      
      final day = parts.length > 2 ? parts[2] : '';
      return '$day.$month.$year';
    } catch (e) {
      return dateString;
    }
  }
}
