import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/gamification_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _globalLeaderboard = [];
  List<Map<String, dynamic>> _friendsLeaderboard = [];
  bool _isLoadingGlobal = true;
  bool _isLoadingFriends = true;
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    // Load global leaderboard
    setState(() => _isLoadingGlobal = true);
    final global = await GamificationService.getGlobalLeaderboard();
    final rank = await GamificationService.getUserRank(currentUser.userId);
    
    // Load friends leaderboard
    setState(() => _isLoadingFriends = true);
    final friends = await GamificationService.getFriendsLeaderboard(currentUser.userId);
    
    setState(() {
      _globalLeaderboard = global;
      _friendsLeaderboard = friends;
      _userRank = rank;
      _isLoadingGlobal = false;
      _isLoadingFriends = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList(_globalLeaderboard, _isLoadingGlobal, showRank: true),
          _buildLeaderboardList(_friendsLeaderboard, _isLoadingFriends),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> leaderboard, bool isLoading, {bool showRank = false}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaderboard.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length + (showRank ? 1 : 0),
        itemBuilder: (context, index) {
          if (showRank && index == 0) {
            return _buildUserRankCard();
          }
          
          final actualIndex = showRank ? index - 1 : index;
          final user = leaderboard[actualIndex];
          return _LeaderboardTile(user: user);
        },
      ),
    );
  }

  Widget _buildUserRankCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFF5E5E).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFF5E5E), size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rank',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '#$_userRank',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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

class _LeaderboardTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const _LeaderboardTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final rank = user['rank'] as int;
    final username = user['username'] as String? ?? 'Unknown';
    final points = user['totalPoints'] as int;
    
    Color? rankColor;
    IconData? rankIcon;
    
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400];
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown[300];
      rankIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor?.withOpacity(0.2) ?? Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 20)
                : Text(
                    '#$rank',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          '$points pts',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
