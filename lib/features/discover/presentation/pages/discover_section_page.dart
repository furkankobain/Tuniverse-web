import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';

class DiscoverSectionPage extends ConsumerStatefulWidget {
  final String title;
  final String sectionType; // 'new-releases', 'popular', 'top-albums', etc.
  
  const DiscoverSectionPage({
    super.key,
    required this.title,
    required this.sectionType,
  });

  @override
  ConsumerState<DiscoverSectionPage> createState() => _DiscoverSectionPageState();
}

class _DiscoverSectionPageState extends ConsumerState<DiscoverSectionPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> data = [];

      switch (widget.sectionType) {
        case 'new-releases':
          // Hot new releases from the last week
          data = await EnhancedSpotifyService.getNewReleases(limit: 50);
          break;
        case 'popular':
          // Popular tracks this week (from global playlists)
          data = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 50);
          break;
        case 'top-albums':
          // Top rated albums (mix of classic + recent highly rated)
          final classics = await EnhancedSpotifyService.searchAlbums('Pink Floyd');
          final recent = await EnhancedSpotifyService.getNewReleases(limit: 30);
          data = [...classics.take(20), ...recent.take(30)].toList();
          break;
        case 'top-tracks':
          // Legendary tracks (search for iconic artists)
          final legendary1 = await EnhancedSpotifyService.searchTracks('Queen Bohemian Rhapsody');
          final legendary2 = await EnhancedSpotifyService.searchTracks('The Beatles');
          final popular = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 30);
          data = [...legendary1.take(5), ...legendary2.take(5), ...popular.take(40)].toList();
          break;
        case 'top-artists':
          // Top artists (search multiple legendary artists)
          final artists1 = await EnhancedSpotifyService.searchArtists('Michael Jackson');
          final artists2 = await EnhancedSpotifyService.searchArtists('Madonna');
          final artists3 = await EnhancedSpotifyService.searchArtists('Drake');
          data = [...artists1.take(1), ...artists2.take(1), ...artists3.take(1)].toList();
          break;
        case 'popular-albums':
          // Currently popular albums (different from top)
          final featured = await EnhancedSpotifyService.getFeaturedPlaylists(limit: 10);
          final newReleases = await EnhancedSpotifyService.getNewReleases(limit: 40);
          data = [...featured.take(10), ...newReleases.take(40)].toList();
          break;
        case 'popular-artists':
          // Currently trending artists
          final trending1 = await EnhancedSpotifyService.searchArtists('Taylor Swift');
          final trending2 = await EnhancedSpotifyService.searchArtists('Bad Bunny');
          final trending3 = await EnhancedSpotifyService.searchArtists('The Weeknd');
          data = [...trending1.take(1), ...trending2.take(1), ...trending3.take(1)].toList();
          break;
        case 'popular-tracks':
          // Different set of popular tracks (chart hits)
          final hits1 = await EnhancedSpotifyService.searchTracks('viral hits 2024');
          final hits2 = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 40);
          data = [...hits1.take(10), ...hits2.take(40)].toList();
          break;
        case 'recommended-albums':
          // Personalized recommendations (use categories)
          final categories = await EnhancedSpotifyService.getCategories(limit: 5);
          if (categories.isNotEmpty) {
            final playlists = await EnhancedSpotifyService.getFeaturedPlaylists(limit: 20);
            data = playlists;
          } else {
            data = await EnhancedSpotifyService.getNewReleases(limit: 20);
          }
          break;
        case 'recommended-users':
          data = []; // TODO: Implement from Firestore users with most followers
          break;
        case 'trending-users':
          data = []; // TODO: Implement from Firestore recent active users
          break;
        case 'reviews':
          data = []; // TODO: Implement from Firestore recent reviews
          break;
        case 'playlists':
          // All public playlists
          data = await EnhancedSpotifyService.getFeaturedPlaylists(limit: 50);
          break;
        case 'friends-lists':
          data = []; // TODO: Implement from Firestore user's friends' playlists
          break;
        default:
          data = [];
      }

      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ${widget.sectionType}: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const GridSkeleton(itemCount: 20)
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(isDark),
                ),
    );
  }

  Widget _buildContent(bool isDark) {
    // Determine if items are tracks or albums based on type
    final isTrackList = widget.sectionType.contains('track') || widget.sectionType == 'popular';
    
    if (isTrackList) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TrackCard(
            key: ValueKey(_items[index]['id']),
            track: _items[index],
          ),
        ),
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) => AlbumCard(
          key: ValueKey(_items[index]['id']),
          album: _items[index],
        ),
      );
    }
  }
}
