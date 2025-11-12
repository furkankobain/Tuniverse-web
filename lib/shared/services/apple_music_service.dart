import 'dart:convert';
import 'package:http/http.dart' as http;

/// Apple Music / iTunes Search API Service
/// Provides preview URLs for tracks (30 seconds)
class AppleMusicService {
  static const String _baseUrl = 'https://itunes.apple.com/search';
  
  /// Search for a track and get preview URL
  /// Returns null if no preview found
  static Future<String?> getTrackPreview({
    required String trackName,
    required String artistName,
  }) async {
    try {
      print('🍎 Searching Apple Music: $trackName by $artistName');
      
      final response = await http.get(
        Uri.parse(_baseUrl).replace(queryParameters: {
          'term': '$trackName $artistName',
          'media': 'music',
          'entity': 'song',
          'limit': '5',
          'country': 'TR', // Turkey
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        
        if (results.isNotEmpty) {
          // Try to find exact match or best match
          for (final result in results) {
            final previewUrl = result['previewUrl'] as String?;
            if (previewUrl != null && previewUrl.isNotEmpty) {
              print('✅ Found Apple Music preview: $previewUrl');
              return previewUrl;
            }
          }
        }
        
        print('⚠️ No preview found on Apple Music');
        return null;
      }
      
      print('❌ Apple Music API error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching Apple Music preview: $e');
      return null;
    }
  }
  
  /// Get preview URL for multiple tracks at once
  static Future<Map<String, String>> getMultipleTrackPreviews(
    List<Map<String, String>> tracks,
  ) async {
    final previews = <String, String>{};
    
    for (final track in tracks) {
      final trackName = track['name'] ?? '';
      final artistName = track['artist'] ?? '';
      
      if (trackName.isEmpty || artistName.isEmpty) continue;
      
      final previewUrl = await getTrackPreview(
        trackName: trackName,
        artistName: artistName,
      );
      
      if (previewUrl != null) {
        previews['$trackName|$artistName'] = previewUrl;
      }
    }
    
    return previews;
  }
}
