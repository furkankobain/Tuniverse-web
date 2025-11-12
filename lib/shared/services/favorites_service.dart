import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firebase_service.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's favorites collection reference
  static CollectionReference _getFavoritesCollection() {
    final userId = FirebaseService.auth.currentUser?.uid;
    if (userId == null) {
      // Use a non-writable placeholder path when not authenticated
      return _firestore.collection('users').doc('_unauthenticated_').collection('favorites');
    }
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  /// Add track to favorites
  static Future<bool> addTrackToFavorites(Map<String, dynamic> track) async {
    try {
      final trackId = track['id'] as String;
      final favoriteData = {
        'id': trackId,
        'type': 'track',
        'name': track['name'],
        'artists': track['artists'],
        'album': track['album'],
        'duration_ms': track['duration_ms'],
        'popularity': track['popularity'],
        'preview_url': track['preview_url'],
        'external_urls': track['external_urls'],
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _getFavoritesCollection().doc('track_$trackId').set(favoriteData);
      return true;
    } catch (e) {
      print('Error adding track to favorites: $e');
      return false;
    }
  }

  /// Remove track from favorites
  static Future<bool> removeTrackFromFavorites(String trackId) async {
    try {
      await _getFavoritesCollection().doc('track_$trackId').delete();
      return true;
    } catch (e) {
      print('Error removing track from favorites: $e');
      return false;
    }
  }

  /// Check if track is in favorites
  static Future<bool> isTrackFavorite(String trackId) async {
    try {
      final doc = await _getFavoritesCollection().doc('track_$trackId').get();
      return doc.exists;
    } catch (e) {
      print('Error checking track favorite: $e');
      return false;
    }
  }

  /// Add album to favorites
  static Future<bool> addAlbumToFavorites(Map<String, dynamic> album) async {
    try {
      final albumId = album['id'] as String;
      final favoriteData = {
        'id': albumId,
        'type': 'album',
        'name': album['name'],
        'artists': album['artists'],
        'images': album['images'],
        'release_date': album['release_date'],
        'total_tracks': album['total_tracks'],
        'external_urls': album['external_urls'],
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _getFavoritesCollection().doc('album_$albumId').set(favoriteData);
      return true;
    } catch (e) {
      print('Error adding album to favorites: $e');
      return false;
    }
  }

  /// Remove album from favorites
  static Future<bool> removeAlbumFromFavorites(String albumId) async {
    try {
      await _getFavoritesCollection().doc('album_$albumId').delete();
      return true;
    } catch (e) {
      print('Error removing album from favorites: $e');
      return false;
    }
  }

  /// Check if album is in favorites
  static Future<bool> isAlbumFavorite(String albumId) async {
    try {
      final doc = await _getFavoritesCollection().doc('album_$albumId').get();
      return doc.exists;
    } catch (e) {
      print('Error checking album favorite: $e');
      return false;
    }
  }

  /// Get all favorite tracks
  static Stream<List<Map<String, dynamic>>> getFavoriteTracks() {
    return _getFavoritesCollection()
        .where('type', isEqualTo: 'track')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      }).toList();
    });
  }

  /// Get all favorite albums
  static Stream<List<Map<String, dynamic>>> getFavoriteAlbums() {
    return _getFavoritesCollection()
        .where('type', isEqualTo: 'album')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      }).toList();
    });
  }

  /// Get all favorites (tracks and albums combined)
  static Stream<List<Map<String, dynamic>>> getAllFavorites() {
    return _getFavoritesCollection()
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      }).toList();
    });
  }

  /// Add artist to favorites
  static Future<bool> addArtistToFavorites(Map<String, dynamic> artist) async {
    try {
      final artistId = artist['id'] as String;
      final favoriteData = {
        'id': artistId,
        'type': 'artist',
        'name': artist['name'],
        'genres': artist['genres'],
        'images': artist['images'],
        'popularity': artist['popularity'],
        'followers': artist['followers'],
        'external_urls': artist['external_urls'],
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _getFavoritesCollection().doc('artist_$artistId').set(favoriteData);
      return true;
    } catch (e) {
      print('Error adding artist to favorites: $e');
      return false;
    }
  }

  /// Remove artist from favorites
  static Future<bool> removeArtistFromFavorites(String artistId) async {
    try {
      await _getFavoritesCollection().doc('artist_$artistId').delete();
      return true;
    } catch (e) {
      print('Error removing artist from favorites: $e');
      return false;
    }
  }

  /// Check if artist is in favorites
  static Future<bool> isArtistFavorite(String artistId) async {
    try {
      final doc = await _getFavoritesCollection().doc('artist_$artistId').get();
      return doc.exists;
    } catch (e) {
      print('Error checking artist favorite: $e');
      return false;
    }
  }

  /// Get all favorite artists
  static Stream<List<Map<String, dynamic>>> getFavoriteArtists() {
    return _getFavoritesCollection()
        .where('type', isEqualTo: 'artist')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      }).toList();
    });
  }

  /// Toggle artist favorite
  static Future<bool> toggleArtistFavorite(Map<String, dynamic> artist) async {
    final artistId = artist['id'] as String;
    final isFavorite = await isArtistFavorite(artistId);
    
    if (isFavorite) {
      return await removeArtistFromFavorites(artistId);
    } else {
      return await addArtistToFavorites(artist);
    }
  }

  /// Get favorites count
  static Future<Map<String, int>> getFavoritesCount() async {
    try {
      final snapshot = await _getFavoritesCollection().get();
      int trackCount = 0;
      int albumCount = 0;
      int artistCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'track') {
          trackCount++;
        } else if (type == 'album') {
          albumCount++;
        } else if (type == 'artist') {
          artistCount++;
        }
      }

      return {
        'tracks': trackCount,
        'albums': albumCount,
        'artists': artistCount,
        'total': trackCount + albumCount + artistCount,
      };
    } catch (e) {
      print('Error getting favorites count: $e');
      return {'tracks': 0, 'albums': 0, 'artists': 0, 'total': 0};
    }
  }

  /// Toggle track favorite
  static Future<bool> toggleTrackFavorite(Map<String, dynamic> track) async {
    final trackId = track['id'] as String;
    final isFavorite = await isTrackFavorite(trackId);
    
    if (isFavorite) {
      return await removeTrackFromFavorites(trackId);
    } else {
      return await addTrackToFavorites(track);
    }
  }

  /// Toggle album favorite
  static Future<bool> toggleAlbumFavorite(Map<String, dynamic> album) async {
    final albumId = album['id'] as String;
    final isFavorite = await isAlbumFavorite(albumId);
    
    if (isFavorite) {
      return await removeAlbumFromFavorites(albumId);
    } else {
      return await addAlbumToFavorites(album);
    }
  }
}
