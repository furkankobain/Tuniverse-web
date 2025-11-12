import 'dart:convert';
import 'package:http/http.dart' as http;

class GeniusService {
  // Get your own API key from https://genius.com/api-clients
  // For now, we use lyrics.ovh instead which doesn't require API key
  static const String _apiKey = ''; // Add your Genius API key here if you have one
  static const String _baseUrl = 'https://api.genius.com';
  
  /// Search for a song on Genius
  static Future<Map<String, dynamic>?> searchSong({
    required String trackName,
    required String artistName,
  }) async {
    if (_apiKey.isEmpty) {
      print('Genius API key not configured');
      return null;
    }
    
    try {
      final query = Uri.encodeComponent('$trackName $artistName');
      final url = '$_baseUrl/search?q=$query';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('Genius API Error: ${response.statusCode}');
        return null;
      }
      
      final data = json.decode(response.body);
      final hits = data['response']?['hits'] as List?;
      
      if (hits == null || hits.isEmpty) return null;
      
      // Return the first result
      final result = hits[0]['result'] as Map<String, dynamic>;
      return result;
    } catch (e) {
      print('Error searching song on Genius: $e');
      return null;
    }
  }
  
  /// Get song URL (Genius API doesn't provide lyrics directly)
  /// Use lyrics.ovh API instead for actual lyrics
  static Future<String?> getSongUrl({
    required String trackName,
    required String artistName,
  }) async {
    try {
      final songData = await searchSong(
        trackName: trackName,
        artistName: artistName,
      );
      
      if (songData == null) return null;
      
      // Return the Genius page URL
      return songData['url'] as String?;
    } catch (e) {
      print('Error getting song URL: $e');
      return null;
    }
  }
  
  /// Get song info with thumbnail and stats
  static Future<Map<String, dynamic>?> getSongInfo({
    required String trackName,
    required String artistName,
  }) async {
    try {
      final songData = await searchSong(
        trackName: trackName,
        artistName: artistName,
      );
      
      if (songData == null) return null;
      
      return {
        'title': songData['title'] as String?,
        'artist': songData['primary_artist']?['name'] as String?,
        'thumbnail': songData['song_art_image_thumbnail_url'] as String?,
        'url': songData['url'] as String?,
        'pageviews': songData['stats']?['pageviews'] as int?,
        'release_date': songData['release_date_for_display'] as String?,
      };
    } catch (e) {
      print('Error getting song info: $e');
      return null;
    }
  }
  
}
