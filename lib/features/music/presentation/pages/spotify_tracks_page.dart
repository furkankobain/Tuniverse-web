import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';

class SpotifyTracksPage extends ConsumerStatefulWidget {
  const SpotifyTracksPage({super.key});

  @override
  ConsumerState<SpotifyTracksPage> createState() => _SpotifyTracksPageState();
}

class _SpotifyTracksPageState extends ConsumerState<SpotifyTracksPage> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> tracks;
      
      if (EnhancedSpotifyService.isConnected) {
        // Load from Spotify if connected
        tracks = await EnhancedSpotifyService.getSavedTracks(limit: 50);
      } else {
        // Use mock data if not connected
        tracks = _getMockTracks();
      }
      
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  List<Map<String, dynamic>> _getMockTracks() {
    return List.generate(20, (index) => {
      'id': 'mock_track_$index',
      'name': 'Şarkı ${index + 1}',
      'artists': [{'name': 'Sanatçı ${index + 1}'}],
      'album': {
        'name': 'Albüm ${index + 1}',
        'images': [{'url': null}],
      },
      'duration_ms': 180000 + (index * 15000),
    });
  }

  List<Map<String, dynamic>> get _filteredTracks {
    if (_searchQuery.isEmpty) return _tracks;
    
    return _tracks.where((track) {
      final name = (track['name'] ?? '').toString().toLowerCase();
      final artists = (track['artists'] as List?)
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
          'Şarkılarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTracks,
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
                    ModernDesignSystem.primaryGreen.withValues(alpha: 0.02),
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
                    hintText: 'Şarkı veya sanatçı ara...',
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
            
            // Tracks List
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredTracks.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildTracksList(isDark),
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
          Text('Şarkılar yükleniyor...'),
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
            Icons.music_note_rounded,
            size: 80,
            color: isDark 
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'Henüz kaydedilmiş şarkı yok'
                : 'Şarkı bulunamadı',
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

  Widget _buildTracksList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTracks.length,
      itemBuilder: (context, index) {
        final track = _filteredTracks[index];
        return _buildTrackCard(track, isDark);
      },
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track, bool isDark) {
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;
    final artistNames = (track['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isDark 
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: imageUrl == null ? ModernDesignSystem.primaryGradient : null,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? const Icon(Icons.music_note_rounded, color: Colors.white)
              : null,
        ),
        title: Text(
          track['name'] ?? 'Unknown Track',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artistNames,
          style: TextStyle(
            fontSize: 13,
            color: isDark 
                ? Colors.white.withValues(alpha: 0.6)
                : ModernDesignSystem.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDark 
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
        ),
        onTap: () {
          // Navigate to track detail page
        },
      ),
    );
  }
}
