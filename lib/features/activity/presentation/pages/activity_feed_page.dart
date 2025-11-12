import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/firebase_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeedPage extends StatefulWidget {
  const ActivityFeedPage({super.key});

  @override
  State<ActivityFeedPage> createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends State<ActivityFeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseService.auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF5E5E),
          labelColor: const Color(0xFFFF5E5E),
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          tabs: const [
            Tab(text: 'My Activity'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyActivityTab(currentUserId, isDark),
          _buildFriendsActivityTab(currentUserId, isDark),
        ],
      ),
    );
  }

  Widget _buildMyActivityTab(String userId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading activity',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Activity Yet',
            'Start rating and reviewing music to see your activity here!',
            Icons.rate_review,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildActivityCard(data, isDark);
          },
        );
      },
    );
  }

  Widget _buildFriendsActivityTab(String userId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('followers')
          .where('followerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, followSnapshot) {
        if (followSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!followSnapshot.hasData || followSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Friends Activity',
            'Follow other users to see their activity here!',
            Icons.people_outline,
          );
        }

        // Get friend IDs
        final friendIds = followSnapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['followingId'] as String)
            .toList();

        if (friendIds.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Friends Activity',
            'Follow other users to see their activity here!',
            Icons.people_outline,
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('reviews')
              .where('userId', whereIn: friendIds.take(10).toList())
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                isDark,
                'No Activity Yet',
                'Your friends haven\'t posted any reviews yet.',
                Icons.rate_review,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviewSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = reviewSnapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildActivityCard(data, isDark, isFriend: true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data, bool isDark, {bool isFriend = false}) {
    final rating = data['rating'] ?? 0.0;
    final reviewText = data['reviewText'] ?? '';
    final trackName = data['trackName'] ?? 'Unknown Track';
    final artistName = data['artistName'] ?? 'Unknown Artist';
    final imageUrl = data['imageUrl'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final likesCount = data['likesCount'] ?? 0;
    final userName = data['userName'] ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                size: 20,
              ),
            ),
            title: Text(
              isFriend ? userName : 'You',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              timeago.format(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Track Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        child: Icon(
                          Icons.music_note,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
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
                        trackName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artistName,
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
              ],
            ),
          ),

          // Review Text
          if (reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                reviewText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 18,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  likesCount.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment_outlined,
                  size: 18,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '0',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
