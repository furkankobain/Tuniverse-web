import 'package:cloud_firestore/cloud_firestore.dart';

/// Gamification service - achievements, badges, streaks, leaderboards
class GamificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== ACHIEVEMENTS & BADGES ====================
  
  /// Check and award achievements
  static Future<List<String>> checkAchievements(String userId) async {
    try {
      final newAchievements = <String>[];
      final userStats = await _getUserStats(userId);
      
      // Check each achievement
      for (final achievement in _allAchievements) {
        final isUnlocked = await _isAchievementUnlocked(userId, achievement['id']);
        if (!isUnlocked && _checkAchievementCondition(achievement, userStats)) {
          await _unlockAchievement(userId, achievement['id']);
          newAchievements.add(achievement['id']);
        }
      }
      
      return newAchievements;
    } catch (e) {
      print('Error checking achievements: $e');
      return [];
    }
  }

  /// Get all achievements for user
  static Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();
      
      final unlockedIds = snapshot.docs.map((d) => d.id).toSet();
      
      return _allAchievements.map((a) {
        return {
          ...a,
          'unlocked': unlockedIds.contains(a['id']),
          'unlockedAt': unlockedIds.contains(a['id'])
              ? snapshot.docs.firstWhere((d) => d.id == a['id']).data()['unlockedAt']
              : null,
        };
      }).toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  /// Unlock achievement
  static Future<void> _unlockAchievement(String userId, String achievementId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(achievementId)
        .set({
      'unlockedAt': FieldValue.serverTimestamp(),
    });
    
    // Award points
    final achievement = _allAchievements.firstWhere((a) => a['id'] == achievementId);
    await _addPoints(userId, achievement['points'] as int);
  }

  /// Check if achievement is unlocked
  static Future<bool> _isAchievementUnlocked(String userId, String achievementId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(achievementId)
        .get();
    return doc.exists;
  }

  /// Check achievement condition
  static bool _checkAchievementCondition(Map<String, dynamic> achievement, Map<String, dynamic> stats) {
    final condition = achievement['condition'] as Map<String, dynamic>;
    final type = condition['type'] as String;
    final required = condition['value'] as int;
    
    switch (type) {
      case 'totalTracks':
        return (stats['totalTracks'] ?? 0) >= required;
      case 'totalReviews':
        return (stats['totalReviews'] ?? 0) >= required;
      case 'totalPlaylists':
        return (stats['totalPlaylists'] ?? 0) >= required;
      case 'followersCount':
        return (stats['followersCount'] ?? 0) >= required;
      case 'streakDays':
        return (stats['currentStreak'] ?? 0) >= required;
      default:
        return false;
    }
  }

  /// All available achievements
  static final List<Map<String, dynamic>> _allAchievements = [
    // Music listening achievements
    {'id': 'first_track', 'name': 'First Steps', 'description': 'Listen to your first track', 'icon': '🎵', 'points': 10, 'condition': {'type': 'totalTracks', 'value': 1}},
    {'id': 'track_10', 'name': 'Music Explorer', 'description': 'Listen to 10 tracks', 'icon': '🎧', 'points': 25, 'condition': {'type': 'totalTracks', 'value': 10}},
    {'id': 'track_50', 'name': 'Dedicated Listener', 'description': 'Listen to 50 tracks', 'icon': '🎼', 'points': 50, 'condition': {'type': 'totalTracks', 'value': 50}},
    {'id': 'track_100', 'name': 'Century Club', 'description': 'Listen to 100 tracks', 'icon': '💯', 'points': 100, 'condition': {'type': 'totalTracks', 'value': 100}},
    {'id': 'track_500', 'name': 'Music Addict', 'description': 'Listen to 500 tracks', 'icon': '🔥', 'points': 250, 'condition': {'type': 'totalTracks', 'value': 500}},
    
    // Review achievements
    {'id': 'first_review', 'name': 'Critic Debut', 'description': 'Write your first review', 'icon': '✍️', 'points': 15, 'condition': {'type': 'totalReviews', 'value': 1}},
    {'id': 'review_10', 'name': 'Opinion Maker', 'description': 'Write 10 reviews', 'icon': '📝', 'points': 30, 'condition': {'type': 'totalReviews', 'value': 10}},
    {'id': 'review_50', 'name': 'Professional Critic', 'description': 'Write 50 reviews', 'icon': '🎖️', 'points': 100, 'condition': {'type': 'totalReviews', 'value': 50}},
    
    // Playlist achievements
    {'id': 'first_playlist', 'name': 'Playlist Creator', 'description': 'Create your first playlist', 'icon': '📀', 'points': 20, 'condition': {'type': 'totalPlaylists', 'value': 1}},
    {'id': 'playlist_5', 'name': 'Curator', 'description': 'Create 5 playlists', 'icon': '🎨', 'points': 50, 'condition': {'type': 'totalPlaylists', 'value': 5}},
    {'id': 'playlist_20', 'name': 'Master Curator', 'description': 'Create 20 playlists', 'icon': '👑', 'points': 150, 'condition': {'type': 'totalPlaylists', 'value': 20}},
    
    // Social achievements
    {'id': 'followers_10', 'name': 'Rising Star', 'description': 'Get 10 followers', 'icon': '⭐', 'points': 50, 'condition': {'type': 'followersCount', 'value': 10}},
    {'id': 'followers_50', 'name': 'Influencer', 'description': 'Get 50 followers', 'icon': '🌟', 'points': 150, 'condition': {'type': 'followersCount', 'value': 50}},
    {'id': 'followers_100', 'name': 'Music Celebrity', 'description': 'Get 100 followers', 'icon': '💫', 'points': 300, 'condition': {'type': 'followersCount', 'value': 100}},
    
    // Streak achievements
    {'id': 'streak_7', 'name': 'Week Warrior', 'description': '7-day listening streak', 'icon': '🔥', 'points': 50, 'condition': {'type': 'streakDays', 'value': 7}},
    {'id': 'streak_30', 'name': 'Month Master', 'description': '30-day listening streak', 'icon': '🌟', 'points': 200, 'condition': {'type': 'streakDays', 'value': 30}},
    {'id': 'streak_100', 'name': 'Century Streak', 'description': '100-day listening streak', 'icon': '💎', 'points': 500, 'condition': {'type': 'streakDays', 'value': 100}},
  ];

  // ==================== STREAKS ====================
  
  /// Get user's current streak
  static Future<Map<String, dynamic>> getUserStreak(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('streak')
          .get();
      
      if (!doc.exists) {
        return {'currentStreak': 0, 'longestStreak': 0, 'lastActiveDate': null};
      }
      
      final data = doc.data()!;
      final lastActive = (data['lastActiveDate'] as Timestamp?)?.toDate();
      final currentStreak = data['currentStreak'] as int? ?? 0;
      
      // Check if streak is broken (more than 1 day since last activity)
      if (lastActive != null) {
        final daysDiff = DateTime.now().difference(lastActive).inDays;
        if (daysDiff > 1) {
          // Streak broken!
          return {...data, 'currentStreak': 0};
        }
      }
      
      return data;
    } catch (e) {
      print('Error getting streak: $e');
      return {'currentStreak': 0, 'longestStreak': 0};
    }
  }

  /// Update streak (call when user listens to music)
  static Future<void> updateStreak(String userId) async {
    try {
      final streakRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('streak');
      
      final doc = await streakRef.get();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (!doc.exists) {
        // First time
        await streakRef.set({
          'currentStreak': 1,
          'longestStreak': 1,
          'lastActiveDate': Timestamp.fromDate(today),
        });
        return;
      }
      
      final data = doc.data()!;
      final lastActive = (data['lastActiveDate'] as Timestamp).toDate();
      final lastDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final daysDiff = today.difference(lastDay).inDays;
      
      if (daysDiff == 0) {
        // Already counted today
        return;
      } else if (daysDiff == 1) {
        // Consecutive day
        final newStreak = (data['currentStreak'] as int) + 1;
        final longestStreak = data['longestStreak'] as int;
        
        await streakRef.update({
          'currentStreak': newStreak,
          'longestStreak': newStreak > longestStreak ? newStreak : longestStreak,
          'lastActiveDate': Timestamp.fromDate(today),
        });
      } else {
        // Streak broken, start new
        await streakRef.update({
          'currentStreak': 1,
          'lastActiveDate': Timestamp.fromDate(today),
        });
      }
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // ==================== LEADERBOARDS ====================
  
  /// Get global leaderboard
  static Future<List<Map<String, dynamic>>> getGlobalLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        return {
          'rank': entry.key + 1,
          'userId': entry.value.id,
          'username': data['username'],
          'totalPoints': data['totalPoints'] ?? 0,
          'profileImage': data['profileImage'],
        };
      }).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get user's rank
  static Future<int> getUserRank(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userPoints = userDoc.data()?['totalPoints'] ?? 0;
      
      final higherRanked = await _firestore
          .collection('users')
          .where('totalPoints', isGreaterThan: userPoints)
          .get();
      
      return higherRanked.docs.length + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  /// Get friends leaderboard
  static Future<List<Map<String, dynamic>>> getFriendsLeaderboard(String userId) async {
    try {
      // Get user's following list
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final following = List<String>.from(userDoc.data()?['following'] ?? []);
      
      if (following.isEmpty) return [];
      
      // Get points for each friend (in batches of 10 due to Firestore limit)
      final friends = <Map<String, dynamic>>[];
      
      for (var i = 0; i < following.length; i += 10) {
        final batch = following.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        friends.addAll(snapshot.docs.map((d) {
          final data = d.data();
          return {
            'userId': d.id,
            'username': data['username'],
            'totalPoints': data['totalPoints'] ?? 0,
            'profileImage': data['profileImage'],
          };
        }));
      }
      
      // Sort by points
      friends.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
      
      // Add rank
      return friends.asMap().entries.map((e) {
        return {...e.value, 'rank': e.key + 1};
      }).toList();
    } catch (e) {
      print('Error getting friends leaderboard: $e');
      return [];
    }
  }

  // ==================== POINTS SYSTEM ====================
  
  /// Add points to user
  static Future<void> _addPoints(String userId, int points) async {
    await _firestore.collection('users').doc(userId).update({
      'totalPoints': FieldValue.increment(points),
    });
  }

  /// Get user stats
  static Future<Map<String, dynamic>> _getUserStats(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    
    final streak = await getUserStreak(userId);
    
    return {
      'totalTracks': data['totalTracksListened'] ?? 0,
      'totalReviews': data['totalReviews'] ?? 0,
      'totalPlaylists': data['totalPlaylists'] ?? 0,
      'followersCount': data['followersCount'] ?? 0,
      'currentStreak': streak['currentStreak'] ?? 0,
    };
  }

  /// Get badge tier based on points
  static String getBadgeTier(int points) {
    if (points >= 5000) return 'Diamond 💎';
    if (points >= 2500) return 'Platinum 🏆';
    if (points >= 1000) return 'Gold 🥇';
    if (points >= 500) return 'Silver 🥈';
    if (points >= 100) return 'Bronze 🥉';
    return 'Newbie 🌱';
  }
}
