import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';

class GenrePage extends ConsumerStatefulWidget {
  final String genre;
  
  const GenrePage({
    super.key,
    required this.genre,
  });

  @override
  ConsumerState<GenrePage> createState() => _GenrePageState();
}

class _GenrePageState extends ConsumerState<GenrePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingTracks = true;
  bool _isLoadingAlbums = true;
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _albums = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingTracks = true;
      _isLoadingAlbums = true;
    });

    // Load tracks
    try {
      final tracks = await EnhancedSpotifyService.searchTracks(
        'genre:${_getGenreQuery()}',
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      print('Error loading ${widget.genre} tracks: $e');
      if (mounted) {
        setState(() => _isLoadingTracks = false);
      }
    }

    // Load albums
    try {
      final albums = await EnhancedSpotifyService.searchAlbums(
        'genre:${_getGenreQuery()}',
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoadingAlbums = false;
        });
      }
    } catch (e) {
      print('Error loading ${widget.genre} albums: $e');
      if (mounted) {
        setState(() => _isLoadingAlbums = false);
      }
    }
  }

  String _getGenreQuery() {
    // Convert display name to Spotify genre query
    final genreMap = {
      'Pop': 'pop',
      'Rock': 'rock',
      'Hip Hop': 'hip-hop',
      'Electronic': 'electronic',
      'Jazz': 'jazz',
      'R&B': 'r-n-b',
      'Country': 'country',
      'Latin': 'latin',
      'Metal': 'metal',
      'Indie': 'indie',
      'Classical': 'classical',
    };
    return genreMap[widget.genre] ?? widget.genre.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        title: Text(widget.genre),
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF5E5E),
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          indicatorColor: const Color(0xFFFF5E5E),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tracks'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTracksTab(isDark),
          _buildAlbumsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildTracksTab(bool isDark) {
    if (_isLoadingTracks) {
      return const ListSkeleton(itemCount: 20);
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tracks found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tracks.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TrackCard(
            key: ValueKey(_tracks[index]['id']),
            track: _tracks[index],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumsTab(bool isDark) {
    if (_isLoadingAlbums) {
      return const GridSkeleton(itemCount: 20);
    }

    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album_outlined,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No albums found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _albums.length,
        itemBuilder: (context, index) => AlbumCard(
          key: ValueKey(_albums[index]['id']),
          album: _albums[index],
        ),
      ),
    );
  }
}
