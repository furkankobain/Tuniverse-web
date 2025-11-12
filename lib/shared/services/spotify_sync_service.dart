import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'enhanced_spotify_service.dart';
import 'firebase_bypass_auth_service.dart';
import '../models/music_list.dart';
import '../models/user_follow.dart';

/// Service to sync Spotify data with MusicShare app
class SpotifySyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync user profile from Spotify to Firebase
  static Future<bool> syncUserProfile() async {
    try {
      final spotifyProfile = EnhancedSpotifyService.userProfile;
      if (spotifyProfile == null) {
        print('No Spotify profile available');
        return false;
      }

      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Extract Spotify data
      final String? spotifyUserId = spotifyProfile['id'];
      final String? displayName = spotifyProfile['display_name'];
      final String? email = spotifyProfile['email'];
      final List? images = spotifyProfile['images'];
      final String? profileImageUrl = 
          images != null && images.isNotEmpty ? images[0]['url'] : null;

      // Update user profile in Firebase
      final userRef = _firestore.collection('users').doc(currentUser.userId);
      
      await userRef.update({
        'spotifyUserId': spotifyUserId,
        'displayName': displayName ?? currentUser.username,
        'email': email ?? currentUser.email,
        'profileImageUrl': profileImageUrl,
        'spotifyConnected': true,
        'spotifyConnectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('User profile synced successfully');
      return true;
    } catch (e) {
      print('Error syncing user profile: $e');
      return false;
    }
  }

  /// Sync user's Spotify playlists to MusicShare lists
  static Future<bool> syncPlaylists() async {
    try {
      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Get playlists from Spotify
      final playlists = await EnhancedSpotifyService.getUserPlaylists();
      if (playlists.isEmpty) {
        print('No playlists found');
        return true; // Not an error, just no playlists
      }

      final listsRef = _firestore
          .collection('users')
          .doc(currentUser.userId)
          .collection('music_lists');

      int syncedCount = 0;
      
      for (var playlist in playlists) {
        try {
          final String? playlistId = playlist['id'];
          final String? name = playlist['name'];
          final String? description = playlist['description'];
          final List? images = playlist['images'];
          final String? coverImageUrl = 
              images != null && images.isNotEmpty ? images[0]['url'] : null;
          final int? trackCount = playlist['tracks']?['total'];

          if (playlistId == null || name == null) continue;

          // Get playlist tracks
          final tracks = await EnhancedSpotifyService.getPlaylistTracks(playlistId);
          
          // Convert tracks to our format
          final List<Map<String, dynamic>> trackItems = tracks.map((track) {
            return {
              'id': track['id'],
              'name': track['name'],
              'artist': track['artists']?[0]?['name'] ?? 'Unknown Artist',
              'album': track['album']?['name'] ?? 'Unknown Album',
              'imageUrl': track['album']?['images']?[0]?['url'] ?? '',
              'duration_ms': track['duration_ms'] ?? 0,
              'spotifyUri': track['uri'] ?? '',
            };
          }).toList();

          // Create or update list in Firebase
          final listDoc = listsRef.doc('spotify_$playlistId');
          
          await listDoc.set({
            'id': 'spotify_$playlistId',
            'spotifyPlaylistId': playlistId,
            'name': name,
            'description': description ?? '',
            'coverImageUrl': coverImageUrl,
            'tracks': trackItems,
            'trackCount': trackItems.length,
            'isPublic': playlist['public'] ?? false,
            'isSpotifyPlaylist': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'userId': currentUser.userId,
          }, SetOptions(merge: true));

          syncedCount++;
        } catch (e) {
          print('Error syncing playlist: $e');
          continue; // Continue with next playlist
        }
      }

      print('Synced $syncedCount playlists');
      return true;
    } catch (e) {
      print('Error syncing playlists: $e');
      return false;
    }
  }

  /// Sync user's top tracks from Spotify
  static Future<bool> syncTopTracks({String timeRange = 'medium_term'}) async {
    try {
      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Get top tracks from Spotify
      final topTracks = await EnhancedSpotifyService.getTopTracks(
        timeRange: timeRange,
        limit: 50,
      );

      if (topTracks.isEmpty) {
        print('No top tracks found');
        return true;
      }

      final userRef = _firestore.collection('users').doc(currentUser.userId);
      
      // Store top tracks
      await userRef.update({
        'topTracks': topTracks.map((track) => {
          'id': track['id'],
          'name': track['name'],
          'artist': track['artists']?[0]?['name'] ?? 'Unknown',
          'album': track['album']?['name'] ?? 'Unknown',
          'imageUrl': track['album']?['images']?[0]?['url'] ?? '',
          'popularity': track['popularity'] ?? 0,
        }).toList(),
        'topTracksUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Top tracks synced successfully');
      return true;
    } catch (e) {
      print('Error syncing top tracks: $e');
      return false;
    }
  }

  /// Sync user's top artists from Spotify
  static Future<bool> syncTopArtists({String timeRange = 'medium_term'}) async {
    try {
      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Get top artists from Spotify
      final topArtists = await EnhancedSpotifyService.getTopArtists(
        timeRange: timeRange,
        limit: 50,
      );

      if (topArtists.isEmpty) {
        print('No top artists found');
        return true;
      }

      final userRef = _firestore.collection('users').doc(currentUser.userId);
      
      // Store top artists
      await userRef.update({
        'topArtists': topArtists.map((artist) => {
          'id': artist['id'],
          'name': artist['name'],
          'imageUrl': artist['images']?[0]?['url'] ?? '',
          'genres': artist['genres'] ?? [],
          'popularity': artist['popularity'] ?? 0,
        }).toList(),
        'topArtistsUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Top artists synced successfully');
      return true;
    } catch (e) {
      print('Error syncing top artists: $e');
      return false;
    }
  }

  /// Sync recently played tracks
  static Future<bool> syncRecentlyPlayed() async {
    try {
      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Get recently played from Spotify
      final recentlyPlayed = await EnhancedSpotifyService.getRecentlyPlayed(
        limit: 50,
      );

      if (recentlyPlayed.isEmpty) {
        print('No recently played tracks found');
        return true;
      }

      final userRef = _firestore.collection('users').doc(currentUser.userId);
      
      // Store recently played
      await userRef.update({
        'recentlyPlayed': recentlyPlayed.map((item) {
          final track = item['track'];
          return {
            'id': track['id'],
            'name': track['name'],
            'artist': track['artists']?[0]?['name'] ?? 'Unknown',
            'album': track['album']?['name'] ?? 'Unknown',
            'imageUrl': track['album']?['images']?[0]?['url'] ?? '',
            'playedAt': item['played_at'],
          };
        }).toList(),
        'recentlyPlayedUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Recently played synced successfully');
      return true;
    } catch (e) {
      print('Error syncing recently played: $e');
      return false;
    }
  }

  /// Full sync - profile, playlists, and listening history
  static Future<Map<String, bool>> fullSync() async {
    print('Starting full Spotify sync...');
    
    final results = <String, bool>{};
    
    // Sync profile
    results['profile'] = await syncUserProfile();
    
    // Sync playlists
    results['playlists'] = await syncPlaylists();
    
    // Sync top tracks
    results['topTracks'] = await syncTopTracks();
    
    // Sync top artists
    results['topArtists'] = await syncTopArtists();
    
    // Sync recently played
    results['recentlyPlayed'] = await syncRecentlyPlayed();
    
    print('Full sync completed: $results');
    return results;
  }

  /// Get user's synced playlists from Firebase
  static Future<List<MusicList>> getSyncedPlaylists() async {
    try {
      final currentUser = FirebaseBypassAuthService.currentUser;
      if (currentUser == null) {
        return [];
      }

      final listsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.userId)
          .collection('music_lists')
          .where('isSpotifyPlaylist', isEqualTo: true)
          .get();

      return listsSnapshot.docs.map((doc) {
        final data = doc.data();
        return MusicList(
          id: data['id'] ?? '',
          userId: data['userId'] ?? '',
          title: data['name'] ?? '',
          description: data['description'],
          trackIds: List<String>.from(data['tracks']?.map((t) => t['id'] ?? '') ?? []),
          isPublic: data['isPublic'] ?? false,
          coverImage: data['coverImageUrl'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting synced playlists: $e');
      return [];
    }
  }
}
