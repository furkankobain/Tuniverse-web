import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _newReleases = [];
  List<Map<String, dynamic>> _topTracks = [];
  List<Map<String, dynamic>> _featured = [];
  List<Map<String, dynamic>> _categories = [];
  
  String _currentViewMode = 'grid';
  
  // Helper method for cleaner localization
  String t(BuildContext context, String key) => AppLocalizations.of(context).t(key);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        EnhancedSpotifyService.getNewReleases(limit: 20),
        EnhancedSpotifyService.getGlobalPopularTracks(limit: 20),
        EnhancedSpotifyService.getFeaturedPlaylists(limit: 10),
        EnhancedSpotifyService.getCategories(limit: 12),
      ]);

      if (mounted) {
        setState(() {
          _newReleases = results[0];
          _topTracks = results[1];
          _featured = results[2];
          _categories = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading discover data: $e');
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
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        title: _buildSearchBox(isDark),
        titleSpacing: 16,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildMusicTab(isDark),
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/discover-search'),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              t(context, 'search_placeholder'),
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Section
          _buildSectionHeader(t(context, 'trending'), isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTrendingBox(t(context, 'hot_new_releases'), Icons.local_fire_department, Colors.orange, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildTrendingBox(t(context, 'popular_this_week'), Icons.trending_up, Colors.green, isDark)),
            ],
          ),
          const SizedBox(height: 32),

          // Top Lists Section
          _buildSectionHeader(t(context, 'top_lists'), isDark),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildTopListBox(t(context, 'top_250_albums'), Icons.album, const Color(0xFFFF5E5E), isDark),
              _buildTopListBox(t(context, 'top_250_tracks'), Icons.music_note, const Color(0xFFFF5E5E), isDark),
              _buildTopListBox(t(context, 'top_250_artists'), Icons.person, const Color(0xFFFF5E5E), isDark),
              _buildTopListBox(t(context, 'most_popular_albums'), Icons.star, const Color(0xFFFF5E5E), isDark),
              _buildTopListBox(t(context, 'most_popular_artists'), Icons.people, const Color(0xFFFF5E5E), isDark),
              _buildTopListBox(t(context, 'most_popular_tracks'), Icons.headphones, const Color(0xFFFF5E5E), isDark),
            ],
          ),
          const SizedBox(height: 32),

          // For You Section
          _buildSectionHeader(t(context, 'for_you'), isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildForYouBox(t(context, 'recommended'), Icons.recommend, const Color(0xFFFF5E5E), isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildForYouBox(t(context, 'to_follow'), Icons.person_add, const Color(0xFFFF5E5E), isDark)),
            ],
          ),
          const SizedBox(height: 32),

          // Community Section
          _buildSectionHeader(t(context, 'community'), isDark),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildCommunityBox(t(context, 'trending_users'), Icons.trending_up, const Color(0xFFFF5E5E), isDark),
              _buildCommunityBox(t(context, 'explore_reviews'), Icons.rate_review, const Color(0xFFFF5E5E), isDark),
              _buildCommunityBox(t(context, 'explore_lists'), Icons.list, const Color(0xFFFF5E5E), isDark),
              _buildCommunityBox(t(context, 'lists_by_friends'), Icons.group, const Color(0xFFFF5E5E), isDark),
            ],
          ),
          const SizedBox(height: 32),

          // Genres Section
          _buildSectionHeader(t(context, 'genres'), isDark),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGenreChip('Pop', isDark),
              _buildGenreChip('Rock', isDark),
              _buildGenreChip('Hip Hop', isDark),
              _buildGenreChip('Electronic', isDark),
              _buildGenreChip('Jazz', isDark),
              _buildGenreChip('R&B', isDark),
              _buildGenreChip('Country', isDark),
              _buildGenreChip('Latin', isDark),
              _buildGenreChip('Metal', isDark),
              _buildGenreChip('Indie', isDark),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Reviews Tab - Coming Soon', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildListsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Lists Tab - Coming Soon', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Users Tab - Coming Soon', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildTrendingBox(String title, IconData icon, Color color, bool isDark) {
    return InkWell(
      onTap: () {
        if (title.contains('New Releases')) {
          context.push('/discover-section/new-releases/Hot New Releases');
        } else if (title.contains('Popular')) {
          context.push('/discover-section/popular/Popular This Week');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -20,
              top: -20,
              child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopListBox(String title, IconData icon, Color color, bool isDark) {
    return InkWell(
      onTap: () {
        if (title == 'Top 250 Albums') {
          context.push('/discover-section/top-albums/Top 250 Albums');
        } else if (title == 'Top 250 Tracks') {
          context.push('/discover-section/top-tracks/Top 250 Tracks');
        } else if (title == 'Top 250 Artists') {
          context.push('/discover-section/top-artists/Top 250 Artists');
        } else if (title == 'Most Popular Albums') {
          context.push('/discover-section/popular-albums/Most Popular Albums');
        } else if (title == 'Most Popular Artists') {
          context.push('/discover-section/popular-artists/Most Popular Artists');
        } else if (title == 'Most Popular Tracks') {
          context.push('/discover-section/popular-tracks/Most Popular Tracks');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? ModernDesignSystem.darkCard : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Stack(
          children: [
            // Background icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 60, color: color.withOpacity(0.1)),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouBox(String title, IconData icon, Color color, bool isDark) {
    return InkWell(
      onTap: () {
        if (title.contains('Recommended')) {
          context.push('/discover-section/recommended-albums/Recommended Albums');
        } else if (title.contains('Follow')) {
          context.push('/discover-section/recommended-users/Recommended To Follow');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? ModernDesignSystem.darkCard : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Icon(icon, size: 70, color: color.withOpacity(0.1)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityBox(String title, IconData icon, Color color, bool isDark) {
    return InkWell(
      onTap: () {
        if (title.contains('Trending Users')) {
          context.push('/discover-section/trending-users/Trending Users');
        } else if (title.contains('Reviews')) {
          context.push('/discover-section/reviews/Explore Reviews');
        } else if (title.contains('Explore Lists')) {
          context.push('/discover-section/playlists/Explore Lists');
        } else if (title.contains('Friends')) {
          context.push('/discover-section/friends-lists/Lists by Friends');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.6),
              color.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -15,
              bottom: -15,
              child: Icon(icon, size: 70, color: Colors.white.withOpacity(0.15)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre, bool isDark) {
    return InkWell(
      onTap: () => context.push('/genre/$genre'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF5E5E).withOpacity(0.3)),
        ),
        child: Text(genre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildNewReleasesTab(bool isDark) {
    if (_isLoading) {
      return _currentViewMode == 'grid'
          ? const GridSkeleton(itemCount: 20)
          : const ListSkeleton(itemCount: 20);
    }

    if (_newReleases.isEmpty) {
      return Center(
        child: Text(
          'No new releases found',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    if (_currentViewMode == 'grid') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 200,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _newReleases.length,
        itemBuilder: (context, index) => AlbumCard(
          key: ValueKey(_newReleases[index]['id']),
          album: _newReleases[index],
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 200,
        itemCount: _newReleases.length,
        itemBuilder: (context, index) {
          final album = _newReleases[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AlbumCard(
              key: ValueKey(album['id']),
              album: album,
            ),
          );
        },
      );
    }
  }

  Widget _buildTopTracksTab(bool isDark) {
    if (_isLoading) {
      return const ListSkeleton(itemCount: 20);
    }

    if (_topTracks.isEmpty) {
      return Center(
        child: Text(
          'No popular tracks found',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 200,
      itemCount: _topTracks.length,
      itemBuilder: (context, index) => TrackCard(
        key: ValueKey(_topTracks[index]['id']),
        track: _topTracks[index],
      ),
    );
  }

  Widget _buildFeaturedTab(bool isDark) {
    if (_isLoading) {
      return const GridSkeleton(itemCount: 10);
    }

    if (_featured.isEmpty) {
      return Center(
        child: Text(
          'No featured playlists found',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 200,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _featured.length,
      itemBuilder: (context, index) => AlbumCard(
        key: ValueKey(_featured[index]['id']),
        album: _featured[index],
      ),
    );
  }

  Widget _buildCategoriesTab(bool isDark) {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) => const AlbumCardSkeleton(),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Text(
          'Kategori bulunamadı',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 200,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final name = category['name'] ?? 'Unknown';
        final icons = category['icons'] as List?;
        final imageUrl = icons?.isNotEmpty == true ? icons![0]['url'] : null;

        return InkWell(
          onTap: () {
            // Navigate to category detail
          },
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          child: Container(
            decoration: BoxDecoration(
              gradient: _getCategoryGradient(index),
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(name),
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getCategoryGradient(int index) {
    final gradients = [
      ModernDesignSystem.primaryGradient,
      ModernDesignSystem.purpleGradient,
      ModernDesignSystem.blueGradient,
      ModernDesignSystem.sunsetGradient,
      ModernDesignSystem.modernGradient,
    ];
    return gradients[index % gradients.length];
  }

  IconData _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('rock')) return Icons.music_note;
    if (nameLower.contains('pop')) return Icons.star;
    if (nameLower.contains('jazz')) return Icons.piano;
    if (nameLower.contains('hip')) return Icons.mic;
    if (nameLower.contains('electronic')) return Icons.equalizer;
    if (nameLower.contains('classical')) return Icons.music_video;
    if (nameLower.contains('country')) return Icons.landscape;
    if (nameLower.contains('latin')) return Icons.celebration;
    if (nameLower.contains('metal')) return Icons.bolt;
    if (nameLower.contains('indie')) return Icons.headphones;
    return Icons.music_note;
  }
}
