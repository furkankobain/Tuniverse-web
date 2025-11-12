import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../shared/services/follow_service.dart';
import '../../../../shared/services/feed_service.dart';
import '../../../../shared/models/activity_item.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String username;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  int _reviewsCount = 0;
  int _listsCount = 0;
  List<ActivityItem> _userActivities = [];
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        _userData = userDoc.data();
      }

      // Load follower/following counts
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .get();
      
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();

      // Load reviews count
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .get();

      // Load user activities
      final activities = await FeedService.getUserActivities(
        userId: widget.userId,
        limit: 20,
      );

      // Check if current user follows this user
      if (currentUserId != null && currentUserId != widget.userId) {
        final followDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(widget.userId)
            .get();
        
        _isFollowing = followDoc.exists;
      }
      
      if (mounted) {
        setState(() {
          _followersCount = followersSnapshot.docs.length;
          _followingCount = followingSnapshot.docs.length;
          _reviewsCount = reviewsSnapshot.docs.length;
          _listsCount = 0; // TODO: Load playlists count
          _userActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);
    
    bool success;
    if (_isFollowing) {
      success = await FollowService.followUser(widget.userId);
      if (success) {
        setState(() => _followersCount++);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.username} takip edildi'),
              backgroundColor: ModernDesignSystem.primaryGreen,
            ),
          );
        }
      }
    } else {
      success = await FollowService.unfollowUser(widget.userId);
      if (success) {
        setState(() => _followersCount--);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.username} takipten çıkarıldı'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    }

    // Revert if failed
    if (!success && mounted) {
      setState(() => _isFollowing = wasFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openConversation() async {
    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      if (currentUserId == null) return;

      // Create or get conversation ID
      final conversationId = _getConversationId(currentUserId, widget.userId);
      
      // Navigate to conversation with user data
      context.push(
        '/conversation/$conversationId',
        extra: {
          'userId': widget.userId,
          'username': widget.username,
          'userPhoto': _userData?['profileImageUrl'] ?? _userData?['photoURL'],
        },
      );
    } catch (e) {
      print('Error opening conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesajlaşma açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getConversationId(String userId1, String userId2) {
    // Sort user IDs to ensure consistent conversation ID
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnProfile = widget.userId == FirebaseBypassAuthService.currentUser?.userId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with User Info
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark
                ? ModernDesignSystem.darkBackground
                : ModernDesignSystem.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Profile Picture
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: _userData?['profileImageUrl'] != null || _userData?['photoURL'] != null
                            ? CircleAvatar(
                                radius: 48,
                                backgroundImage: CachedNetworkImageProvider(
                                  _userData!['profileImageUrl'] ?? _userData!['photoURL'],
                                ),
                              )
                            : CircleAvatar(
                                radius: 48,
                                backgroundColor: ModernDesignSystem.darkCard,
                                child: Text(
                                  widget.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Username
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: ModernDesignSystem.fontSizeXXL,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('İnceleme', _reviewsCount.toString()),
                            _buildStatColumn('Liste', _listsCount.toString()),
                            _buildStatColumn('Takipçi', _followersCount.toString()),
                            _buildStatColumn('Takip', _followingCount.toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (!isOwnProfile) ...[
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.grey
                              : ModernDesignSystem.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                          ),
                        ),
                        child: Text(
                          _isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (isOwnProfile) {
                          context.push('/edit-profile');
                        } else {
                          _openConversation();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? ModernDesignSystem.darkBorder
                              : ModernDesignSystem.lightBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOwnProfile ? Icons.edit : Icons.message,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOwnProfile ? 'Profili Düzenle' : 'Mesaj Gönder',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
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

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: ModernDesignSystem.primaryGreen,
                unselectedLabelColor: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                indicatorColor: ModernDesignSystem.primaryGreen,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: ModernDesignSystem.fontSizeS,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'İncelemeler'),
                  Tab(text: 'Listeler'),
                  Tab(text: 'Favori'),
                  Tab(text: 'Aktivite'),
                ],
              ),
              isDark,
            ),
          ),

          // Tab Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsTab(isDark),
                  _buildListsTab(isDark),
                  _buildFavoritesTab(isDark),
                  _buildActivityTab(isDark),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: ModernDesignSystem.fontSizeL,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeXS,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz inceleme yok',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: ModernDesignSystem.fontSizeM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz liste yok',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: ModernDesignSystem.fontSizeM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz favori yok',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: ModernDesignSystem.fontSizeM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz aktivite yok',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: ModernDesignSystem.fontSizeM,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark
          ? ModernDesignSystem.darkBackground
          : ModernDesignSystem.lightBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
