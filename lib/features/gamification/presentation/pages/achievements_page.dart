import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/gamification_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;
  int _totalPoints = 0;
  int _unlockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final achievements = await GamificationService.getUserAchievements(currentUser.userId);
    
    final unlocked = achievements.where((a) => a['unlocked'] == true).toList();
    final totalPoints = unlocked.fold<int>(0, (sum, a) => sum + (a['points'] as int));

    setState(() {
      _achievements = achievements;
      _unlockedCount = unlocked.length;
      _totalPoints = totalPoints;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAchievements,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _achievements.length,
                      itemBuilder: (context, index) {
                        return _AchievementCard(achievement: _achievements[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final badge = GamificationService.getBadgeTier(_totalPoints);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF5E5E),
            const Color(0xFFFF5E5E).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            badge,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalPoints Points',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_unlockedCount / ${_achievements.length} Unlocked',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement['unlocked'] == true;
    final icon = achievement['icon'] as String;
    final name = achievement['name'] as String;
    final description = achievement['description'] as String;
    final points = achievement['points'] as int;

    return Card(
      elevation: isUnlocked ? 4 : 1,
      color: isUnlocked ? null : Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 48,
                color: isUnlocked ? null : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? null : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isUnlocked ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked ? const Color(0xFFFF5E5E) : Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$points pts',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
