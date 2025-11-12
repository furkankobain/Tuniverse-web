import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../reviews/presentation/pages/reviews_page.dart';
import '../../../albums/presentation/pages/albums_page.dart';
import '../../../discover/presentation/pages/enhanced_discover_page.dart';
import '../../../../shared/widgets/spotify/spotify_connect_button.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/spotify_service.dart';
import '../../../../shared/models/play_history.dart';
import '../../../../shared/widgets/weekly_stats_card.dart';
import '../../../../shared/widgets/daily_challenge_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/adaptive_banner_ad_widget.dart';

class MusicShareHomePage extends ConsumerStatefulWidget {
  const MusicShareHomePage({super.key});

  @override
  ConsumerState<MusicShareHomePage> createState() => _MusicShareHomePageState();
}

class _MusicShareHomePageState extends ConsumerState<MusicShareHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _globalNewReleases = [];
  List<Map<String, dynamic>> _globalPopularTracks = [];
  List<PlayHistory> _recentlyPlayed = [];
  bool _isLoadingNewReleases = true;
  bool _isLoadingPopular = true;
  bool _isLoadingRecent = true;
  String _releasesViewMode = 'new'; // 'popular' or 'new'
  String _timelineViewMode = 'popular'; // 'popular' or 'friends'
  String? _userPhotoUrl;
  List<Map<String, dynamic>> _socialFeed = [];
  bool _isLoadingFeed = true;
  String? _userCountry; // User's Spotify country for content localization

  final List<String> _tabs = ['Popular This Week', 'New Releases', 'Discover', 'Profile'];
  
  // Helper method for cleaner localization
  String t(BuildContext context, String key) => AppLocalizations.of(context).t(key);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadGlobalData();
    _loadUserPhoto();
  }

  Future<void> _loadUserPhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userPhotoUrl = doc.data()?['profileImageUrl'] ?? doc.data()?['photoURL'];
            _userCountry = doc.data()?['spotifyCountry'] as String?;
          });
          print('🌍 User country: $_userCountry');
        }
      }
    } catch (e) {
      print('Error loading user photo: $e');
    }
  }

  Future<void> _loadGlobalData() async {
    // Load social feed
    _loadSocialFeed();
    
    // Determine market based on user's country
    // If user is from Turkey, use TR market, otherwise use US (global)
    final market = (_userCountry == 'TR') ? 'TR' : 'US';
    print('🎵 Loading content for market: $market');
    
    // Load Global New Release Tracks (not albums)
    if (mounted) {
      setState(() => _isLoadingNewReleases = true);
    }
    try {
      final tracks = await EnhancedSpotifyService.getGlobalNewReleaseTracks(
        limit: 50,
        market: market,
      );
      if (mounted) {
        setState(() {
          _globalNewReleases = tracks;
          _isLoadingNewReleases = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNewReleases = false);
      }
      print('Error loading new releases: $e');
    }
    
    // Load Global Popular Tracks
    if (mounted) {
      setState(() => _isLoadingPopular = true);
    }
    try {
      final tracks = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 50);
      if (mounted) {
        setState(() {
          _globalPopularTracks = tracks;
          _isLoadingPopular = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPopular = false);
      }
      print('Error loading popular tracks: $e');
    }

    // Load recently played
    if (mounted) {
      setState(() => _isLoadingRecent = true);
    }
    try {
      final tracks = await SpotifyService.getRecentlyPlayed(limit: 10);
      if (mounted) {
        setState(() {
          _recentlyPlayed = tracks.map((track) => PlayHistory.fromSpotify(track)).toList();
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  Future<void> _handleFeedLike(Map<String, dynamic> review) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(review['id']);
      
      final likedBy = List<String>.from(review['likedBy'] ?? []);
      final hasLiked = likedBy.contains(currentUser.uid);

      if (hasLiked) {
        await reviewRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        await reviewRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      // Refresh feed
      _loadSocialFeed();
    } catch (e) {
      print('Error liking review: $e');
    }
  }

  Future<void> _showFeedCommentSheet(Map<String, dynamic> review) async {
    final controller = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Row(
                    children: [
                      Text(
                        t(context, 'add_comment'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: t(context, 'write_comment'),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isNotEmpty) {
                        await _addFeedComment(review['id'], controller.text.trim());
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t(context, 'post_comment'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addFeedComment(String reviewId, String comment) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .collection('comments')
          .add({
        'userId': currentUser.uid,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(context, 'comment_added')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<void> _loadSocialFeed() async {
    if (mounted) {
      setState(() => _isLoadingFeed = true);
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      final feedItems = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          // Load user data
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['userId'])
              .get();
          
          return {
            'id': doc.id,
            'userId': data['userId'],
            'userName': userDoc.data()?['username'] ?? 'Unknown User',
            'userPhoto': userDoc.data()?['profileImageUrl'] ?? userDoc.data()?['photoURL'],
            'trackName': data['trackName'],
            'artistName': data['artistName'],
            'albumArt': data['albumArt'],
            'rating': data['rating'] ?? 0,
            'reviewText': data['reviewText'] ?? '',
            'likes': data['likes'] ?? 0,
            'likedBy': List<String>.from(data['likedBy'] ?? []),
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList(),
      );
      
      if (mounted) {
        setState(() {
          _socialFeed = feedItems;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      print('Error loading social feed: $e');
      if (mounted) {
        setState(() => _isLoadingFeed = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              title: const Text(
                'TUNIVERSE',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 32,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFFF5E5E),
                  height: 1,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_active),
                  tooltip: 'Activity',
                  onPressed: () => context.push('/activity'),
                ),
                // Golden app icon with subtle sparkle
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 3000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return IconButton(
                        icon: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFE55C).withOpacity(0.9 + 0.1 * value),
                              Color(0xFFFFD700),
                            ],
                            stops: [
                              0.0,
                              value,
                              1.0,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Image.asset(
                            'assets/images/logos/app_icon.png',
                            width: 32,
                            height: 32,
                            color: Colors.white,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.music_note,
                                color: Color(0xFFFFD700),
                                size: 32,
                              );
                            },
                          ),
                        ),
                        tooltip: 'More Features',
                        onPressed: () => context.push('/more'),
                        padding: EdgeInsets.zero,
                      );
                    },
                    onEnd: () {
                      // Restart animation
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
            // Tab Bar removed - no tabs needed for main content
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadGlobalData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // What have you been listening to?
                GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to home with profile tab
                            context.go('/profile-tab');
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(25),
                              image: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_userPhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _userPhotoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t(context, 'search_placeholder'),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Hot New Releases Section
                _buildHotNewReleasesSection(isDark),
                const SizedBox(height: 32),

                // Recently Played Section
                _buildSectionHeader(t(context, 'recently_played'), isDark, onSeeAll: () => context.push('/recently-played')),
                const SizedBox(height: 16),
                _buildRecentlyPlayedSection(isDark),
                const SizedBox(height: 32),

                // Trending Section
                _buildSectionHeader(t(context, 'trending_this_week'), isDark),
                const SizedBox(height: 16),
                _buildTrendingSection(isDark),
                const SizedBox(height: 32),
                
                // Social Feed Section
                _buildSocialFeedSection(isDark),
                const SizedBox(height: 32),

                // Quick Actions
                _buildQuickActionsSection(isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HOT NEW RELEASES SECTION
  Widget _buildHotNewReleasesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _releasesViewMode == 'new' ? t(context, 'global_new_releases') : t(context, 'popular_worldwide'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _releasesViewMode = 'popular'),
                  child: Text(
                    t(context, 'popular_new_toggle'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _releasesViewMode == 'popular'
                          ? const Color(0xFFFF5E5E)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('/', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _releasesViewMode = 'new'),
                  child: Text(
                    t(context, 'new_toggle'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _releasesViewMode == 'new'
                          ? const Color(0xFFFF5E5E)
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPopularSongsSection(isDark),
      ],
    );
  }
  
  // TIMELINE SECTION
  Widget _buildTimelineSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _timelineViewMode = 'popular'),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _timelineViewMode == 'popular'
                          ? const Color(0xFFFF5E5E)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('/', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _timelineViewMode = 'friends'),
                  child: Text(
                    'FRIENDS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _timelineViewMode == 'friends'
                          ? const Color(0xFFFF5E5E)
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimelineContent(isDark),
      ],
    );
  }
  
  // TIMELINE CONTENT
  Widget _buildTimelineContent(bool isDark) {
    // Mock timeline posts
    final posts = [
      {
        'title': 'Thriller',
        'artist': 'Michael Jackson',
        'albumType': 'Album',
        'review': 'Why Michael Jackson will always be the GOAT!!!',
        'rating': 5.0,
        'reviewBody':
            'I know this review is out a month before its next anniversary, but let me cook. Back in middle school, I was really obsessed with Michael Jackson.',
      },
    ];
    
    return Column(
      children: [
        for (var post in posts)
          _buildTimelinePost(post, isDark),
      ],
    );
  }
  
  // TIMELINE POST CARD
  Widget _buildTimelinePost(Map<String, dynamic> post, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album info with play button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post['artist']} • ${post['albumType']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Review title
          Text(
            post['review'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Rating
          Row(
            children: [
              for (int i = 0; i < 5; i++)
                const Icon(Icons.star, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Review body
          Text(
            post['reviewBody'] ?? '',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Quick Actions Widget
  Widget _buildQuickActionsWidget(bool isDark) {
    final actions = [
      {
        'icon': Icons.emoji_events,
        'label': 'Achievements',
        'color': Colors.amber,
        'route': '/achievements',
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'Streaks',
        'color': Colors.deepOrange,
        'route': '/streaks',
      },
      {
        'icon': Icons.psychology,
        'label': 'Analytics',
        'color': Colors.purple,
        'route': '/taste-profile',
      },
      {
        'icon': Icons.quiz,
        'label': 'Music Quiz',
        'color': Colors.blue,
        'route': '/music-quiz',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: actions.map((action) {
            return GestureDetector(
              onTap: () => context.push(action['route'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[850] : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title, bool isDark, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t(context, 'view_all'),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Global Tracks Section (New Releases or Popular)
  Widget _buildPopularSongsSection(bool isDark) {
    final isLoading = _releasesViewMode == 'new' ? _isLoadingNewReleases : _isLoadingPopular;
    final dataToShow = _releasesViewMode == 'new' ? _globalNewReleases : _globalPopularTracks;
    
    if (isLoading) {
      return const HorizontalScrollSkeleton(
        height: 220,
        itemCount: 5,
      );
    }

    final tracksToShow = dataToShow.take(10).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracksToShow.length,
        itemBuilder: (context, index) {
          final item = tracksToShow[index];
          
          // Handle both tracks and albums (new releases are albums)
          if (_releasesViewMode == 'new') {
            // New Releases - these are tracks, so we need album.images
            final artistName = (item['artists'] as List?)?.isNotEmpty == true
                ? item['artists'][0]['name']
                : 'Unknown Artist';
            final imageUrl = (item['album']?['images'] as List?)?.isNotEmpty == true
                ? item['album']['images'][0]['url']
                : null;
            
            return _buildAlbumCard(
              item['name'] ?? 'Unknown Album',
              artistName,
              isDark,
              imageUrl: imageUrl,
              onTap: () {
                context.push('/album-detail', extra: item);
              },
            );
          } else {
            // Tracks
            final artistName = (item['artists'] as List?)?.isNotEmpty == true
                ? item['artists'][0]['name']
                : 'Unknown Artist';
            final imageUrl = (item['album']?['images'] as List?)?.isNotEmpty == true
                ? item['album']['images'][0]['url']
                : null;
            
            return _buildSongCard(
              item,
              item['name'] ?? 'Unknown Track',
              artistName,
              isDark,
              imageUrl: imageUrl,
            );
          }
        },
      ),
    );
  }

  // Takip Edilen Kişilerin Aktiviteleri
  Widget _buildFollowingActivitiesSection(bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildActivityCard(
            'Kullanıcı ${index + 1}',
            'Şarkı dinledi',
            'Şarkı Adı - Sanatçı',
            isDark,
          );
        },
      ),
    );
  }

  // Popular Albums Section (not used anymore, keeping for reference)
  Widget _buildPopularAlbumsSection(bool isDark) {
    if (_isLoadingNewReleases) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final albumsToShow = _globalNewReleases.take(10).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albumsToShow.length,
        itemBuilder: (context, index) {
          final album = albumsToShow[index];
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
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  // Şarkı Kartı
  Widget _buildSongCard(Map<String, dynamic> track, String title, String artist, bool isDark, {String? imageUrl}) {
    return GestureDetector(
      onTap: () {
        context.push('/track-detail', extra: track);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kapak
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(
                    Icons.music_note,
                    size: 50,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
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
        ],
        ),
      ),
    );
  }

  // Son Dinlenenler Bölümü
  Widget _buildRecentlyPlayedSection(bool isDark) {
    if (_isLoadingRecent) {
      return const HorizontalScrollSkeleton(
        height: 120,
        itemCount: 3,
      );
    }

    if (_recentlyPlayed.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 40,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                t(context, 'connect_spotify_history'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recentlyPlayed.length,
        itemBuilder: (context, index) {
          final track = _recentlyPlayed[index];
          return _buildRecentlyPlayedCard(track, isDark);
        },
      ),
    );
  }

  // Son Dinlenenler Kartı
  Widget _buildRecentlyPlayedCard(PlayHistory track, bool isDark) {
    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // Fetch full track details from Spotify
          final fullTrackData = await EnhancedSpotifyService.getTrackDetails(track.trackId);
          
          if (mounted) {
            // Close loading dialog
            Navigator.of(context).pop();
            
            if (fullTrackData != null) {
              // Navigate with full track data
              context.push('/track-detail', extra: fullTrackData);
            } else {
              // Show error if track data couldn't be loaded
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t(context, 'could_not_load_track')),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Album Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.albumImageUrl != null
                  ? Image.network(
                      track.albumImageUrl!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderCover(isDark),
                    )
                  : _buildPlaceholderCover(isDark),
            ),
            const SizedBox(width: 12),
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.trackName,
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
                    track.artistName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        track.relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${track.formattedDuration}',
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
      ),
    );
  }

  Widget _buildPlaceholderCover(bool isDark) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        size: 32,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
    );
  }

  // Aktivite Kartı
  Widget _buildActivityCard(String username, String action, String content, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      action,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(width: 12),
              Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  // Hero Section
  Widget _buildHeroSection(bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E5E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.music_note,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Trending Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover what\'s hot this week',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/discover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF5E5E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 16),
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

  // Albüm Kartı
  Widget _buildAlbumCard(String title, String artist, bool isDark, {String? imageUrl, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
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
                    size: 50,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '4.5',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  // Trending Section
  Widget _buildTrendingSection(bool isDark) {
    // Use popular tracks data for trending
    final trendingItems = _globalPopularTracks.take(5).toList();
    
    if (trendingItems.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: trendingItems.asMap().entries.map((entry) {
        final index = entry.key;
        final track = entry.value;
        final artistName = (track['artists'] as List?)?.isNotEmpty == true
            ? track['artists'][0]['name']
            : 'Unknown Artist';
        final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
            ? track['album']['images'][0]['url']
            : null;

        return GestureDetector(
          onTap: () => context.push('/track-detail', extra: track),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: index == 0
                          ? [Colors.amber, Colors.orange]
                          : [const Color(0xFFFF5E5E), const Color(0xFFFF8E8E)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Cover
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
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
                        track['name'] ?? 'Unknown Track',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artistName,
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
                // Play button
                IconButton(
                  icon: const Icon(Icons.play_circle_filled),
                  color: AppTheme.primaryColor,
                  iconSize: 32,
                  onPressed: () {
                    // TODO: Play preview
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Quick Actions Section
  // Social Feed Section
  Widget _buildSocialFeedSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Community Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/reviews'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t(context, 'view_all'),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingFeed)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_socialFeed.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(context, 'be_first_share'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _buildFeedListWithAds(isDark),
          ),
      ],
    );
  }
  
  List<Widget> _buildFeedListWithAds(bool isDark) {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < _socialFeed.length; i++) {
      // Add feed card
      widgets.add(_buildFeedCard(_socialFeed[i], isDark));
      
      // Add banner ad every 7 posts
      if ((i + 1) % 7 == 0 && i != _socialFeed.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AdaptiveBannerAdWidget(),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  Widget _buildFeedCard(Map<String, dynamic> review, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/review/${review['id']}', extra: review),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
          // User header
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/user/${review['userId']}'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[700],
                    image: review['userPhoto'] != null
                        ? DecorationImage(
                            image: NetworkImage(review['userPhoto']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: review['userPhoto'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/user/${review['userId']}'),
                          child: Text(
                            review['userName'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'reviewed',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeago.format(review['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Track info
          if (review['trackName'] != null) ...[
            Row(
              children: [
                if (review['albumArt'] != null)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(review['albumArt']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['trackName'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (review['artistName'] != null)
                        Text(
                          review['artistName'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Review text
          if (review['reviewText'] != null && review['reviewText'].isNotEmpty)
            Text(
              review['reviewText'],
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 12),
          
          // Actions
          Row(
            children: [
              // Like button
              InkWell(
                onTap: () => _handleFeedLike(review),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        (review['likedBy'] as List? ?? []).contains(FirebaseAuth.instance.currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: (review['likedBy'] as List? ?? []).contains(FirebaseAuth.instance.currentUser?.uid)
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${review['likes'] ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Comment button
              InkWell(
                onTap: () => _showFeedCommentSheet(review),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t(context, 'comment'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isDark) {
    final actions = [
      {
        'icon': Icons.library_music,
        'label': t(context, 'my_library'),
        'color': Colors.purple,
        'onTap': () => context.push('/favorites'),
      },
      {
        'icon': Icons.analytics,
        'label': t(context, 'stats'),
        'color': Colors.green,
        'onTap': () => context.push('/statistics'),
      },
      {
        'icon': Icons.rate_review,
        'label': 'Reviews',
        'color': const Color(0xFFFF5E5E),
        'onTap': () => context.push('/reviews'),
      },
      {
        'icon': Icons.explore,
        'label': t(context, 'discover_btn'),
        'color': Colors.orange,
        'onTap': () => context.push('/discover'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: () => (action['onTap'] as VoidCallback)(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (action['color'] as Color).withOpacity(0.8),
                  (action['color'] as Color).withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (action['color'] as Color).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action['icon'] as IconData,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _StickyTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
