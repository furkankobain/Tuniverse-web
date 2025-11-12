import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// Last.fm API Service for track ratings and metadata
/// Get your API key from: https://www.last.fm/api/account/create
class LastFmService {
  static const String _apiKey = 'c4ba70b84c3df6294775863ab41865e8';
  static const String _sharedSecret = 'ec2feb05d1db45c641d65817fcb0a220'; // For future OAuth if needed
  static const String _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  /// Get track info including play count and listeners
  static Future<Map<String, dynamic>?> getTrackInfo({
    required String artist,
    required String track,
  }) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'track.getInfo',
        'api_key': _apiKey,
        'artist': artist,
        'track': track,
        'format': 'json',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['track'] != null) {
          final track = data['track'];
          return {
            'name': track['name'],
            'artist': track['artist']['name'],
            'playcount': int.tryParse(track['playcount']?.toString() ?? '0') ?? 0,
            'listeners': int.tryParse(track['listeners']?.toString() ?? '0') ?? 0,
            'userplaycount': int.tryParse(track['userplaycount']?.toString() ?? '0') ?? 0,
            'duration': int.tryParse(track['duration']?.toString() ?? '0') ?? 0,
            'tags': (track['toptags']?['tag'] as List?)
                ?.map((tag) => tag['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList() ?? [],
            'albumImage': _extractLargestImage(track['album']?['image']),
            'wiki': track['wiki']?['summary'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Last.fm API error (getTrackInfo): $e');
      return null;
    }
  }

  /// Get album info including play count and listeners
  static Future<Map<String, dynamic>?> getAlbumInfo({
    required String artist,
    required String album,
  }) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'album.getInfo',
        'api_key': _apiKey,
        'artist': artist,
        'album': album,
        'format': 'json',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['album'] != null) {
          final album = data['album'];
          return {
            'name': album['name'],
            'artist': album['artist'],
            'playcount': int.tryParse(album['playcount']?.toString() ?? '0') ?? 0,
            'listeners': int.tryParse(album['listeners']?.toString() ?? '0') ?? 0,
            'tags': (album['tags']?['tag'] as List?)
                ?.map((tag) => tag['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList() ?? [],
            'image': _extractLargestImage(album['image']),
            'wiki': album['wiki']?['summary'],
            'tracks': (album['tracks']?['track'] as List?)
                ?.map((track) => track['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList() ?? [],
          };
        }
      }
      return null;
    } catch (e) {
      print('Last.fm API error (getAlbumInfo): $e');
      return null;
    }
  }

  /// Get similar tracks
  static Future<List<Map<String, dynamic>>> getSimilarTracks({
    required String artist,
    required String track,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'track.getSimilar',
        'api_key': _apiKey,
        'artist': artist,
        'track': track,
        'limit': limit.toString(),
        'format': 'json',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['similartracks']?['track'] != null) {
          final tracks = data['similartracks']['track'] as List;
          return tracks.map((track) {
            return {
              'name': track['name'],
              'artist': track['artist']?['name'],
              'image': _extractLargestImage(track['image']),
              'match': double.tryParse(track['match']?.toString() ?? '0') ?? 0.0,
              'url': track['url'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Last.fm API error (getSimilarTracks): $e');
      return [];
    }
  }

  /// Get top tracks globally or by country
  static Future<List<Map<String, dynamic>>> getTopTracks({
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'chart.getTopTracks',
        'api_key': _apiKey,
        'limit': limit.toString(),
        'page': page.toString(),
        'format': 'json',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['tracks']?['track'] != null) {
          final tracks = data['tracks']['track'] as List;
          return tracks.map((track) {
            return {
              'name': track['name'],
              'artist': track['artist']?['name'],
              'playcount': int.tryParse(track['playcount']?.toString() ?? '0') ?? 0,
              'listeners': int.tryParse(track['listeners']?.toString() ?? '0') ?? 0,
              'image': _extractLargestImage(track['image']),
              'url': track['url'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Last.fm API error (getTopTracks): $e');
      return [];
    }
  }

  /// Get similar artists
  static Future<List<Map<String, dynamic>>> getSimilarArtists({
    required String artist,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'artist.getSimilar',
        'api_key': _apiKey,
        'artist': artist,
        'limit': limit.toString(),
        'format': 'json',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['similarartists']?['artist'] != null) {
          final artists = data['similarartists']['artist'] as List;
          return artists.map((artist) {
            return {
              'name': artist['name'],
              'image': _extractLargestImage(artist['image']),
              'url': artist['url'],
              'match': double.tryParse(artist['match']?.toString() ?? '0') ?? 0.0,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Last.fm API error (getSimilarArtists): $e');
      return [];
    }
  }

  /// Get artist info
  static Future<Map<String, dynamic>?> getArtistInfo({
    required String artist,
  }) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'artist.getInfo',
        'api_key': _apiKey,
        'artist': artist,
        'format': 'json',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['artist'] != null) {
          final artist = data['artist'];
          return {
            'name': artist['name'],
            'playcount': int.tryParse(artist['stats']?['playcount']?.toString() ?? '0') ?? 0,
            'listeners': int.tryParse(artist['stats']?['listeners']?.toString() ?? '0') ?? 0,
            'image': _extractLargestImage(artist['image']),
            'bio': artist['bio']?['summary'],
            'tags': (artist['tags']?['tag'] as List?)
                ?.map((tag) => tag['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList() ?? [],
            'url': artist['url'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Last.fm API error (getArtistInfo): $e');
      return null;
    }
  }

  /// Calculate a rating score from Last.fm data (0-10 scale)
  static double calculateRating({
    required int playcount,
    required int listeners,
  }) {
    if (playcount == 0 || listeners == 0) return 0.0;

    // Calculate average plays per listener
    final avgPlaysPerListener = playcount / listeners;
    
    // Normalize playcount (log scale)
    final normalizedPlaycount = (playcount.toDouble().clamp(1.0, 1000000000.0)).log10() / 9; // Max 1B plays = 9
    
    // Normalize listeners (log scale)
    final normalizedListeners = (listeners.toDouble().clamp(1.0, 100000000.0)).log10() / 8; // Max 100M listeners = 8
    
    // Normalize avg plays per listener (log scale, more plays = more engaging)
    final normalizedAvgPlays = (avgPlaysPerListener.clamp(1.0, 1000.0)).log10() / 3; // Max 1000 avg plays
    
    // Weight: 40% playcount, 40% listeners, 20% engagement
    final score = (normalizedPlaycount * 0.4) + 
                  (normalizedListeners * 0.4) + 
                  (normalizedAvgPlays * 0.2);
    
    // Scale to 0-10
    return (score * 10).clamp(0, 10);
  }

  /// Extract largest image from Last.fm image array
  static String? _extractLargestImage(dynamic images) {
    if (images == null) return null;
    
    try {
      final imageList = images as List;
      // Last.fm provides: small, medium, large, extralarge, mega
      // Get the largest available
      for (var size in ['mega', 'extralarge', 'large', 'medium']) {
        final image = imageList.firstWhere(
          (img) => img['size'] == size,
          orElse: () => null,
        );
        if (image != null && image['#text']?.toString().isNotEmpty == true) {
          return image['#text'];
        }
      }
      
      // Fallback to any image
      if (imageList.isNotEmpty && imageList.first['#text']?.toString().isNotEmpty == true) {
        return imageList.first['#text'];
      }
    } catch (e) {
      print('Error extracting image: $e');
    }
    
    return null;
  }
}

/// Extension for log10
extension DoubleLog on double {
  double log10() => math.log(this) / 2.302585092994046; // ln(10)
}
