import 'package:cloud_firestore/cloud_firestore.dart';
import 'favorites_service.dart';

/// Analytics service for user listening insights and statistics
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== LISTENING CLOCK ====================
  
  /// Get listening activity by hour of day
  static Future<Map<int, int>> getListeningClock(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listeningHistory')
          .get();
      
      // Initialize hours (0-23)
      final hourlyData = <int, int>{};
      for (int i = 0; i < 24; i++) {
        hourlyData[i] = 0;
      }
      
      // Count plays per hour
      for (final doc in snapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final hour = timestamp.hour;
          hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
        }
      }
      
      return hourlyData;
    } catch (e) {
      print('Error getting listening clock: $e');
      return {};
    }
  }

  /// Get peak listening time
  static Future<String> getPeakListeningTime(String userId) async {
    final clock = await getListeningClock(userId);
    
    if (clock.isEmpty) return 'No data';
    
    var maxHour = 0;
    var maxCount = 0;
    
    clock.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        maxHour = hour;
      }
    });
    
    return '${maxHour.toString().padLeft(2, '0')}:00 - ${(maxHour + 1).toString().padLeft(2, '0')}:00';
  }

  // ==================== MUSIC MAP ====================
  
  /// Get artist locations for music map visualization
  static Future<List<Map<String, dynamic>>> getArtistLocations(String userId) async {
    try {
      // Get user's favorite artists
      final favoritesSnapshot = await FavoritesService.getFavoriteArtists().first;
      
      final locations = <Map<String, dynamic>>[];
      
      for (final artist in favoritesSnapshot) {
        // In a real app, you'd fetch this from an API or database
        // For now, return mock locations based on common artist origins
        final location = _getArtistOrigin(artist['name'] as String);
        if (location != null) {
          locations.add({
            'artist': artist['name'],
            'latitude': location['lat'],
            'longitude': location['lng'],
            'country': location['country'],
          });
        }
      }
      
      return locations;
    } catch (e) {
      print('Error getting artist locations: $e');
      return [];
    }
  }

  /// Get artist origin (mock data - in real app fetch from API)
  static Map<String, dynamic>? _getArtistOrigin(String artistName) {
    // Mock data - in production, use a proper music API
    final origins = {
      'The Beatles': {'country': 'UK', 'lat': 53.4084, 'lng': -2.9916}, // Liverpool
      'Drake': {'country': 'Canada', 'lat': 43.6532, 'lng': -79.3832}, // Toronto
      'BTS': {'country': 'South Korea', 'lat': 37.5665, 'lng': 126.9780}, // Seoul
      'Ed Sheeran': {'country': 'UK', 'lat': 52.0569, 'lng': 1.1482}, // Ipswich
      'Bad Bunny': {'country': 'Puerto Rico', 'lat': 18.4663, 'lng': -66.1057}, // San Juan
    };
    
    return origins[artistName];
  }

  /// Get country distribution
  static Future<Map<String, int>> getCountryDistribution(String userId) async {
    final locations = await getArtistLocations(userId);
    final distribution = <String, int>{};
    
    for (final location in locations) {
      final country = location['country'] as String;
      distribution[country] = (distribution[country] ?? 0) + 1;
    }
    
    return distribution;
  }

  // ==================== TASTE PROFILE ====================
  
  /// Get detailed taste profile
  static Future<Map<String, dynamic>> getTasteProfile(String userId) async {
    try {
      final profile = <String, dynamic>{};
      
      // Get favorite tracks
      final tracks = await FavoritesService.getFavoriteTracks().first;
      
      if (tracks.isEmpty) {
        return {'error': 'No listening data'};
      }
      
      // Analyze genres
      final genres = <String, int>{};
      final decades = <String, int>{};
      final moods = <String, int>{};
      
      for (final track in tracks) {
        // Extract genres from artists
        final artists = track['artists'] as List?;
        if (artists != null && artists.isNotEmpty) {
          final artist = artists.first;
          final artistGenres = artist['genres'] as List?;
          if (artistGenres != null) {
            for (final genre in artistGenres) {
              genres[genre as String] = (genres[genre] ?? 0) + 1;
            }
          }
        }
        
        // Extract decade from release date
        final releaseDate = track['album']?['release_date'] as String?;
        if (releaseDate != null && releaseDate.length >= 4) {
          final year = int.tryParse(releaseDate.substring(0, 4));
          if (year != null) {
            final decade = '${(year ~/ 10) * 10}s';
            decades[decade] = (decades[decade] ?? 0) + 1;
          }
        }
      }
      
      // Get top genres
      final sortedGenres = genres.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      profile['topGenres'] = sortedGenres.take(5).map((e) => {
        'genre': e.key,
        'count': e.value,
        'percentage': (e.value / tracks.length * 100).toStringAsFixed(1),
      }).toList();
      
      // Get top decades
      final sortedDecades = decades.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      profile['topDecades'] = sortedDecades.take(3).map((e) => {
        'decade': e.key,
        'count': e.value,
        'percentage': (e.value / tracks.length * 100).toStringAsFixed(1),
      }).toList();
      
      // Calculate diversity score (0-100)
      profile['diversityScore'] = _calculateDiversityScore(genres);
      
      // Get listening personality
      profile['personality'] = _getListeningPersonality(genres, decades);
      
      return profile;
    } catch (e) {
      print('Error getting taste profile: $e');
      return {};
    }
  }

  /// Calculate diversity score based on genre distribution
  static int _calculateDiversityScore(Map<String, int> genres) {
    if (genres.isEmpty) return 0;
    
    final total = genres.values.reduce((a, b) => a + b);
    var entropy = 0.0;
    
    for (final count in genres.values) {
      final p = count / total;
      if (p > 0) {
        entropy -= p * (p.clamp(0.001, 1.0)).toDouble();
      }
    }
    
    // Normalize to 0-100
    final maxEntropy = 4.0; // log2(16) - assuming max ~16 genres
    return ((entropy / maxEntropy) * 100).clamp(0, 100).toInt();
  }

  /// Determine listening personality
  static String _getListeningPersonality(Map<String, int> genres, Map<String, int> decades) {
    final diversityScore = _calculateDiversityScore(genres);
    
    if (diversityScore > 75) {
      return 'The Eclectic Explorer 🌍';
    } else if (diversityScore > 50) {
      return 'The Balanced Listener 🎧';
    } else if (genres.keys.any((g) => g.contains('rock') || g.contains('metal'))) {
      return 'The Rock Enthusiast 🎸';
    } else if (genres.keys.any((g) => g.contains('pop'))) {
      return 'The Pop Aficionado 🎤';
    } else if (genres.keys.any((g) => g.contains('hip hop') || g.contains('rap'))) {
      return 'The Hip Hop Head 🎵';
    } else if (decades.keys.any((d) => d.contains('80') || d.contains('90'))) {
      return 'The Nostalgic Soul 📻';
    } else {
      return 'The Music Lover ❤️';
    }
  }

  // ==================== YEARLY WRAPPED ====================
  
  /// Generate Yearly Wrapped summary
  static Future<Map<String, dynamic>> generateYearlyWrapped(String userId, int year) async {
    try {
      final wrapped = <String, dynamic>{};
      wrapped['year'] = year;
      
      // Get listening history for the year
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listeningHistory')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      // Total minutes listened
      var totalMinutes = 0;
      final trackCounts = <String, int>{};
      final artistCounts = <String, int>{};
      final genreCounts = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final duration = data['duration_ms'] as int? ?? 0;
        totalMinutes += (duration ~/ 60000);
        
        // Count tracks
        final trackId = data['trackId'] as String?;
        if (trackId != null) {
          trackCounts[trackId] = (trackCounts[trackId] ?? 0) + 1;
        }
        
        // Count artists
        final artistName = data['artistName'] as String?;
        if (artistName != null) {
          artistCounts[artistName] = (artistCounts[artistName] ?? 0) + 1;
        }
        
        // Count genres
        final genre = data['genre'] as String?;
        if (genre != null) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
      
      wrapped['totalMinutes'] = totalMinutes;
      wrapped['totalTracks'] = snapshot.docs.length;
      
      // Top 5 tracks
      final sortedTracks = trackCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      wrapped['topTracks'] = sortedTracks.take(5).map((e) => {
        'trackId': e.key,
        'playCount': e.value,
      }).toList();
      
      // Top 5 artists
      final sortedArtists = artistCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      wrapped['topArtists'] = sortedArtists.take(5).map((e) => {
        'artistName': e.key,
        'playCount': e.value,
      }).toList();
      
      // Top 3 genres
      final sortedGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      wrapped['topGenres'] = sortedGenres.take(3).map((e) => {
        'genre': e.key,
        'percentage': (e.value / snapshot.docs.length * 100).toStringAsFixed(1),
      }).toList();
      
      // Fun facts
      wrapped['funFacts'] = _generateFunFacts(totalMinutes, snapshot.docs.length, artistCounts);
      
      return wrapped;
    } catch (e) {
      print('Error generating yearly wrapped: $e');
      return {};
    }
  }

  /// Generate fun facts for Wrapped
  static List<String> _generateFunFacts(int totalMinutes, int totalTracks, Map<String, int> artistCounts) {
    final facts = <String>[];
    
    // Minutes fact
    if (totalMinutes > 60000) {
      facts.add('You listened to over ${(totalMinutes / 60).toStringAsFixed(0)} hours of music!');
    } else {
      facts.add('You listened to $totalMinutes minutes of music!');
    }
    
    // Track variety
    facts.add('You discovered $totalTracks different tracks!');
    
    // Top artist
    if (artistCounts.isNotEmpty) {
      final topArtist = artistCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      facts.add('${topArtist.key} was your most played artist!');
    }
    
    // Day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final avgPerDay = totalMinutes / dayOfYear;
    facts.add('You averaged ${avgPerDay.toStringAsFixed(0)} minutes per day!');
    
    return facts;
  }

  // ==================== MUSIC MAP ====================

  /// Get music map data (countries and artists)
  static Future<Map<String, dynamic>> getMusicMap(String userId) async {
    try {
      final locations = await getArtistLocations(userId);
      final distribution = await getCountryDistribution(userId);
      
      return {
        'artistLocations': locations,
        'countryDistribution': distribution,
        'totalCountries': distribution.length,
      };
    } catch (e) {
      print('Error getting music map: $e');
      return {};
    }
  }

  // ==================== YEARLY WRAPPED ====================

  /// Get yearly wrapped for current year
  static Future<Map<String, dynamic>> getYearlyWrapped(String userId) async {
    final currentYear = DateTime.now().year;
    return await generateYearlyWrapped(userId, currentYear);
  }

  // ==================== FRIENDS COMPARISON ====================

  /// Compare taste with friends
  static Future<List<Map<String, dynamic>>> compareTasteWithFriends(String userId) async {
    try {
      // Get user's friends list
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final following = List<String>.from(userDoc.data()?['following'] ?? []);
      
      if (following.isEmpty) return [];
      
      // Get user's taste profile
      final userProfile = await getTasteProfile(userId);
      final userGenres = userProfile['topGenres'] as List? ?? [];
      
      final comparisons = <Map<String, dynamic>>[];
      
      // Compare with each friend
      for (final friendId in following.take(10)) {
        try {
          final friendDoc = await _firestore.collection('users').doc(friendId).get();
          if (!friendDoc.exists) continue;
          
          final friendProfile = await getTasteProfile(friendId);
          final friendGenres = friendProfile['topGenres'] as List? ?? [];
          
          // Calculate similarity based on common genres
          final similarity = _calculateSimilarity(userGenres, friendGenres);
          
          // Get common artists
          final commonArtists = await _getCommonArtists(userId, friendId);
          
          // Get common genres
          final commonGenres = _getCommonGenres(userGenres, friendGenres);
          
          comparisons.add({
            'friendId': friendId,
            'friendName': friendDoc.data()?['displayName'] ?? 'Friend',
            'similarity': similarity,
            'commonArtists': commonArtists,
            'commonGenres': commonGenres,
          });
        } catch (e) {
          print('Error comparing with friend $friendId: $e');
        }
      }
      
      // Sort by similarity (highest first)
      comparisons.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
      
      return comparisons;
    } catch (e) {
      print('Error comparing taste with friends: $e');
      return [];
    }
  }

  /// Calculate similarity score (0.0-1.0) based on genre overlap
  static double _calculateSimilarity(List<dynamic> userGenres, List<dynamic> friendGenres) {
    if (userGenres.isEmpty || friendGenres.isEmpty) return 0.0;
    
    final userGenreNames = userGenres.map((g) => g['genre'] as String).toSet();
    final friendGenreNames = friendGenres.map((g) => g['genre'] as String).toSet();
    
    final intersection = userGenreNames.intersection(friendGenreNames).length;
    final union = userGenreNames.union(friendGenreNames).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Get common artists between two users
  static Future<List<Map<String, dynamic>>> _getCommonArtists(String userId1, String userId2) async {
    try {
      final user1Favorites = await FavoritesService.getFavoriteArtists().first;
      // For now, return a subset (in real app, query user2's favorites)
      return user1Favorites.take(3).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get common genres
  static List<String> _getCommonGenres(List<dynamic> userGenres, List<dynamic> friendGenres) {
    final userGenreNames = userGenres.map((g) => g['genre'] as String).toSet();
    final friendGenreNames = friendGenres.map((g) => g['genre'] as String).toSet();
    
    return userGenreNames.intersection(friendGenreNames).toList();
  }

  // ==================== FRIENDS COMPARISON ====================
  
  /// Compare taste with a friend
  static Future<Map<String, dynamic>> compareTasteWithFriend(String userId, String friendId) async {
    try {
      // Get both users' favorite tracks
      final userTracks = await FavoritesService.getFavoriteTracks().first;
      // Would need to fetch friend's tracks - placeholder for now
      
      final comparison = <String, dynamic>{};
      
      // Calculate similarity score (0-100)
      comparison['similarityScore'] = _calculateSimilarityScore(userTracks, []);
      
      // Common tracks
      comparison['commonTracks'] = [];
      
      // Unique preferences
      comparison['yourUnique'] = [];
      comparison['friendUnique'] = [];
      
      // Genre overlap
      comparison['genreOverlap'] = <String>[];
      
      return comparison;
    } catch (e) {
      print('Error comparing taste: $e');
      return {};
    }
  }

  /// Calculate taste similarity score
  static int _calculateSimilarityScore(List<Map<String, dynamic>> userTracks, List<Map<String, dynamic>> friendTracks) {
    if (userTracks.isEmpty || friendTracks.isEmpty) return 0;
    
    // Simple Jaccard similarity
    final userTrackIds = userTracks.map((t) => t['id']).toSet();
    final friendTrackIds = friendTracks.map((t) => t['id']).toSet();
    
    final intersection = userTrackIds.intersection(friendTrackIds).length;
    final union = userTrackIds.union(friendTrackIds).length;
    
    if (union == 0) return 0;
    
    return ((intersection / union) * 100).toInt();
  }

  /// Get compatibility description
  static String getCompatibilityDescription(int score) {
    if (score >= 80) return 'Musical Soulmates! 💕';
    if (score >= 60) return 'Great Taste Match! 🎵';
    if (score >= 40) return 'Some Common Ground 👍';
    if (score >= 20) return 'Different Vibes 🎭';
    return 'Opposite Ends! 🌓';
  }
}
