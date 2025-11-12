import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';

class AlbumsPage extends ConsumerStatefulWidget {
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends ConsumerState<AlbumsPage> {
  List<Map<String, dynamic>> _turkeyAlbums = [];
  List<Map<String, dynamic>> _globalAlbums = [];
  bool _isLoadingTurkey = true;
  bool _isLoadingGlobal = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load Turkey albums
    if (mounted) {
      setState(() => _isLoadingTurkey = true);
    }
    try {
      final albums = await EnhancedSpotifyService.getTurkeyTopAlbums(limit: 20);
      if (mounted) {
        setState(() {
          _turkeyAlbums = albums;
          _isLoadingTurkey = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTurkey = false);
      }
    }

    // Load Global albums
    if (mounted) {
      setState(() => _isLoadingGlobal = true);
    }
    try {
      final albums = await EnhancedSpotifyService.getGlobalTopAlbums(limit: 20);
      if (mounted) {
        setState(() {
          _globalAlbums = albums;
          _isLoadingGlobal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGlobal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Türkiye'de Popüler
              _buildSectionHeader(
                context,
                '🇹🇷 Türkiye\'de Popüler',
                isDark,
                onSeeAll: () {
                  // TODO: Navigate to full list
                },
              ),
              const SizedBox(height: 12),
              _buildTurkeyAlbumsList(isDark),
              
              const SizedBox(height: 32),
              
              // Global Popüler Albümler
              _buildSectionHeader(
                context,
                '🌍 Global Popüler',
                isDark,
                onSeeAll: () {
                  context.push('/global-top-albums');
                },
              ),
              const SizedBox(height: 12),
              _buildGlobalAlbumsList(isDark),
              
              const SizedBox(height: 32),
              
              // Arkadaşlarımın Listeleri
              _buildSectionHeader(
                context,
                '👥 Arkadaşlarımın Listeleri',
                isDark,
                onSeeAll: () {
                  context.push('/lists');
                },
              ),
              const SizedBox(height: 12),
              _buildFriendsList(isDark),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDark, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurkeyAlbumsList(bool isDark) {
    if (_isLoadingTurkey) {
      return SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final albums = _turkeyAlbums.take(10).toList();

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          final artistName = (album['artists'] as List?)?.isNotEmpty == true
              ? album['artists'][0]['name']
              : 'Unknown Artist';
          final imageUrl = (album['images'] as List?)?.isNotEmpty == true
              ? album['images'][0]['url']
              : null;

          return _buildAlbumCard(
            album['name'] ?? 'Unknown Album',
            artistName,
            isDark,
            rankBadge: '${index + 1}',
            rating: 4.5 - (index * 0.05),
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  Widget _buildGlobalAlbumsList(bool isDark) {
    if (_isLoadingGlobal) {
      return SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final albums = _globalAlbums.take(10).toList();

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          final artistName = (album['artists'] as List?)?.isNotEmpty == true
              ? album['artists'][0]['name']
              : 'Unknown Artist';
          final imageUrl = (album['images'] as List?)?.isNotEmpty == true
              ? album['images'][0]['url']
              : null;

          return _buildAlbumCard(
            album['name'] ?? 'Unknown Album',
            artistName,
            isDark,
            rankBadge: '${index + 1}',
            rating: 4.5 - (index * 0.05),
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  Widget _buildFriendsList(bool isDark) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildFriendListCard(
            'Kullanıcı ${index + 1}',
            'Favorilerim ${index + 1}',
            15 + index * 3,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildAlbumCard(
    String title,
    String artist,
    bool isDark, {
    String? rankBadge,
    double rating = 4.5,
    String? imageUrl,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Albüm Kapağı ve Rank Badge
          Stack(
            children: [
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Icon(
                        Icons.album,
                        size: 60,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )
                    : null,
              ),
              if (rankBadge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      rankBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
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
            artist,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.favorite,
                size: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '${(rating * 100).toInt()}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendListCard(
    String username,
    String listName,
    int songCount,
    bool isDark,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Albüm Grid (4 albüm kapağı)
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.all(1),
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.music_note,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      size: 32,
                    ),
                  );
                }),
              ),
            ),
          ),
          // Liste Bilgisi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Text(
                        username[0].toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$songCount şarkı',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${songCount * 2}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
