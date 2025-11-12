import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/music_quiz_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class WeeklyChallengesPage extends StatefulWidget {
  const WeeklyChallengesPage({super.key});

  @override
  State<WeeklyChallengesPage> createState() => _WeeklyChallengesPageState();
}

class _WeeklyChallengesPageState extends State<WeeklyChallengesPage> {
  Map<String, dynamic> _challenge = {};
  Map<String, dynamic> _progress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final challenge = await MusicQuizService.getWeeklyChallenge();
    final progress = await MusicQuizService.getUserWeeklyChallengeProgress(currentUser.userId);

    setState(() {
      _challenge = challenge;
      _progress = progress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Challenges')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChallenge,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChallengeCard(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 24),
                  _buildRewardsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildChallengeCard() {
    final name = _challenge['name'] ?? 'Weekly Challenge';
    final description = _challenge['description'] ?? '';
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 This Week\'s Challenge',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _progress['progress'] ?? 0;
    final target = _challenge['target'] ?? 1;
    final percentage = target > 0 ? (progress / target * 100).clamp(0, 100) : 0;
    final completed = _progress['completed'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$progress / $target',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? Colors.green : const Color(0xFFFF5E5E),
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              completed ? '✅ Challenge Completed!' : '${percentage.toStringAsFixed(0)}% Complete',
              style: TextStyle(
                color: completed ? Colors.green : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsCard() {
    final reward = _challenge['reward'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            const Text(
              'Reward',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '$reward Points',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
