import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/lastfm_service.dart';

class TrackRecommendationsWidget extends StatefulWidget {
  final Map<String, dynamic> track;

  const TrackRecommendationsWidget({
    super.key,
    required this.track,
  });

  @override
  State<TrackRecommendationsWidget> createState() => _TrackRecommendationsWidgetState();
}

class _TrackRecommendationsWidgetState extends State<TrackRecommendationsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _similarTracks = [];
  List<Map<String, dynamic>> _spotifyRecommendations = [];
  bool _isLoadingSimilar = true;
  bool _isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    // Load Last.fm similar tracks
    _loadSimilarTracks();
    
    // Load Spotify recommendations
    _loadSpotifyRecommendations();
  }

  Future<void> _loadSimilarTracks() async {
    final trackName = widget.track['name'] as String?;
    final artistName = (widget.track['artists'] as List?)?.first?['name'] as String?;

    if (trackName != null && artistName != null) {
      final similar = await LastFmService.getSimilarTracks(
        artist: artistName,
        track: trackName,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _similarTracks = similar;
          _isLoadingSimilar = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingSimilar = false);
      }
    }
  }

  Future<void> _loadSpotifyRecommendations() async {
    final trackId = widget.track['id'] as String?;
    final artistId = (widget.track['artists'] as List?)?.first?['id'] as String?;

    if (trackId != null) {
      final recommendations = await EnhancedSpotifyService.getTrackRecommendations(
        seedTrackId: trackId,
        seedArtistId: artistId,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _spotifyRecommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.explore,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Discovery',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Similar Tracks'),
              Tab(text: 'Recommendations'),
            ],
          ),

          // Tab Content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSimilarTracks(isDark),
                _buildSpotifyRecommendations(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarTracks(bool isDark) {
    if (_isLoadingSimilar) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_similarTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No similar tracks found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _similarTracks.length,
      itemBuilder: (context, index) {
        final track = _similarTracks[index];
        return _buildTrackItem(track, isDark, isLastFm: true);
      },
    );
  }

  Widget _buildSpotifyRecommendations(bool isDark) {
    if (_isLoadingRecommendations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_spotifyRecommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No recommendations found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _spotifyRecommendations.length,
      itemBuilder: (context, index) {
        final track = _spotifyRecommendations[index];
        return _buildTrackItem(track, isDark, isLastFm: false);
      },
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, bool isDark, {required bool isLastFm}) {
    final trackName = isLastFm ? track['name'] : track['name'];
    final artistName = isLastFm ? track['artist'] : (track['artists'] as List?)?.first?['name'];
    // Get proper image URL - for Last.fm, use the largest image
    String? imageUrl;
    if (isLastFm) {
      final imageData = track['image'];
      if (imageData is List && imageData.isNotEmpty) {
        // Last.fm returns images in different sizes, get the largest (extralarge)
        final largeImage = imageData.firstWhere(
          (img) => img['size'] == 'extralarge' || img['size'] == 'large',
          orElse: () => imageData.last,
        );
        imageUrl = largeImage['#text'] as String?;
        if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;
      } else if (imageData is String && imageData.isNotEmpty) {
        imageUrl = imageData;
      }
    } else {
      final albumImages = track['album']?['images'] as List?;
      imageUrl = (albumImages != null && albumImages.isNotEmpty) 
          ? albumImages.first['url'] as String?
          : null;
    }
    final matchScore = isLastFm ? track['match'] : null;

    return InkWell(
      onTap: () {
        if (!isLastFm) {
          // Navigate to track detail for Spotify tracks
          context.push('/track-detail', extra: track);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(
                      Icons.music_note,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackName ?? 'Unknown Track',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistName ?? 'Unknown Artist',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Match Score (Last.fm only)
            if (matchScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(matchScore * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            // Play button (Spotify only)
            if (!isLastFm)
              IconButton(
                icon: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  final previewUrl = track['preview_url'] as String?;
                  if (previewUrl != null && previewUrl.isNotEmpty) {
                    // Navigate to track detail which has play functionality
                    context.push('/track-detail', extra: track);
                  } else {
                    // No preview, open track detail anyway
                    context.push('/track-detail', extra: track);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
