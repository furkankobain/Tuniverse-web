import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/music_list.dart';
import 'enhanced_spotify_service.dart';
import 'playlist_service.dart';
import 'firebase_service.dart';

class PlaylistSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Import Spotify playlists to Firebase
  static Future<List<String>> importSpotifyPlaylists(List<String> playlistIds) async {
    final List<String> importedIds = [];
    final currentUser = FirebaseService.auth.currentUser;
    if (currentUser == null) {
      print('❌ No user logged in for playlist import');
      return importedIds;
    }
    final userId = currentUser.uid;
    print('🎵 Starting import of ${playlistIds.length} playlists for user: $userId');

    for (final spotifyId in playlistIds) {
      try {
        print('📥 Importing playlist: $spotifyId');
        // Get playlist details from Spotify
        final rawPlaylistData = await EnhancedSpotifyService.getPlaylistDetails(spotifyId);
        if (rawPlaylistData == null) {
          print('⚠️ Failed to get playlist details for: $spotifyId');
          continue;
        }

        // Get tracks
        final tracks = await EnhancedSpotifyService.getPlaylistTracks(spotifyId);
        final trackIds = tracks.map((t) => t['id'] as String).where((id) => id.isNotEmpty).toList();

        // Create in Firebase
        final now = DateTime.now();
        final coverImage = rawPlaylistData['images'] != null && (rawPlaylistData['images'] as List).isNotEmpty
            ? rawPlaylistData['images'][0]['url']
            : null;

        final playlist = MusicList(
          id: '',
          userId: userId,
          title: rawPlaylistData['name'] ?? 'Unnamed Playlist',
          description: rawPlaylistData['description'],
          trackIds: trackIds,
          isPublic: rawPlaylistData['public'] ?? true,
          coverImage: coverImage,
          createdAt: now,
          updatedAt: now,
          source: 'spotify',
          spotifyId: spotifyId,
        );

        final docRef = await _firestore
            .collection('playlists')
            .add(playlist.toFirestore());

        importedIds.add(docRef.id);
        print('✅ Successfully imported playlist: ${playlist.title} (ID: ${docRef.id})');
      } catch (e) {
        print('❌ Error importing playlist $spotifyId: $e');
      }
    }

    print('🎉 Import complete! Successfully imported ${importedIds.length} playlists');
    return importedIds;
  }

  /// Export local playlist to Spotify
  static Future<String?> exportToSpotify(String playlistId) async {
    try {
      // Get local playlist
      final playlist = await PlaylistService.getPlaylist(playlistId);
      if (playlist == null || playlist.source != 'local') return null;

      // Create on Spotify
      final spotifyId = await EnhancedSpotifyService.createPlaylistOnSpotify(
        name: playlist.title,
        description: playlist.description ?? '',
        isPublic: playlist.isPublic,
      );

      if (spotifyId == null) return null;

      // Add tracks to Spotify playlist
      if (playlist.trackIds.isNotEmpty) {
        final trackUris = playlist.trackIds
            .map((id) => 'spotify:track:$id')
            .toList();
        
        await EnhancedSpotifyService.addTracksToSpotifyPlaylist(
          spotifyId,
          trackUris,
        );
      }

      // Update local playlist to mark as synced
      await PlaylistService.updatePlaylist(
        playlistId: playlistId,
      );

      await _firestore.collection('playlists').doc(playlistId).update({
        'source': 'synced',
        'spotifyId': spotifyId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return spotifyId;
    } catch (e) {
      print('Error exporting playlist to Spotify: $e');
      return null;
    }
  }

  /// Sync a playlist from Spotify to Firebase
  static Future<bool> syncFromSpotify(String playlistId) async {
    try {
      final playlist = await PlaylistService.getPlaylist(playlistId);
      if (playlist == null || playlist.spotifyId == null) return false;

      // Get updated tracks from Spotify
      final tracks = await EnhancedSpotifyService.getPlaylistTracks(playlist.spotifyId!);
      final trackIds = tracks.map((t) => t['id'] as String).where((id) => id.isNotEmpty).toList();

      // Update Firebase
      await _firestore.collection('playlists').doc(playlistId).update({
        'trackIds': trackIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error syncing from Spotify: $e');
      return false;
    }
  }

  /// Sync a playlist from Firebase to Spotify
  static Future<bool> syncToSpotify(String playlistId) async {
    try {
      final playlist = await PlaylistService.getPlaylist(playlistId);
      if (playlist == null || playlist.spotifyId == null) return false;

      // Get current Spotify tracks
      final spotifyTracks = await EnhancedSpotifyService.getPlaylistTracks(playlist.spotifyId!);
      final spotifyTrackIds = spotifyTracks.map((t) => t['id'] as String).where((id) => id.isNotEmpty).toSet();
      final localTrackIds = playlist.trackIds.toSet();

      // Find differences
      final toAdd = localTrackIds.difference(spotifyTrackIds).toList();
      final toRemove = spotifyTrackIds.difference(localTrackIds).toList();

      // Add new tracks
      if (toAdd.isNotEmpty) {
        final trackUris = toAdd.map((id) => 'spotify:track:$id').toList();
        await EnhancedSpotifyService.addTracksToSpotifyPlaylist(
          playlist.spotifyId!,
          trackUris,
        );
      }

      // Remove old tracks
      if (toRemove.isNotEmpty) {
        final trackUris = toRemove.map((id) => 'spotify:track:$id').toList();
        await EnhancedSpotifyService.removeTracksFromSpotifyPlaylist(
          playlist.spotifyId!,
          trackUris,
        );
      }

      // Update metadata if changed
      await EnhancedSpotifyService.updateSpotifyPlaylist(
        playlistId: playlist.spotifyId!,
        name: playlist.title,
        description: playlist.description,
        isPublic: playlist.isPublic,
      );

      return true;
    } catch (e) {
      print('Error syncing to Spotify: $e');
      return false;
    }
  }

  /// Two-way sync: sync both directions
  static Future<bool> bidirectionalSync(String playlistId) async {
    try {
      // First sync from Spotify to get latest
      await syncFromSpotify(playlistId);
      
      // Then sync to Spotify with any local changes
      await syncToSpotify(playlistId);
      
      return true;
    } catch (e) {
      print('Error in bidirectional sync: $e');
      return false;
    }
  }

  /// Unlink playlist from Spotify
  static Future<bool> unlinkFromSpotify(String playlistId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'source': 'local',
        'spotifyId': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error unlinking from Spotify: $e');
      return false;
    }
  }

  /// Get sync status for a playlist
  static Future<Map<String, dynamic>> getSyncStatus(String playlistId) async {
    try {
      final playlist = await PlaylistService.getPlaylist(playlistId);
      if (playlist == null) {
        return {'synced': false, 'error': 'Playlist not found'};
      }

      if (playlist.source == 'local') {
        return {
          'synced': false,
          'source': 'local',
          'message': 'Local playlist, not synced with Spotify',
        };
      }

      if (playlist.spotifyId == null) {
        return {
          'synced': false,
          'source': playlist.source,
          'error': 'No Spotify ID',
        };
      }

      // Check if tracks match
      final spotifyTracks = await EnhancedSpotifyService.getPlaylistTracks(playlist.spotifyId!);
      final spotifyTrackIds = spotifyTracks.map((t) => t['id'] as String).where((id) => id.isNotEmpty).toSet();
      final localTrackIds = playlist.trackIds.toSet();

      final inSync = spotifyTrackIds.length == localTrackIds.length &&
                     spotifyTrackIds.difference(localTrackIds).isEmpty;

      return {
        'synced': inSync,
        'source': playlist.source,
        'spotifyId': playlist.spotifyId,
        'localTracks': localTrackIds.length,
        'spotifyTracks': spotifyTrackIds.length,
        'needsSync': !inSync,
      };
    } catch (e) {
      return {'synced': false, 'error': e.toString()};
    }
  }
}
