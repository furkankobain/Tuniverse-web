import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../player/presentation/pages/now_playing_animation_page.dart';
import '../../../reviews/presentation/pages/add_review_page.dart';
import 'artist_profile_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/services/profile_service.dart';
import '../../../../shared/services/rating_aggregation_service.dart';
import '../../../../shared/services/rating_cache_service.dart';
import '../../../../shared/services/lyrics_service.dart';
import '../../../../shared/services/apple_music_service.dart';
import '../../../../shared/services/music_player_service.dart';
import '../../../../shared/widgets/aggregated_rating_display.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/adaptive_banner_ad_widget.dart';
import '../widgets/track_recommendations_widget.dart';

class TrackDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> track;

  const TrackDetailPage({
    super.key,
    required this.track,
  });

  @override
  ConsumerState<TrackDetailPage> createState() => _TrackDetailPageState();
}

class _TrackDetailPageState extends ConsumerState<TrackDetailPage> {
  double _userRating = 0;
  bool _isFavorite = false;
  bool _isPinned = false;
  bool _isSavedToSpotify = false;
  bool _isCheckingSpotify = true;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoadingAudio = false;
  AggregatedRating? _aggregatedRating;
  bool _isLoadingRating = true;
  LyricsData? _lyricsData;
  bool _isLoadingLyrics = false;
  final TextEditingController _lyricsSearchController = TextEditingController();
  final ScrollController _lyricsScrollController = ScrollController();
  String _lyricsSearchQuery = '';
  List<int> _searchResultIndices = [];

