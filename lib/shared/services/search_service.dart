import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Search for tracks in user ratings
  static Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final results = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final List<Map<String, dynamic>> tracks = [];
      
      for (var doc in results.docs) {
        final data = doc.data();
        final trackName = data['trackName']?.toString().toLowerCase() ?? '';
        final artistName = data['artists']?.toString().toLowerCase() ?? '';
        final albumName = data['albumName']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        if (trackName.contains(searchQuery) || 
            artistName.contains(searchQuery) || 
            albumName.contains(searchQuery)) {
          tracks.add({
            'id': doc.id,
            'trackName': data['trackName'],
            'artists': data['artists'],
            'albumName': data['albumName'],
            'albumImage': data['albumImage'],
            'rating': data['rating'],
            'review': data['review'],
            'tags': data['tags'] ?? [],
            'createdAt': data['createdAt'],
            'type': 'user_track',
          });
        }
      }

      // Sort by relevance (exact matches first, then partial matches)
      tracks.sort((a, b) {
        final aTrack = a['trackName']?.toString().toLowerCase() ?? '';
        final aArtist = a['artists']?.toString().toLowerCase() ?? '';
        final bTrack = b['trackName']?.toString().toLowerCase() ?? '';
        final bArtist = b['artists']?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();

        final aExactMatch = aTrack == queryLower || aArtist == queryLower;
        final bExactMatch = bTrack == queryLower || bArtist == queryLower;

        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;
        return 0;
      });

      return tracks;
    } catch (e) {
      return [];
    }
  }

  /// Search for artists
  static Future<List<Map<String, dynamic>>> searchArtists(String query) async {
    if (query.isEmpty) return [];

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final results = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final Map<String, Map<String, dynamic>> artistMap = {};
      
      for (var doc in results.docs) {
        final data = doc.data();
        final artistName = data['artists']?.toString() ?? '';
        final queryLower = query.toLowerCase();
        final artistLower = artistName.toLowerCase();

        if (artistLower.contains(queryLower)) {
          if (!artistMap.containsKey(artistName)) {
            artistMap[artistName] = {
              'name': artistName,
              'trackCount': 0,
              'averageRating': 0.0,
              'tracks': <String>[],
              'type': 'artist',
            };
          }

          final artist = artistMap[artistName]!;
          artist['trackCount'] = (artist['trackCount'] as int) + 1;
          artist['tracks'].add(data['trackName']?.toString() ?? '');
          
          // Calculate average rating
          final currentAvg = artist['averageRating'] as double;
          final trackRating = (data['rating'] as int? ?? 0).toDouble();
          final newAvg = (currentAvg * ((artist['trackCount'] as int) - 1) + trackRating) / (artist['trackCount'] as int);
          artist['averageRating'] = newAvg;
        }
      }

      final List<Map<String, dynamic>> artists = artistMap.values.toList();
      
      // Sort by track count and average rating
      artists.sort((a, b) {
        final aCount = a['trackCount'] as int;
        final bCount = b['trackCount'] as int;
        if (aCount != bCount) return bCount.compareTo(aCount);
        
        final aRating = a['averageRating'] as double;
        final bRating = b['averageRating'] as double;
        return bRating.compareTo(aRating);
      });

      return artists;
    } catch (e) {
      return [];
    }
  }

  /// Search for albums
  static Future<List<Map<String, dynamic>>> searchAlbums(String query) async {
    if (query.isEmpty) return [];

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final results = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final Map<String, Map<String, dynamic>> albumMap = {};
      
      for (var doc in results.docs) {
        final data = doc.data();
        final albumName = data['albumName']?.toString() ?? '';
        final artistName = data['artists']?.toString() ?? '';
        final queryLower = query.toLowerCase();
        final albumLower = albumName.toLowerCase();

        if (albumLower.contains(queryLower)) {
          final albumKey = '$albumName - $artistName';
          
          if (!albumMap.containsKey(albumKey)) {
            albumMap[albumKey] = {
              'name': albumName,
              'artist': artistName,
              'trackCount': 0,
              'averageRating': 0.0,
              'albumImage': data['albumImage'],
              'tracks': <String>[],
              'type': 'album',
            };
          }

          final album = albumMap[albumKey]!;
          album['trackCount'] = (album['trackCount'] as int) + 1;
          album['tracks'].add(data['trackName']?.toString() ?? '');
          
          // Calculate average rating
          final currentAvg = album['averageRating'] as double;
          final trackRating = (data['rating'] as int? ?? 0).toDouble();
          final newAvg = (currentAvg * ((album['trackCount'] as int) - 1) + trackRating) / (album['trackCount'] as int);
          album['averageRating'] = newAvg;
        }
      }

      final List<Map<String, dynamic>> albums = albumMap.values.toList();
      
      // Sort by track count and average rating
      albums.sort((a, b) {
        final aCount = a['trackCount'] as int;
        final bCount = b['trackCount'] as int;
        if (aCount != bCount) return bCount.compareTo(aCount);
        
        final aRating = a['averageRating'] as double;
        final bRating = b['averageRating'] as double;
        return bRating.compareTo(aRating);
      });

      return albums;
    } catch (e) {
      return [];
    }
  }

  /// Get search suggestions based on user's previous searches
  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get user's recent ratings for suggestions
      final results = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final Set<String> suggestions = {};
      final queryLower = query.toLowerCase();

      for (var doc in results.docs) {
        final data = doc.data();
        
        final trackName = data['trackName']?.toString() ?? '';
        final artistName = data['artists']?.toString() ?? '';
        final albumName = data['albumName']?.toString() ?? '';

        if (trackName.toLowerCase().contains(queryLower)) {
          suggestions.add(trackName);
        }
        if (artistName.toLowerCase().contains(queryLower)) {
          suggestions.add(artistName);
        }
        if (albumName.toLowerCase().contains(queryLower)) {
          suggestions.add('$albumName - $artistName');
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get trending searches (mock data for now)
  static List<String> getTrendingSearches() {
    return [
      'Taylor Swift',
      'Harry Styles',
      'The Weeknd',
      'Bad Bunny',
      'Billie Eilish',
      'Ed Sheeran',
      'Ariana Grande',
      'Post Malone',
    ];
  }

  /// Save search history
  static Future<void> saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final searchHistoryRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('search_history')
          .doc();

      await searchHistoryRef.set({
        'query': query.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get user's search history
  static Future<List<Map<String, dynamic>>> getSearchHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final results = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return results.docs.map((doc) => {
        'query': doc.data()['query'],
        'timestamp': doc.data()['timestamp'],
        'id': doc.id,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear search history
  static Future<void> clearSearchHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      final searchHistoryRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('search_history');

      final snapshot = await searchHistoryRef.get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      // Handle error silently
    }
  }
}
