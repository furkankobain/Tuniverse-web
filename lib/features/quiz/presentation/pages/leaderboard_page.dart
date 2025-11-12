import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/services/advanced_quiz_service.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/adaptive_banner_ad_widget.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboard = [];
  int _userRank = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await AdvancedQuizService.getMonthlyLeaderboard(limit: 50);
      
      final user = FirebaseAuth.instance.currentUser;
      int userRank = -1;
      if (user != null) {
        userRank = await AdvancedQuizService.getUserRank(user.uid);
      }

      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
          _userRank = userRank;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadLeaderboard();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B46C1), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  color: const Color(0xFFFFD700),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🏆', style: TextStyle(fontSize: 40)),
                                SizedBox(width: 12),
                                Text(
                                  'Leaderboard',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ],
                            ),
                            if (_userRank > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Your Rank: #$_userRank',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Top 3 Podium
                      if (_leaderboard.length >= 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 2nd place
                              Expanded(
                                child: _buildPodiumPlace(
                                  rank: 2,
                                  username: _leaderboard[1]['username'] ?? 'Unknown',
                                  score: _leaderboard[1]['totalScore'] ?? 0,
                                  profileImageUrl: _leaderboard[1]['profileImageUrl'] ?? '',
                                  height: 100,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 1st place
                              Expanded(
                                child: _buildPodiumPlace(
                                  rank: 1,
                                  username: _leaderboard[0]['username'] ?? 'Unknown',
                                  score: _leaderboard[0]['totalScore'] ?? 0,
                                  profileImageUrl: _leaderboard[0]['profileImageUrl'] ?? '',
                                  height: 140,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 3rd place
                              Expanded(
                                child: _buildPodiumPlace(
                                  rank: 3,
                                  username: _leaderboard[2]['username'] ?? 'Unknown',
                                  score: _leaderboard[2]['totalScore'] ?? 0,
                                  profileImageUrl: _leaderboard[2]['profileImageUrl'] ?? '',
                                  height: 80,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Rest of leaderboard
                      Expanded(
                        child: _leaderboard.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.leaderboard_outlined,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No players yet this month',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Be the first to play!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
                                itemBuilder: (context, index) {
                                  final adjustedIndex = index + 3;
                                  final player = _leaderboard[adjustedIndex];
                                  final rank = adjustedIndex + 1;
                                  final isCurrentUser = user != null && player['userId'] == user.uid;

                                  return _buildLeaderboardItem(
                                    rank: rank,
                                    username: player['username'] ?? 'Unknown',
                                    score: player['totalScore'] ?? 0,
                                    gamesPlayed: player['gamesPlayed'] ?? 0,
                                    profileImageUrl: player['profileImageUrl'] ?? '',
                                    isCurrentUser: isCurrentUser,
                                  );
                                },
                              ),
                      ),
                      
                      // Banner Ad
                      AdaptiveBannerAdWidget(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPodiumPlace({
    required int rank,
    required String username,
    required int score,
    required String profileImageUrl,
    required double height,
  }) {
    String medal;
    Color podiumColor;

    if (rank == 1) {
      medal = '🥇';
      podiumColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      medal = '🥈';
      podiumColor = const Color(0xFFC0C0C0);
    } else {
      medal = '🥉';
      podiumColor = const Color(0xFFCD7F32);
    }

    return Column(
      children: [
        // Profile with medal
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: podiumColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: podiumColor.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            Positioned(
              top: -10,
              right: -5,
              child: Text(medal, style: const TextStyle(fontSize: 28)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          username,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '$score pts',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                podiumColor,
                podiumColor.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String username,
    required int score,
    required int gamesPlayed,
    required String profileImageUrl,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFFFFD700).withOpacity(0.2)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.2),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          if (isCurrentUser)
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Profile image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[600],
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Username and games
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$gamesPlayed games',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
