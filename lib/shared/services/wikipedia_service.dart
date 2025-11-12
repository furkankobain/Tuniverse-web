import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  static const String _baseUrl = 'https://en.wikipedia.org/api/rest_v1';
  
  /// Get artist summary from Wikipedia
  static Future<Map<String, dynamic>?> getArtistInfo(String artistName) async {
    try {
      // Try multiple search variations
      final searchQueries = [
        '$artistName musician',
        '$artistName singer',
        '$artistName band',
        artistName,
      ];

      for (final query in searchQueries) {
        // Search for the artist page
        final searchUrl = 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&origin=*';
        
        final searchResponse = await http.get(Uri.parse(searchUrl));
        if (searchResponse.statusCode != 200) continue;
        
        final searchData = json.decode(searchResponse.body);
        final searchResults = searchData['query']?['search'] as List?;
        
        if (searchResults == null || searchResults.isEmpty) continue;
        
        // Try to find a result that looks like a music-related article
        for (var result in searchResults.take(3)) {
          final pageTitle = result['title'] as String;
          final snippet = result['snippet'] as String? ?? '';
          
          // Check if it's likely a music-related article
          final lowerSnippet = snippet.toLowerCase();
          final lowerTitle = pageTitle.toLowerCase();
          final musicKeywords = ['musician', 'singer', 'band', 'artist', 'rapper', 'songwriter', 'music', 'album', 'song'];
          
          if (!musicKeywords.any((keyword) => lowerSnippet.contains(keyword) || lowerTitle.contains(keyword)) && 
              result != searchResults.first) {
            continue; // Skip if not music-related
          }
          
          // Get page summary
          final summaryUrl = '$_baseUrl/page/summary/${Uri.encodeComponent(pageTitle)}';
          final summaryResponse = await http.get(Uri.parse(summaryUrl));
          
          if (summaryResponse.statusCode != 200) continue;
          
          final summaryData = json.decode(summaryResponse.body);
          final extract = summaryData['extract'] as String?;
          
          // Make sure we have actual content
          if (extract == null || extract.trim().isEmpty || extract.length < 50) {
            continue;
          }
          
          // Extract relevant information
          return {
            'title': summaryData['title'] as String?,
            'extract': extract,
            'description': summaryData['description'] as String?,
            'thumbnail': summaryData['thumbnail']?['source'] as String?,
            'pageUrl': summaryData['content_urls']?['desktop']?['page'] as String?,
          };
        }
      }
      
      print('Wikipedia: No suitable article found for $artistName');
      return null;
    } catch (e) {
      print('Wikipedia API Error: $e');
      return null;
    }
  }
  
  /// Get detailed artist biography
  static Future<String?> getArtistBiography(String artistName) async {
    try {
      final info = await getArtistInfo(artistName);
      return info?['extract'] as String?;
    } catch (e) {
      print('Error getting biography: $e');
      return null;
    }
  }
}
