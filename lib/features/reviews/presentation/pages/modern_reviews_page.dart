import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';

class ModernReviewsPage extends ConsumerStatefulWidget {
  const ModernReviewsPage({super.key});

  @override
  ConsumerState<ModernReviewsPage> createState() => _ModernReviewsPageState();
}

class _ModernReviewsPageState extends ConsumerState<ModernReviewsPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _followingReviews = [];
  List<Map<String, dynamic>> _popularReviews = [];
  
  bool _isLoadingAll = true;
  bool _isLoadingFollowing = true;
  bool _isLoadingPopular = true;
  
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllReviews();
    _loadFollowingReviews();
    _loadPopularReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingAll && _hasMore && _tabController.index == 0) {
        _loadMoreReviews();
      }
    }
  }

  Future<void> _loadAllReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingAll = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      final snapshot = await query.get();
      final reviews = await _processReviews(snapshot.docs);

      if (mounted) {
        setState(() {
          _allReviews = reviews;
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _limit;
          _isLoadingAll = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) setState(() => _isLoadingAll = false);
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_lastDocument == null) return;
    
    setState(() => _isLoadingAll = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_limit);

      final snapshot = await query.get();
      final reviews = await _processReviews(snapshot.docs);

      if (mounted) {
        setState(() {
          _allReviews.addAll(reviews);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _limit;
          _isLoadingAll = false;
        });
      }
    } catch (e) {
      print('Error loading more: $e');
      if (mounted) setState(() => _isLoadingAll = false);
    }
  }

  Future<void> _loadFollowingReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingFollowing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _followingReviews = [];
          _isLoadingFollowing = false;
        });
        return;
      }

      // Get following list
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final following = List<String>.from(userDoc.data()?['following'] ?? []);
      
      if (following.isEmpty) {
        setState(() {
          _followingReviews = [];
          _isLoadingFollowing = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', whereIn: following.take(10).toList())
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final reviews = await _processReviews(snapshot.docs);

      if (mounted) {
        setState(() {
          _followingReviews = reviews;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      print('Error loading following reviews: $e');
      if (mounted) setState(() => _isLoadingFollowing = false);
    }
  }

  Future<void> _loadPopularReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingPopular = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('likes', descending: true)
          .limit(20)
          .get();

      final reviews = await _processReviews(snapshot.docs);

      if (mounted) {
        setState(() {
          _popularReviews = reviews;
          _isLoadingPopular = false;
        });
      }
    } catch (e) {
      print('Error loading popular reviews: $e');
      if (mounted) setState(() => _isLoadingPopular = false);
    }
  }

  Future<List<Map<String, dynamic>>> _processReviews(
    List<QueryDocumentSnapshot> docs,
  ) async {
    return Future.wait(
      docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        
        // Load user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .get();

        // Get comment count
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .doc(doc.id)
            .collection('comments')
            .get();

        return {
          'id': doc.id,
          'userId': data['userId'],
          'userName': userDoc.data()?['username'] ?? 'Unknown User',
          'userPhoto': userDoc.data()?['profileImageUrl'] ?? 
                       userDoc.data()?['photoURL'],
          'trackName': data['trackName'],
          'artistName': data['artistName'],
          'albumName': data['albumName'],
          'albumArt': data['albumArt'],
          'rating': data['rating'] ?? 0,
          'reviewText': data['reviewText'] ?? '',
          'likes': data['likes'] ?? 0,
          'likedBy': List<String>.from(data['likedBy'] ?? []),
          'commentCount': commentsSnapshot.docs.length,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? 
                       DateTime.now(),
        };
      }).toList(),
    );
  }

  Future<void> _handleLike(String reviewId, List<String> likedBy) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId);
      
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

      // Refresh
      _refreshCurrentTab();
    } catch (e) {
      print('Error liking review: $e');
    }
  }

  Future<void> _showCommentSheet(Map<String, dynamic> review) async {
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
                      'Add Comment',
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
                    hintText: 'Write a comment...',
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
                        await _addComment(review['id'], controller.text.trim());
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
                    child: const Text(
                      'Post Comment',
                      style: TextStyle(
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

  Future<void> _addComment(String reviewId, String comment) async {
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

      _refreshCurrentTab();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _loadAllReviews();
        break;
      case 1:
        _loadFollowingReviews();
        break;
      case 2:
        _loadPopularReviews();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        title: const Text(
          'Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Following'),
            Tab(text: 'Popular'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsList(_allReviews, _isLoadingAll, isDark, showLoadMore: true),
          _buildReviewsList(_followingReviews, _isLoadingFollowing, isDark),
          _buildReviewsList(_popularReviews, _isLoadingPopular, isDark),
        ],
      ),
    );
  }

  Widget _buildReviewsList(
    List<Map<String, dynamic>> reviews,
    bool isLoading,
    bool isDark, {
    bool showLoadMore = false,
  }) {
    if (isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshCurrentTab(),
      child: ListView.builder(
        controller: showLoadMore ? _scrollController : null,
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length + (showLoadMore && _hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == reviews.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildReviewCard(reviews[index], isDark);
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isDark) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasLiked = currentUser != null && 
                     (review['likedBy'] as List).contains(currentUser.uid);

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
                    index < (review['rating'] ?? 0)
                        ? Icons.star
                        : Icons.star_border,
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
          if (review['reviewText'] != null && 
              review['reviewText'].toString().isNotEmpty)
            Text(
              review['reviewText'],
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.4,
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Actions
          Row(
            children: [
              // Like button
              InkWell(
                onTap: () => _handleLike(
                  review['id'],
                  review['likedBy'] as List<String>,
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: hasLiked ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${review['likes']}',
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
                onTap: () => _showCommentSheet(review),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${review['commentCount'] ?? 0}',
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
}