  @override
  void initState() {
    super.initState();
    _checkSpotifyStatus();
    _checkFavoriteStatus();
    _checkPinnedStatus();
    _setupAudioPlayer();
    _loadAggregatedRating();
    _loadLyrics();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _lyricsSearchController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final trackId = widget.track['id'] as String?;
    if (trackId != null) {
      final isFav = await FavoritesService.isTrackFavorite(trackId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Future<void> _checkPinnedStatus() async {
    final trackId = widget.track['id'] as String?;
    if (trackId != null) {
      final isPinned = await ProfileService.isTrackPinned(trackId);
      if (mounted) {
        setState(() => _isPinned = isPinned);
      }
    }
  }

  Future<void> _loadAggregatedRating() async {
    final trackId = widget.track['id'] as String?;
    final trackName = widget.track['name'] as String?;
    final artistName = (widget.track['artists'] as List?)?.first?['name'] as String?;
    final popularity = widget.track['popularity'] as int?;

    if (trackId != null && trackName != null && artistName != null) {
      // Cache sistemi ile rating getir
      final rating = await RatingCacheService.getRatingWithCache(
        trackId: trackId,
        trackName: trackName,
        artistName: artistName,
        spotifyPopularity: popularity,
      );

      if (mounted) {
        setState(() {
          _aggregatedRating = rating;
          _isLoadingRating = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingRating = false);
      }
    }
  }

  Future<void> _loadLyrics() async {
    final trackName = widget.track['name'] as String?;
    final artistName = (widget.track['artists'] as List?)?.first?['name'] as String?;

    if (trackName != null && artistName != null) {
      setState(() => _isLoadingLyrics = true);

      try {
        final lyrics = await LyricsService.fetchLyrics(
          trackName: trackName,
          artistName: artistName,
        );

        if (mounted) {
          setState(() {
            _lyricsData = lyrics;
            _isLoadingLyrics = false;
          });
        }
      } catch (e) {
        print('Error loading lyrics: $e');
        if (mounted) {
          setState(() => _isLoadingLyrics = false);
        }
      }
    }
  }

  Future<void> _toggleFavorite() async {
    // First add/remove from favorites
    final success = await FavoritesService.toggleTrackFavorite(widget.track);
    
    if (success && mounted) {
      final newFavoriteStatus = !_isFavorite;
      setState(() => _isFavorite = newFavoriteStatus);
      
      // If adding to favorites, also add to pinned tracks (if not already pinned and space available)
      if (newFavoriteStatus) {
        final currentPinned = await ProfileService.getPinnedTracks();
        if (currentPinned.length < 4 && !_isPinned) {
          final pinSuccess = await ProfileService.addPinnedTrack(widget.track);
          if (pinSuccess && mounted) {
            setState(() => _isPinned = true);
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'Favorilere eklendi'
                : 'Favorilerden çıkarıldı',
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted && state == PlayerState.stopped) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _playPreview() async {
    try {
      String? previewUrl = widget.track['preview_url'] as String?;
      
      print('🎵 Play preview pressed for: ${widget.track['name']}');
      print('   Spotify Preview URL: $previewUrl');
      
      // If Spotify preview not available, try Apple Music
      if (previewUrl == null || previewUrl.isEmpty) {
        print('🍎 Spotify preview not available, trying Apple Music...');
        
        final trackName = widget.track['name'] as String? ?? 'Unknown Track';
        final artists = widget.track['artists'] as List?;
        final artistName = artists?.isNotEmpty == true
            ? artists!.first['name'] as String
            : 'Unknown Artist';
        
        previewUrl = await AppleMusicService.getTrackPreview(
          trackName: trackName,
          artistName: artistName,
        );
        
        if (previewUrl != null) {
          print('✅ Using Apple Music preview');
        }
      }
      
      if (previewUrl == null || previewUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preview not available for this track'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Use MusicPlayerService to show mini player
      final trackName = widget.track['name'] as String? ?? 'Unknown Track';
      final artists = widget.track['artists'] as List?;
      final artistNames = artists?.isNotEmpty == true
          ? artists!.map((a) => a['name'] as String).join(', ')
          : 'Unknown Artist';
      final album = widget.track['album'] as Map<String, dynamic>?;
      final images = album?['images'] as List?;
      final imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
      
      await MusicPlayerService.playTrack(
        trackId: widget.track['id'] as String,
        previewUrl: previewUrl,
        trackName: trackName,
        artistName: artistNames,
        imageUrl: imageUrl,
      );
      
      setState(() => _isPlaying = true);
    } catch (e) {
      print('Error playing preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkSpotifyStatus() async {
    final trackId = widget.track['id'] as String?;
    if (trackId != null && EnhancedSpotifyService.isConnected) {
      final isSaved = await EnhancedSpotifyService.checkSavedTrack(trackId);
      if (mounted) {
        setState(() {
          _isSavedToSpotify = isSaved;
          _isCheckingSpotify = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCheckingSpotify = false);
      }
    }
  }

  Future<void> _toggleSpotifySave() async {
    final trackId = widget.track['id'] as String?;
    if (trackId == null) return;

    if (!EnhancedSpotifyService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spotify hesabınıza bağlanmanız gerekiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCheckingSpotify = true);

    final success = _isSavedToSpotify
        ? await EnhancedSpotifyService.removeTrack(trackId)
        : await EnhancedSpotifyService.saveTrack(trackId);

    if (mounted) {
      setState(() {
        if (success) {
          _isSavedToSpotify = !_isSavedToSpotify;
        }
        _isCheckingSpotify = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (_isSavedToSpotify
                    ? 'Spotify beğenilen şarkılara eklendi'
                    : 'Spotify beğenilen şarkılardan çıkarıldı')
                : 'İşlem başarısız oldu',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = widget.track;
    
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;
    final artistNames = (track['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';
    final albumName = track['album']?['name'] ?? 'Unknown Album';
    final duration = track['duration_ms'] ?? 0;
    final popularity = track['popularity'] ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: _isFavorite ? ModernDesignSystem.accentYellow : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _openActionsSheet,
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
                    ModernDesignSystem.primaryGreen.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: CustomScrollView(
          slivers: [
            // Header with album art
            SliverToBoxAdapter(
              child: _buildHeader(imageUrl, isDark),
            ),
            
            // Track info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Track title
                    Text(
                      track['name'] ?? 'Unknown Track',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Artist name - clickable
                    GestureDetector(
                      onTap: () {
                        final artists = track['artists'] as List?;
                        if (artists != null && artists.isNotEmpty) {
                          final firstArtist = artists[0];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistProfilePage(artist: firstArtist),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            artistNames,
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Album name
                    Text(
                      albumName,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats row
                    _buildStatsRow(duration, popularity, isDark),
                    const SizedBox(height: 32),
                    
                    // Aggregated Rating
                    if (_isLoadingRating)
                      const Center(child: CircularProgressIndicator())
                    else if (_aggregatedRating != null)
                      AggregatedRatingDisplay(
                        rating: _aggregatedRating!,
                        showBreakdown: true,
                        showStats: true,
                        compact: false,
                      ),
                    const SizedBox(height: 24),
                    
                    // Rating section
                    _buildRatingSection(isDark),
                    const SizedBox(height: 32),
                    
                    // Play button
                    _buildPlayButton(isDark),
                    const SizedBox(height: 32),
                    
                    // Lyrics section
                    _buildLyricsSection(isDark),
                    const SizedBox(height: 32),
                    
                    // Information section
                    _buildInformationSection(track, isDark),
                    const SizedBox(height: 24),

                    // Top Reviews
                    _buildTopReviewsSection(isDark),
                    const SizedBox(height: 24),
                    
                    // Recommendations
                    TrackRecommendationsWidget(track: widget.track),
                    const SizedBox(height: 32),
                    
                    // Banner Ad
                    AdaptiveBannerAdWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildMiniPlayerBar(isDark),
    );
  }

  void _openActionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ModernDesignSystem.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Rate Track'),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToRating();
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review),
                title: const Text('Write a Review'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddReviewPage(
                        item: widget.track,
                        itemType: 'track',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to playlists tab or show a picker (future enhancement)
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () async {
                  Navigator.pop(context);
                  final link = widget.track['external_urls']?['spotify'] as String?;
                  if (link != null) {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link kopyalandı')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToRating() {
    // Optionally scroll to rating section; current layout already near top
  }

  Widget _buildMiniPlayerBar(bool isDark) {
    final track = widget.track;
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Album Cover
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey,
                        child: const Icon(Icons.music_note),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note),
                ),

              const SizedBox(width: 12),

              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (track['artists'] as List?)?.map((a) => a['name']).join(', ') ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Spotify Save Button
              if (_isCheckingSpotify)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: _isSavedToSpotify
                        ? ModernDesignSystem.primaryGreen.withValues(alpha: 0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSavedToSpotify ? Icons.favorite : Icons.favorite_border,
                      color: _isSavedToSpotify
                          ? ModernDesignSystem.primaryGreen
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 24,
                    ),
                    onPressed: _toggleSpotifySave,
                    tooltip: _isSavedToSpotify
                        ? 'Spotify beğenilenlerden çıkar'
                        : 'Spotify beğenilenlere ekle',
                  ),
                ),

              // Play Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: _isPlaying
                      ? LinearGradient(
                          colors: [
                            ModernDesignSystem.primaryGreen.withValues(alpha: 0.8),
                            ModernDesignSystem.secondaryGreen.withValues(alpha: 0.8),
                          ],
                        )
                      : ModernDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final previewUrl = track['preview_url'] as String?;
                      
                      if (previewUrl != null && previewUrl.isNotEmpty) {
                        // Play preview audio
                        if (_isPlaying) {
                          await _audioPlayer.stop();
                          setState(() => _isPlaying = false);
                        } else {
                          setState(() {
                            _isPlaying = true;
                            _isLoadingAudio = true;
                          });
                          
                          try {
                            await _audioPlayer.play(UrlSource(previewUrl));
                            setState(() => _isLoadingAudio = false);
                            
                            // Open full-screen now playing page
                            if (mounted) {
                              final artistsData = track['artists'] as List?;
                              final artistName = artistsData?.isNotEmpty == true
                                  ? artistsData!.first['name'] as String?
                                  : 'Unknown Artist';
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NowPlayingAnimationPage(
                                    track: {
                                      'name': track['name'] ?? 'Unknown Track',
                                      'artist': artistName,
                                      'albumArt': imageUrl,
                                      'previewUrl': previewUrl,
                                      'duration': 30, // 30 seconds preview
                                    },
                                  ),
                                ),
                              ).then((_) {
                                // When returning, check if still playing
                                if (_isPlaying) {
                                  _audioPlayer.stop();
                                  setState(() => _isPlaying = false);
                                }
                              });
                            }
                          } catch (e) {
                            print('Error playing preview: $e');
                            setState(() {
                              _isPlaying = false;
                              _isLoadingAudio = false;
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Önizleme çalınamadı'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      } else {
                        // No preview available, open in Spotify
                        final spotifyUrl = track['external_urls']?['spotify'] as String?;
                        if (spotifyUrl != null) {
                          final uri = Uri.parse(spotifyUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _isLoadingAudio
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? imageUrl, bool isDark) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (imageUrl != null)
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(
                      Icons.music_note,
                      size: 100,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              child: Icon(
                Icons.music_note,
                size: 100,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark ? Colors.black : Colors.white,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(Map<String, dynamic> track, bool isDark) {
    final releaseDate = track['album']?['release_date'] as String?;
    final label = track['album']?['label'] as String?;
    final duration = track['duration_ms'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isDark
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Release Date', releaseDate ?? '—', isDark),
          _infoRow('Duration', _formatDuration(duration), isDark),
          if (label != null) _infoRow('Label', label, isDark),
          TextButton(
            onPressed: () {
              final q = Uri.encodeComponent('${track['name']} lyrics');
              launchUrl(Uri.parse('https://www.google.com/search?q=$q'), mode: LaunchMode.externalApplication);
            },
            child: const Text('Open Lyrics on Web'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(title, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]))),
          Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int duration, int popularity, bool isDark) {
    return Row(
      children: [
        _buildStatItem(
          Icons.access_time_rounded,
          _formatDuration(duration),
          isDark,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          Icons.trending_up_rounded,
          '$popularity%',
          isDark,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          Icons.favorite_rounded,
          '1.2K',
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: ModernDesignSystem.primaryGreen,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTopReviewsSection(bool isDark) {
    final trackId = widget.track['id'] as String?;
    if (trackId == null) return const SizedBox.shrink();

    final query = FirebaseFirestore.instance
        .collection('reviews')
        .where('trackId', isEqualTo: trackId)
        .orderBy('createdAt', descending: true)
        .limit(25);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        // Map and sort by like signals
        final items = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        items.sort((a, b) {
          int likesA = (a['likeCount'] as int?) ?? (a['likes'] is List ? (a['likes'] as List).length : (a['likedBy'] is List ? (a['likedBy'] as List).length : 0));
          int likesB = (b['likeCount'] as int?) ?? (b['likes'] is List ? (b['likes'] as List).length : (b['likedBy'] is List ? (b['likedBy'] as List).length : 0));
          return likesB.compareTo(likesA);
        });
        final top3 = items.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddReviewPage(
                          item: widget.track,
                          itemType: 'track',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Write Review',
                    style: TextStyle(
                      color: Color(0xFFFF5E5E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...top3.map((r) => _reviewTileMap(r, isDark)),
            if (items.length > 3) ...[
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to full reviews page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full reviews page coming soon'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5E5E),
                    side: const BorderSide(color: Color(0xFFFF5E5E)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    'See All ${items.length} Reviews',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _reviewTileMap(Map<String, dynamic> review, bool isDark) {
    final rating = (review['rating'] as num?)?.toDouble();
    final text = (review['reviewText'] ?? review['note'] ?? '') as String?;
    int likes = (review['likeCount'] as int?) ?? (review['likes'] is List ? (review['likes'] as List).length : (review['likedBy'] is List ? (review['likedBy'] as List).length : 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(rating != null ? rating.toStringAsFixed(1) : '-', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              const Spacer(),
              Icon(Icons.thumb_up_alt_outlined, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 4),
              Text('$likes', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 6),
          if ((text ?? '').isNotEmpty)
            Text(text!, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRatingSection(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => AddReviewPage(
              item: widget.track,
              itemType: 'track',
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeIn),
              );

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: isDark
            ? ModernDesignSystem.darkGlassmorphism.copyWith(
                border: Border.all(
                  color: const Color(0xFFFF5E5E).withValues(alpha: 0.3),
                  width: 1,
                ),
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                boxShadow: ModernDesignSystem.mediumShadow,
                border: Border.all(
                  color: const Color(0xFFFF5E5E).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF5E5E).withValues(alpha: 0.2),
                    const Color(0xFFFF8C8C).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rate_review,
                color: Color(0xFFFF5E5E),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write a Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your thoughts about this track',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _playPreview,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                _isPlaying ? 'Pause Preview' : 'Play Preview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsSection(bool isDark) {
    return Container(
      decoration: isDark
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        initiallyExpanded: _lyricsData != null,
        title: Row(
          children: [
            Icon(
              Icons.lyrics,
              color: const Color(0xFFFF5E5E),
            ),
            const SizedBox(width: 12),
            Text(
              'Lyrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (_isLoadingLyrics) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildLyricsContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(bool isDark) {
    if (_isLoadingLyrics) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_lyricsData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lyrics not available',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadLyrics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF5E5E),
              side: const BorderSide(color: Color(0xFFFF5E5E)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source indicator
        Row(
          children: [
            Icon(
              Icons.verified,
              size: 16,
              color: ModernDesignSystem.primaryGreen,
            ),
            const SizedBox(width: 6),
            Text(
              'Source: ${_lyricsData!.source}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_lyricsData!.url != null)
              TextButton.icon(
                onPressed: () async {
                  final url = _lyricsData!.url;
                  if (url != null) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View Full'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5E5E),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Search bar
        TextField(
          controller: _lyricsSearchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Search in lyrics...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            suffixIcon: _lyricsSearchQuery.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchResultIndices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${_searchResultIndices.length} found',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _lyricsSearchController.clear();
                          setState(() {
                            _lyricsSearchQuery = '';
                            _searchResultIndices = [];
                          });
                        },
                      ),
                    ],
                  )
                : null,
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF5E5E),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _lyricsSearchQuery = value;
              if (value.isNotEmpty) {
                final lines = _lyricsData!.lyrics.split('\n');
                _searchResultIndices = [];
                for (var i = 0; i < lines.length; i++) {
                  if (lines[i].toLowerCase().contains(value.toLowerCase())) {
                    _searchResultIndices.add(i);
                  }
                }
              } else {
                _searchResultIndices = [];
              }
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Lyrics text with highlighting
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            controller: _lyricsScrollController,
            child: _buildHighlightedLyrics(isDark),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _loadLyrics,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                side: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yorumlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: isDark
              ? ModernDesignSystem.darkGlassmorphism
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                  boxShadow: ModernDesignSystem.mediumShadow,
                ),
          child: Text(
            'Henüz yorum yapılmamış. İlk yorumu siz yapın!',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildHighlightedLyrics(bool isDark) {
    if (_lyricsSearchQuery.isEmpty) {
      return Text(
        _lyricsData!.lyrics,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: isDark ? Colors.grey[300] : Colors.black87,
          fontFamily: 'monospace',
        ),
      );
    }

    final lines = _lyricsData!.lyrics.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        final isHighlighted = _searchResultIndices.contains(index);
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          color: isHighlighted
              ? const Color(0xFFFF5E5E).withOpacity(0.2)
              : Colors.transparent,
          child: Text(
            line.isEmpty ? ' ' : line,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isHighlighted
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[300] : Colors.black87),
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'monospace',
            ),
          ),
        );
      }).toList(),
    );
  }
}
