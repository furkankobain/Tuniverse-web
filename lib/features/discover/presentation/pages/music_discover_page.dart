import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/spotify_provider.dart';
import '../../../../shared/models/spotify_track.dart';
import '../../../../shared/models/spotify_album.dart';
import '../../../music/presentation/pages/track_detail_page.dart';
import '../../../music/presentation/pages/album_detail_page.dart';

class MusicDiscoverPage extends ConsumerStatefulWidget {
  const MusicDiscoverPage({super.key});

  @override
  ConsumerState<MusicDiscoverPage> createState() => _MusicDiscoverPageState();
}

class _MusicDiscoverPageState extends ConsumerState<MusicDiscoverPage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  String _selectedGenre = 'pop';
  final List<Map<String, dynamic>> _genres = [
    {'id': 'pop', 'name': 'Pop', 'emoji': '🎤'},
    {'id': 'rock', 'name': 'Rock', 'emoji': '🎸'},
    {'id': 'hip-hop', 'name': 'Hip Hop', 'emoji': '🎧'},
    {'id': 'electronic', 'name': 'Electronic', 'emoji': '🎹'},
    {'id': 'indie', 'name': 'Indie', 'emoji': '🎵'},
    {'id': 'jazz', 'name': 'Jazz', 'emoji': '🎺'},
    {'id': 'classical', 'name': 'Klasik', 'emoji': '🎻'},
    {'id': 'r-n-b', 'name': 'R&B', 'emoji': '💿'},
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingTracksProvider);
          ref.invalidate(newReleasesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Text(
                    '🔍',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Müzik Keşfet',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Genre Selector
            SliverToBoxAdapter(
              child: Container(
                height: 100,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    final isSelected = _selectedGenre == genre['id'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedGenre = genre['id']);
                      },
                      child: Container(
                        width: 80,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark ? Colors.grey[850] : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              genre['emoji'],
                              style: TextStyle(fontSize: 28),
                            ),
                            SizedBox(height: 4),
                            Text(
                              genre['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Trending Tracks
            SliverToBoxAdapter(
              child: _buildSectionHeader('Trend Şarkılar', '🔥', isDark),
            ),
            _buildTrendingTracks(isDark),

            SliverToBoxAdapter(child: SizedBox(height: 24)),

            // New Releases
            SliverToBoxAdapter(
              child: _buildSectionHeader('Yeni Çıkanlar', '✨', isDark),
            ),
            _buildNewReleases(isDark),

            SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Top Albums
            SliverToBoxAdapter(
              child: _buildSectionHeader('Popüler Albümler', '💿', isDark),
            ),
            _buildTopAlbums(isDark),

            SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTracks(bool isDark) {
    final tracksAsync = ref.watch(trendingTracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState('Trend şarkı bulunamadı', isDark),
          );
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: tracks.length > 10 ? 10 : tracks.length,
              itemBuilder: (context, index) {
                return _buildTrackCard(tracks[index], isDark);
              },
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: _buildLoadingIndicator(isDark),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState('Trend şarkılar yüklenemedi', isDark),
      ),
    );
  }

  Widget _buildNewReleases(bool isDark) {
    final albumsAsync = ref.watch(newReleasesProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState('Yeni albüm bulunamadı', isDark),
          );
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: albums.length > 10 ? 10 : albums.length,
              itemBuilder: (context, index) {
                return _buildAlbumCard(albums[index], isDark);
              },
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: _buildLoadingIndicator(isDark),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState('Yeni çıkanlar yüklenemedi', isDark),
      ),
    );
  }

  Widget _buildTopAlbums(bool isDark) {
    final albumsAsync = ref.watch(topAlbumsProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState('Popüler albüm bulunamadı', isDark),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildAlbumGridItem(albums[index], isDark);
              },
              childCount: albums.length > 6 ? 6 : albums.length,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: _buildLoadingIndicator(isDark),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState('Popüler albümler yüklenemedi', isDark),
      ),
    );
  }

  Widget _buildTrackCard(SpotifyTrack track, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackDetailPage(track: track),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                image: track.albumImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(track.albumImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: track.albumImageUrl == null
                  ? Icon(
                      Icons.music_note,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    )
                  : null,
            ),
            
            // Track Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      track.artists.join(', '),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(SpotifyAlbum album, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(albumId: album.id),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                image: album.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(album.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: album.imageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.album,
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    )
                  : null,
            ),
            
            // Album Info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    album.artists.join(', '),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumGridItem(SpotifyAlbum album, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(albumId: album.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  image: album.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(album.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: album.imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    album.artists.join(', '),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[300],
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
