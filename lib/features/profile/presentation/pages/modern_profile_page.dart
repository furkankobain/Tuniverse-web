import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/profile_service.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/services/music_player_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/services/playlist_service.dart';
import '../../../../shared/models/music_list.dart';
import 'package:flutter/services.dart';
import '../../../music/presentation/pages/track_detail_page.dart';
import '../../../music/presentation/pages/album_detail_page.dart';
import '../../../music/presentation/pages/artist_profile_page.dart';
import '../../../playlists/playlist_detail_page.dart';
import '../../../../core/localization/app_localizations.dart';

class ModernProfilePage extends StatefulWidget {
  const ModernProfilePage({super.key});

  @override
  State<ModernProfilePage> createState() => _ModernProfilePageState();
}

class _ModernProfilePageState extends State<ModernProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {};
  String? _bio;
  String? _displayName;
  String? _username;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    final stats = await ProfileService.getStats();
    final bio = await ProfileService.getBio();
    
    // Load user data from Firestore
    final currentUser = FirebaseService.auth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseService.firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          _displayName = data?['displayName'] as String?;
          _username = data?['username'] as String?;
          _profileImageUrl = data?['profileImageUrl'] as String?;
        }

        // Get real review count
        final reviewCount = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: currentUser.uid)
            .get()
            .then((snapshot) => snapshot.docs.length);
        
        stats['totalReviews'] = reviewCount;
      } catch (e) {
        print('Error loading user data: $e');
      }
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _bio = bio;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseService.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
            elevation: 0,
            title: Text(
              _username ?? _displayName ?? currentUser?.email?.split('@').first ?? AppLocalizations.of(context).t('profile'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                onPressed: () async {
                  final uid = FirebaseService.auth.currentUser?.uid;
                  if (uid == null) return;
                  final link = 'tuniverse://user/$uid';
                  await Clipboard.setData(ClipboardData(text: link));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil linki kopyalandı')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 24),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                          ),
                          child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        _getInitial(currentUser),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitial(currentUser),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              _stats['totalReviews']?.toString() ?? '0',
                              'Reviews',
                              isDark,
                            ),
                            _buildStatItem(
                              _stats['followers']?.toString() ?? '0',
                              AppLocalizations.of(context).t('followers'),
                              isDark,
                            ),
                            _buildStatItem(
                              _stats['following']?.toString() ?? '0',
                              AppLocalizations.of(context).t('following_count'),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Name & Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName ?? currentUser?.email?.split('@').first ?? 'User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (_username != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$_username',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                      if (_bio != null && _bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final result = await context.push('/edit-profile');
                        if (result == true) {
                          // Reload profile data after successful edit
                          _loadProfileData();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).t('edit_profile'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Now Playing / Last Played Card
                _buildNowPlayingCard(isDark),

                const SizedBox(height: 24),

                // Favorites Section (Letterboxd-style)
                _buildFavoritesSection(isDark),

                const SizedBox(height: 24),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    indicatorWeight: 2,
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: isDark ? Colors.grey[600] : Colors.grey[500],
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      const Tab(text: 'Reviews'),
                      Tab(text: AppLocalizations.of(context).t('playlists')),
                      Tab(text: AppLocalizations.of(context).t('activity')),
                      Tab(text: AppLocalizations.of(context).t('artists')),
                      Tab(text: AppLocalizations.of(context).t('liked_songs')),
                    ],
                  ),
                ),

                // Tab Content
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReviewsTab(isDark),
                      _buildPlaylistsTab(isDark),
                      _buildRecentActivity(isDark),
                      _buildTopArtists(isDark),
                      _buildFavoritesTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNowPlayingCard(bool isDark) {
    final currentTrack = MusicPlayerService.currentTrackName;
    final currentArtist = MusicPlayerService.currentArtistName;
    final isPlaying = MusicPlayerService.isPlaying;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Album Art Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPlaying ? Icons.music_note : Icons.history,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying ? 'Now Playing' : 'Last Played',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentTrack,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentArtist ?? 'Unknown Artist',
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
          if (isPlaying)
            Icon(
              Icons.play_circle_filled,
              color: AppTheme.primaryColor,
              size: 32,
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/favorites'),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2x2 Grid from real favorites
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FavoritesService.getAllFavorites(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final gridItems = items.take(4).toList();
              if (gridItems.isEmpty) {
                return Text(
                  'Henüz favori eklenmedi',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildFavoriteCard(gridItems[0], isDark)),
                      const SizedBox(width: 12),
                      if (gridItems.length > 1)
                        Expanded(child: _buildFavoriteCard(gridItems[1], isDark))
                      else
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (gridItems.length > 2)
                        Expanded(child: _buildFavoriteCard(gridItems[2], isDark))
                      else
                        const Expanded(child: SizedBox.shrink()),
                      const SizedBox(width: 12),
                      if (gridItems.length > 3)
                        Expanded(child: _buildFavoriteCard(gridItems[3], isDark))
                      else
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> item, bool isDark) {
    String type = (item['type'] ?? '') as String;
    String title = (item['name'] ?? '') as String;
    String subtitle = '';
    String? imageUrl;

    if (type == 'track') {
      final album = item['album'] as Map<String, dynamic>?;
      final images = album?['images'] as List?;
      imageUrl = images != null && images.isNotEmpty ? images.first['url'] as String? : null;
      final artists = item['artists'] as List?;
      subtitle = artists != null && artists.isNotEmpty ? artists.map((a) => a['name']).join(', ') : '';
    } else if (type == 'album') {
      final images = item['images'] as List?;
      imageUrl = images != null && images.isNotEmpty ? images.first['url'] as String? : null;
      final artists = item['artists'] as List?;
      subtitle = artists != null && artists.isNotEmpty ? artists.map((a) => a['name']).join(', ') : '';
    } else if (type == 'artist') {
      final images = item['images'] as List?;
      imageUrl = images != null && images.isNotEmpty ? images.first['url'] as String? : null;
      subtitle = 'Artist';
    }

    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: () {
          if (type == 'track') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackDetailPage(track: {
                  'id': item['id'],
                  'name': title,
                  'artists': item['artists'],
                  'album': item['album'],
                }),
              ),
            );
          } else if (type == 'album') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlbumDetailPage(album: item),
              ),
            );
          } else if (type == 'artist') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistProfilePage(artist: item),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                image: imageUrl != null
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            // Texts
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
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

  Widget _buildRecentActivity(bool isDark) {
    final currentUser = FirebaseService.auth.currentUser;
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please sign in to see activity',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activities')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline_outlined,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Activity Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring and sharing music!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final activity = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildActivityItem(activity, isDark);
          },
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isDark) {
    IconData icon;
    String subtitle;
    
    switch (activity['type']) {
      case 'listened':
        icon = Icons.play_circle_outline;
        subtitle = 'Listened to ${activity['title']} • ${activity['artist']}';
        break;
      case 'rated':
        icon = Icons.star;
        subtitle = 'Rated ${activity['title']} ${'⭐' * (activity['rating'] as int)}';
        break;
      case 'playlist':
        icon = Icons.playlist_play;
        subtitle = 'Created playlist: ${activity['title']}';
        break;
      default:
        icon = Icons.music_note;
        subtitle = activity['title'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtists(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FavoritesService.getAllFavorites().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        final artists = items.where((item) => item['type'] == 'artist').toList();

        if (artists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Favorite Artists',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your favorite artists to see them here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            final name = artist['name'] as String? ?? 'Unknown';
            final images = artist['images'] as List?;
            final imageUrl = images != null && images.isNotEmpty ? images.first['url'] as String? : null;
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistProfilePage(artist: artist),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                      shape: BoxShape.circle,
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Artist',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Reviews Tab - Show user's reviews
  Widget _buildReviewsTab(bool isDark) {
    final currentUser = FirebaseService.auth.currentUser;
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please sign in to see reviews',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Reviews Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start sharing your thoughts\nabout music you love!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final reviews = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final reviewDoc = reviews[index];
            final review = reviewDoc.data() as Map<String, dynamic>;
            return _buildReviewCard(review, reviewDoc.id, isDark);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, String reviewId, bool isDark) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final reviewText = (review['reviewText'] as String?) ?? '';
    final itemName = (review['itemName'] as String?) ?? 'Unknown';
    final itemType = (review['itemType'] as String?) ?? 'track';
    final mood = review['mood'] as String?;
    final tags = (review['tags'] as List?)?.cast<String>() ?? [];
    final gifUrl = review['gifUrl'] as String?;
    final itemImageUrl = review['itemImageUrl'] as String?;

    return GestureDetector(
      onTap: () {
        // Add review id to the map
        final reviewWithId = {...review, 'id': reviewId};
        context.push('/review/$reviewId', extra: reviewWithId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with item info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Item image
                if (itemImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: itemImageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E5E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              itemType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5E5E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rating stars
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: const Color(0xFFFF5E5E),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          // Mood
          if (mood != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4ECDC4), width: 1),
                ),
                child: Text(
                  mood,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
              ),
            ),
          
          // Review text
          if (reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                reviewText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // GIF
          if (gifUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  gifUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Tags
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
              ),
          ],
        ),
      ),
    );
  }

  // Playlists Tab - User's playlists
  Widget _buildPlaylistsTab(bool isDark) {
    final currentUser = FirebaseService.auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<MusicList>>(
      stream: PlaylistService.getUserPlaylists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final playlists = snapshot.data ?? [];
        if (playlists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Playlists Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create or import playlists\nfrom Spotify',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/playlists/user'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Create Playlist',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return _buildPlaylistCard(playlist, isDark);
          },
        );
      },
    );
  }

  Widget _buildPlaylistCard(MusicList playlist, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: playlist.coverImage != null
              ? CachedNetworkImage(
                  imageUrl: playlist.coverImage!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.music_note,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      size: 30,
                    ),
                  ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(
                    Icons.music_note,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    size: 30,
                  ),
                ),
        ),
        title: Text(
          playlist.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(
              playlist.source == 'spotify'
                  ? Icons.music_note
                  : playlist.source == 'local'
                      ? Icons.phone_android
                      : Icons.sync,
              size: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${playlist.trackIds.length} tracks',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailPage(playlist: playlist),
            ),
          );
        },
      ),
    );
  }

  // Favorites Tab - Grid of favorite items
  Widget _buildFavoritesTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FavoritesService.getAllFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Favorites Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding your favorite tracks,\nalbums, and artists!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildFavoriteCard(items[index], isDark);
          },
        );
      },
    );
  }

  String _getInitial(dynamic currentUser) {
    if (currentUser == null) return 'U';
    
    // Use Firestore displayName first, then fall back to auth displayName or email
    final name = _displayName ?? currentUser.displayName ?? currentUser.email ?? '';
    if (name.isEmpty) return 'U';
    
    return name.substring(0, 1).toUpperCase();
  }
}
