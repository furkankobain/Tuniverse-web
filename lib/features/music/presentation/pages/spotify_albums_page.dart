import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';

class SpotifyAlbumsPage extends ConsumerStatefulWidget {
  const SpotifyAlbumsPage({super.key});

  @override
  ConsumerState<SpotifyAlbumsPage> createState() => _SpotifyAlbumsPageState();
}

class _SpotifyAlbumsPageState extends ConsumerState<SpotifyAlbumsPage> {
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> albums;
      
      if (EnhancedSpotifyService.isConnected) {
        // Load from Spotify if connected
        albums = await EnhancedSpotifyService.getSavedAlbums(limit: 50);
      } else {
        // Use mock data if not connected
        albums = _getMockAlbums();
      }
      
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
  
  List<Map<String, dynamic>> _getMockAlbums() {
    return List.generate(20, (index) => {
      'id': 'mock_album_$index',
      'name': 'Albüm ${index + 1}',
      'artists': [{'name': 'Sanatçı ${index + 1}'}],
      'images': [{'url': null}],
      'total_tracks': 10 + index,
      'release_date': '2024',
    });
  }

  List<Map<String, dynamic>> get _filteredAlbums {
    if (_searchQuery.isEmpty) return _albums;
    
    return _albums.where((album) {
      final name = (album['name'] ?? '').toString().toLowerCase();
      final artists = (album['artists'] as List?)
          ?.map((a) => (a['name'] ?? '').toString().toLowerCase())
          .join(' ') ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || artists.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Albümlerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAlbums,
          ),
        ],
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
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: isDark 
                    ? ModernDesignSystem.darkGlassmorphism
                    : BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                        boxShadow: ModernDesignSystem.mediumShadow,
                      ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Albüm veya sanatçı ara...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // Albums Grid
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredAlbums.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildAlbumsGrid(isDark),
            ),
          ],
        ),
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
          Text('Albümler yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.album_rounded,
            size: 80,
            color: isDark 
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'Henüz kaydedilmiş albüm yok'
                : 'Albüm bulunamadı',
            style: TextStyle(
              fontSize: 18,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredAlbums.length,
      itemBuilder: (context, index) {
        final album = _filteredAlbums[index];
        return _buildAlbumCard(album, isDark);
      },
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, bool isDark) {
    final imageUrl = (album['images'] as List?)?.isNotEmpty == true
        ? album['images'][0]['url']
        : null;
    final artistNames = (album['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    return GestureDetector(
      onTap: () {
        // Navigate to album detail page
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
            // Album Cover
            Expanded(
              child: Container(
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
                    ? const Icon(
                        Icons.album_rounded,
                        color: Colors.white,
                        size: 48,
                      )
                    : null,
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 12,
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${album['total_tracks'] ?? 0} şarkı',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
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
}
