import 'package:cloud_firestore/cloud_firestore.dart';

/// Achievement/Badges system service
class AchievementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Available achievements
  static const List<Achievement> allAchievements = [
    // Listening achievements
    Achievement(
      id: 'first_listen',
      name: 'İlk Adım',
      description: 'İlk şarkını dinledin',
      icon: '🎵',
      category: 'listening',
      requirement: 1,
    ),
    Achievement(
      id: 'music_explorer',
      name: 'Müzik Kaşifi',
      description: '50 şarkı dinledin',
      icon: '🎧',
      category: 'listening',
      requirement: 50,
    ),
    Achievement(
      id: 'music_addict',
      name: 'Müzik Bağımlısı',
      description: '500 şarkı dinledin',
      icon: '🎸',
      category: 'listening',
      requirement: 500,
    ),
    Achievement(
      id: 'music_legend',
      name: 'Müzik Efsanesi',
      description: '5000 şarkı dinledin',
      icon: '👑',
      category: 'listening',
      requirement: 5000,
    ),

    // Rating achievements
    Achievement(
      id: 'first_rating',
      name: 'İlk Değerlendirme',
      description: 'İlk puanını verdin',
      icon: '⭐',
      category: 'rating',
      requirement: 1,
    ),
    Achievement(
      id: 'critic',
      name: 'Eleştirmen',
      description: '50 şarkıya puan verdin',
      icon: '📝',
      category: 'rating',
      requirement: 50,
    ),
    Achievement(
      id: 'master_critic',
      name: 'Usta Eleştirmen',
      description: '500 şarkıya puan verdin',
      icon: '🎭',
      category: 'rating',
      requirement: 500,
    ),

    // Social achievements
    Achievement(
      id: 'first_friend',
      name: 'İlk Arkadaş',
      description: 'İlk takipçini kazandın',
      icon: '👥',
      category: 'social',
      requirement: 1,
    ),
    Achievement(
      id: 'popular',
      name: 'Popüler',
      description: '50 takipçin var',
      icon: '🌟',
      category: 'social',
      requirement: 50,
    ),
    Achievement(
      id: 'influencer',
      name: 'Etkileyici',
      description: '500 takipçin var',
      icon: '💫',
      category: 'social',
      requirement: 500,
    ),

    // Streak achievements
    Achievement(
      id: 'week_streak',
      name: '7 Günlük Seri',
      description: '7 gün üst üste aktif oldun',
      icon: '🔥',
      category: 'streak',
      requirement: 7,
    ),
    Achievement(
      id: 'month_streak',
      name: 'Aylık Seri',
      description: '30 gün üst üste aktif oldun',
      icon: '💥',
      category: 'streak',
      requirement: 30,
    ),
    Achievement(
      id: 'legend_streak',
      name: 'Efsane Seri',
      description: '100 gün üst üste aktif oldun',
      icon: '⚡',
      category: 'streak',
      requirement: 100,
    ),

    // Discovery achievements
    Achievement(
      id: 'genre_explorer',
      name: 'Tür Kaşifi',
      description: '10 farklı tür dinledin',
      icon: '🗺️',
      category: 'discovery',
      requirement: 10,
    ),
    Achievement(
      id: 'artist_collector',
      name: 'Sanatçı Koleksiyoncusu',
      description: '100 farklı sanatçı dinledin',
      icon: '🎨',
      category: 'discovery',
      requirement: 100,
    ),

    // Playlist achievements
    Achievement(
      id: 'playlist_creator',
      name: 'Çalma Listesi Yaratıcısı',
      description: 'İlk çalma listeni oluşturdun',
      icon: '📋',
      category: 'playlist',
      requirement: 1,
    ),
    Achievement(
      id: 'curator',
      name: 'Küratör',
      description: '10 çalma listesi oluşturdun',
      icon: '🎼',
      category: 'playlist',
      requirement: 10,
    ),
  ];

  /// Check and award achievements for a user
  static Future<List<Achievement>> checkAndAwardAchievements(String userId) async {
    try {
      final newAchievements = <Achievement>[];

      // Get user's current achievements
      final userAchievementsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('unlocked')
          .get();

      final unlockedIds = Set<String>.from(
        (userAchievementsDoc.data()?['achievementIds'] ?? []) as List,
      );

      // Get user stats
      final stats = await _getUserStats(userId);

      // Check each achievement
      for (final achievement in allAchievements) {
        if (unlockedIds.contains(achievement.id)) continue;

        bool unlocked = false;

        switch (achievement.category) {
          case 'listening':
            unlocked = stats['totalListens'] >= achievement.requirement;
            break;
          case 'rating':
            unlocked = stats['totalRatings'] >= achievement.requirement;
            break;
          case 'social':
            unlocked = stats['followerCount'] >= achievement.requirement;
            break;
          case 'streak':
            unlocked = stats['currentStreak'] >= achievement.requirement;
            break;
          case 'discovery':
            if (achievement.id == 'genre_explorer') {
              unlocked = stats['uniqueGenres'] >= achievement.requirement;
            } else if (achievement.id == 'artist_collector') {
              unlocked = stats['uniqueArtists'] >= achievement.requirement;
            }
            break;
          case 'playlist':
            unlocked = stats['playlistCount'] >= achievement.requirement;
            break;
        }

        if (unlocked) {
          newAchievements.add(achievement);
          unlockedIds.add(achievement.id);

          // Save achievement
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('achievements')
              .doc(achievement.id)
              .set({
            'achievementId': achievement.id,
            'unlockedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Update unlocked list
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('unlocked')
          .set({
        'achievementIds': unlockedIds.toList(),
        'lastChecked': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return newAchievements;
    } catch (e) {
      print('Error checking achievements: $e');
      return [];
    }
  }

  /// Get user's unlocked achievements
  static Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final userAchievementsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('unlocked')
          .get();

      final unlockedIds = Set<String>.from(
        (userAchievementsDoc.data()?['achievementIds'] ?? []) as List,
      );

      return allAchievements
          .where((achievement) => unlockedIds.contains(achievement.id))
          .toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }

  /// Get user stats for achievement checking
  static Future<Map<String, int>> _getUserStats(String userId) async {
    final stats = <String, int>{
      'totalListens': 0,
      'totalRatings': 0,
      'followerCount': 0,
      'currentStreak': 0,
      'uniqueGenres': 0,
      'uniqueArtists': 0,
      'playlistCount': 0,
    };

    try {
      // Get listens count
      final listensSnapshot = await _firestore
          .collection('listens')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      stats['totalListens'] = listensSnapshot.count ?? 0;

      // Get ratings count
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      stats['totalRatings'] = ratingsSnapshot.count ?? 0;

      // Get user doc for followers
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      stats['followerCount'] = (userData['followers'] as List?)?.length ?? 0;
      stats['currentStreak'] = userData['currentStreak'] ?? 0;

      // Get unique genres
      final listensForGenres = await _firestore
          .collection('listens')
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();
      
      final genres = <String>{};
      for (final doc in listensForGenres.docs) {
        final trackGenres = doc.data()['genres'] as List?;
        if (trackGenres != null) {
          genres.addAll(trackGenres.cast<String>());
        }
      }
      stats['uniqueGenres'] = genres.length;

      // Get unique artists
      final artists = <String>{};
      for (final doc in listensForGenres.docs) {
        final artist = doc.data()['artistName'] as String?;
        if (artist != null) {
          artists.add(artist);
        }
      }
      stats['uniqueArtists'] = artists.length;

      // Get playlist count
      final playlistsSnapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      stats['playlistCount'] = playlistsSnapshot.count ?? 0;

      return stats;
    } catch (e) {
      print('Error getting user stats: $e');
      return stats;
    }
  }

  /// Get achievement progress
  static Future<Map<String, double>> getAchievementProgress(String userId) async {
    final progress = <String, double>{};
    final stats = await _getUserStats(userId);

    for (final achievement in allAchievements) {
      int current = 0;

      switch (achievement.category) {
        case 'listening':
          current = stats['totalListens']!;
          break;
        case 'rating':
          current = stats['totalRatings']!;
          break;
        case 'social':
          current = stats['followerCount']!;
          break;
        case 'streak':
          current = stats['currentStreak']!;
          break;
        case 'discovery':
          if (achievement.id == 'genre_explorer') {
            current = stats['uniqueGenres']!;
          } else if (achievement.id == 'artist_collector') {
            current = stats['uniqueArtists']!;
          }
          break;
        case 'playlist':
          current = stats['playlistCount']!;
          break;
      }

      progress[achievement.id] = (current / achievement.requirement).clamp(0.0, 1.0);
    }

    return progress;
  }
}

/// Achievement data class
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final int requirement;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirement,
  });
}
