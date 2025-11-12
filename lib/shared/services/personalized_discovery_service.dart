import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_spotify_service.dart';
import 'favorites_service.dart';

/// Personalized discovery service - Daily Mix, Release Radar
class PersonalizedDiscoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== DAILY MIX ====================
  
  /// Generate Daily Mix playlists based on user's listening habits
  static Future<List<Map<String, dynamic>>> generateDailyMixes(String userId) async {
    try {
      // Get user's favorite tracks and recent listening history
      final favorites = await FavoritesService.getFavoriteTracks().first;
      
      if (favorites.isEmpty) {
        return [];
      }

      final mixes = <Map<String, dynamic>>[];
      
      // Generate 3-6 mixes based on different moods/genres
      final seedTracks = favorites.take(5).map((t) => t['id'] as String).toList();
      
      // Mix 1: Based on top artists
      final mix1 = await _generateMix(
        name: 'Daily Mix 1',
        description: 'Your favorite artists',
        seedTracks: seedTracks,
        targetEnergy: null,
        targetValence: null,
      );
      if (mix1 != null) mixes.add(mix1);
      
      // Mix 2: Upbeat/Energetic
      final mix2 = await _generateMix(
        name: 'Daily Mix 2',
        description: 'Upbeat and energetic',
        seedTracks: seedTracks,
        targetEnergy: 0.8,
        targetValence: 0.8,
      );
      if (mix2 != null) mixes.add(mix2);
      
      // Mix 3: Chill/Relaxed
      final mix3 = await _generateMix(
        name: 'Daily Mix 3',
        description: 'Chill and relaxed',
        seedTracks: seedTracks,
        targetEnergy: 0.3,
        targetValence: 0.5,
      );
      if (mix3 != null) mixes.add(mix3);
      
      return mixes;
    } catch (e) {
      print('Error generating daily mixes: $e');
      return [];
    }
  }

  /// Generate a single mix
  static Future<Map<String, dynamic>?> _generateMix({
    required String name,
    required String description,
    required List<String> seedTracks,
    double? targetEnergy,
    double? targetValence,
  }) async {
    try {
      // TODO: Implement full recommendation API
      final tracks = await EnhancedSpotifyService.searchTracks(
        seedTracks.first,
        limit: 30,
      );
      
      if (tracks.isEmpty) return null;
      
      return {
        'id': 'daily_mix_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'description': description,
        'tracks': tracks,
        'coverUrl': tracks.first['album']?['images']?.first?['url'],
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'daily_mix',
      };
    } catch (e) {
      print('Error generating mix: $e');
      return null;
    }
  }

  // ==================== RELEASE RADAR ====================
  
  /// Generate release radar with new tracks
  static Future<List<Map<String, dynamic>>> generateReleaseRadar(String userId) async {
    return await getReleaseRadar(userId);
  }

  /// Get new releases from followed artists
  static Future<List<Map<String, dynamic>>> getReleaseRadar(String userId) async {
    try {
      // Get user's followed artists
      final followedArtists = await _getFollowedArtists(userId);
      
      if (followedArtists.isEmpty) {
        return [];
      }

      final releases = <Map<String, dynamic>>[];
      
      // Get new releases from each artist (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      for (final artistId in followedArtists.take(20)) {
        try {
          // TODO: Implement getArtistAlbums method
          final artistReleases = await EnhancedSpotifyService.searchAlbums(
            'artist:$artistId',
            limit: 10,
          );
          
          // Filter releases from last 30 days
          final recentReleases = artistReleases.where((album) {
            final releaseDate = DateTime.tryParse(album['release_date'] ?? '');
            return releaseDate != null && releaseDate.isAfter(thirtyDaysAgo);
          }).toList();
          
          releases.addAll(recentReleases);
        } catch (e) {
          print('Error fetching releases for artist $artistId: $e');
        }
      }
      
      // Sort by release date (newest first)
      releases.sort((a, b) {
        final dateA = DateTime.tryParse(a['release_date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['release_date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      return releases;
    } catch (e) {
      print('Error getting release radar: $e');
      return [];
    }
  }

  /// Get followed artists from Firestore
  static Future<List<String>> _getFollowedArtists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      
      if (data != null && data.containsKey('followedArtists')) {
        return List<String>.from(data['followedArtists'] ?? []);
      }
      
      // Fallback: Get artists from favorite tracks
      final favorites = await FavoritesService.getFavoriteTracks().first;
      
      final artistIds = favorites
          .map((track) => (track['artists'] as List?)?.first?['id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();
      
      return artistIds;
    } catch (e) {
      print('Error getting followed artists: $e');
      return [];
    }
  }

  // ==================== DISCOVER WEEKLY (BONUS) ====================
  
  /// Generate Discover Weekly playlist
  static Future<Map<String, dynamic>?> generateDiscoverWeekly(String userId) async {
    try {
      final favorites = await FavoritesService.getFavoriteTracks().first;
      
      if (favorites.isEmpty) {
        return null;
      }

      // Get diverse seed tracks
      final seedTracks = favorites
          .take(5)
          .map((t) => t['id'] as String)
          .toList();
      
      // Get recommendations with variety  
      // TODO: Implement getRecommendations method in EnhancedSpotifyService
      final tracks = await EnhancedSpotifyService.searchTracks(
        seedTracks.first,
        limit: 30,
      );
      
      if (tracks.isEmpty) return null;
      
      return {
        'id': 'discover_weekly_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Discover Weekly',
        'description': 'Your weekly mixtape of fresh music',
        'tracks': tracks,
        'coverUrl': tracks.first['album']?['images']?.first?['url'],
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'discover_weekly',
      };
    } catch (e) {
      print('Error generating discover weekly: $e');
      return null;
    }
  }

  // ==================== ON REPEAT (BONUS) ====================
  
  /// Get user's most played tracks (On Repeat)
  static Future<List<Map<String, dynamic>>> getOnRepeat(String userId) async {
    try {
      // Get user's play history from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('playHistory')
          .orderBy('playCount', descending: true)
          .limit(30)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting on repeat: $e');
      return [];
    }
  }
}
