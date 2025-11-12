import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/music_review.dart';
import '../../../../core/theme/app_theme.dart';
import 'review_detail_page.dart';

class ReviewsPage extends ConsumerStatefulWidget {
  const ReviewsPage({super.key});

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text(
          'Reviews',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Popular'),
            Tab(text: 'New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsReviews(isDark),
          _buildPopularReviews(isDark),
          _buildRecentReviews(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReviewDialog(context, isDark),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.edit),
        label: const Text('Write Review'),
      ),
    );
  }

  Widget _buildFriendsReviews(bool isDark) {
    final mockReviews = _getMockReviews();

    if (mockReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When your friends share reviews, they\'ll appear here',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockReviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(mockReviews[index], isDark);
        },
      ),
    );
  }

  Widget _buildPopularReviews(bool isDark) {
    return _buildFriendsReviews(isDark);
  }

  Widget _buildRecentReviews(bool isDark) {
    return _buildFriendsReviews(isDark);
  }

  Widget _buildReviewCard(MusicReview review, bool isDark) {
    return InkWell(
      onTap: () => _showReviewDetail(review, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header with Rating
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Text(
                      review.username[0].toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to user profile
                            context.push(
                              '/user-profile',
                              extra: {
                                'userId': review.userId,
                                'username': review.username,
                              },
                            );
                          },
                          child: Text(
                            review.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? AppTheme.primaryColor : AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(review.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating stars
                  if (review.rating != null)
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating! ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.more_horiz, size: 20),
                    onPressed: () {
                      // TODO: Show options menu
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Music Info with Album Art
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Album artwork
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: review.albumImage != null
                          ? CachedNetworkImage(
                              imageUrl: review.albumImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                child: Icon(
                                  Icons.music_note,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(
                                Icons.music_note,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.trackName,
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
                          review.artists,
                          style: TextStyle(
                            fontSize: 14,
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

            const SizedBox(height: 12),

            // Review Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                review.reviewText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  letterSpacing: 0.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tags
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: review.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Like/Dislike combined
                  _buildLikeDislikeButton(review, isDark),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: '${review.replyCount}',
                    onTap: () {
                      _showReviewDetail(review, isDark);
                    },
                    isDark: isDark,
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '',
                    onTap: () {
                      _shareReview(review);
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.bookmark_border,
                    label: '',
                    onTap: () {
                      _bookmarkReview(review);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeDislikeButton(MusicReview review, bool isDark) {
    // Mock current user ID (in real app, get from auth service)
    const currentUserId = 'current_user';
    
    final isLiked = review.likedBy.contains(currentUserId);
    final isDisliked = review.dislikedBy.contains(currentUserId);
    final netScore = review.likeCount - review.dislikeCount;
    final scoreColor = netScore > 0 
        ? Colors.green 
        : netScore < 0 
            ? Colors.red 
            : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              // TODO: Implement like toggle
              setState(() {
                // Mock implementation
              });
            },
            child: Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: isLiked ? AppTheme.primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            netScore.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              // TODO: Implement dislike toggle
              setState(() {
                // Mock implementation
              });
            },
            child: Icon(
              isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
              size: 18,
              color: isDisliked ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReviewDetail(MusicReview review, bool isDark) {
    // Note: This page is deprecated, modern_reviews_page.dart is used instead
    // Just showing a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please use the Reviews page from home')),
    );
  }

  void _shareReview(MusicReview review) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share ${review.username}\'s review')),
    );
  }

  void _bookmarkReview(MusicReview review) {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review saved')),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  void _showCreateReviewDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write Review'),
        content: const Text('Review writing feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<MusicReview> _getMockReviews() {
    // Mock data
    return List.generate(5, (index) {
      return MusicReview(
        id: 'review_$index',
        userId: 'user_$index',
        username: 'User ${index + 1}',
        trackId: 'track_$index',
        trackName: 'Song Title ${index + 1}',
        artists: 'Artist Name',
        albumImage: null, // In real app, this would come from Spotify
        rating: (index % 5) + 1,
        reviewText: index == 0
            ? 'This song is absolutely amazing! The melody and lyrics are so impactful. Every time I listen to it, it adds a different feeling to my day. Definitely a must-listen track for everyone.'
            : index == 1
            ? 'Didn\'t understand it on first listen, but it grew on me over time. Now it\'s one of my favorites. The rhythm and instrumentation are perfect.'
            : 'Great track! ${index + 1}/5 ⭐',
        tags: index == 0
            ? ['favorites', 'emotional', 'must-listen']
            : index == 1
            ? ['summer', 'energetic']
            : [],
        likeCount: (index + 1) * 12,
        dislikeCount: index * 2,
        likedBy: index == 0 ? ['current_user', 'user_1'] : ['user_1'],
        dislikedBy: index == 1 ? ['current_user'] : [],
        replyCount: (index + 1) * 3,
        createdAt: DateTime.now().subtract(Duration(hours: index * 2)),
        updatedAt: DateTime.now().subtract(Duration(hours: index * 2)),
      );
    });
  }
}
