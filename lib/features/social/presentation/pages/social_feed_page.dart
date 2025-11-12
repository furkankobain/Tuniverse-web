import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../shared/models/activity_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/services/feed_service.dart';

class SocialFeedPage extends ConsumerStatefulWidget {
  const SocialFeedPage({super.key});

  @override
  ConsumerState<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends ConsumerState<SocialFeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ActivityItem> _allFeed = [];
  List<ActivityItem> _followingFeed = [];
  List<ActivityItem> _popularFeed = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _tabController = TabController(length: 3, vsync: this);
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      FeedService.getGlobalFeed(),
      FeedService.getFollowingFeed(),
      FeedService.getPopularFeed(),
    ]);

    if (mounted) {
      setState(() {
        _allFeed = results[0];
        _followingFeed = results[1];
        _popularFeed = results[2];
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Following'),
            Tab(text: 'Popular'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Now Playing Stories Section
          _buildNowPlayingStories(isDark),
          // Feed Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedList(isDark, 'all'),
                _buildFeedList(isDark, 'following'),
                _buildFeedList(isDark, 'popular'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(bool isDark, String feedType) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activities = feedType == 'all'
        ? _allFeed
        : feedType == 'following'
            ? _followingFeed
            : _popularFeed;

    if (activities.isEmpty) {
      late String title;
      late String description;
      
      switch (feedType) {
        case 'following':
          title = 'Not following anyone yet';
          description = 'Follow friends to see their music activity';
          break;
        case 'popular':
          title = 'No popular content';
          description = 'Check back later';
          break;
        default:
          title = 'No activity yet';
          description = 'Start listening to music';
      }
      
      return EmptyStateWidget(
        title: title,
        description: description,
        icon: Icons.music_note,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeeds,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(activities[index], isDark);
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // User info header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    activity.username[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            activity.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activity.getActivityText(),
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(activity.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // TODO: Show options
                  },
                ),
              ],
            ),
          ),

          // Content based on activity type
          if (activity.albumImage != null) ...[
            _buildMusicContent(activity, isDark),
          ],

          // Review text
          if (activity.reviewText != null && activity.reviewText!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                activity.reviewText!,
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: activity.likeCount.toString(),
                  onTap: () async {
                    await FeedService.likeActivity(activity.id);
                    await _loadFeeds();
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: activity.commentCount.toString(),
                  onTap: () {
                    // TODO: Show comments dialog
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Paylaş',
                  onTap: () {
                    // TODO: Share activity
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicContent(ActivityItem activity, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Album cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: const Icon(Icons.music_note, size: 40),
            ),
          ),
          const SizedBox(width: 12),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.trackName ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.artists ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.rating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < activity.rating! ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  Widget _buildNowPlayingStories(bool isDark) {
    final mockUsers = [
      {'name': 'Furkan', 'track': 'Blinding Lights', 'isPlaying': true},
      {'name': 'Ahmet', 'track': 'Levitating', 'isPlaying': true},
      {'name': 'Zeynep', 'track': 'Save Your Tears', 'isPlaying': false},
      {'name': 'Can', 'track': 'Good 4 U', 'isPlaying': true},
      {'name': 'Elif', 'track': 'Peaches', 'isPlaying': false},
    ];

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: mockUsers.length,
        itemBuilder: (context, index) {
          final user = mockUsers[index];
          return _buildNowPlayingStory(
            user['name'] as String,
            user['track'] as String,
            user['isPlaying'] as bool,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildNowPlayingStory(String name, String track, bool isPlaying, bool isDark) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isPlaying
                      ? const LinearGradient(
                          colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                        )
                      : null,
                  border: Border.all(
                    color: isPlaying
                        ? Colors.transparent
                        : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              if (isPlaying)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[900]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<ActivityItem> _getMockActivities() {
    // Mock data - gerçek uygulamada Firestore'dan gelecek
    return [];
  }
}
