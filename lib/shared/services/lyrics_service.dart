import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for fetching and caching song lyrics
/// Uses multiple free APIs with fallback
class LyricsService {
  static const String _cacheKeyPrefix = 'lyrics_cache_';
  static const Duration _cacheDuration = Duration(days: 30);

  // Free lyrics APIs
  static const String _lyricsOvhUrl = 'https://api.lyrics.ovh/v1';
  static const String _lyristUrl = 'https://lyrist.vercel.app/api';

  /// Fetch lyrics for a track
  static Future<LyricsData?> fetchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
  }) async {
    // Check cache first
    final cacheKey = _getCacheKey(trackName, artistName);
    final cachedLyrics = await _getFromCache(cacheKey);
    if (cachedLyrics != null) {
      return cachedLyrics;
    }

    // Try multiple APIs in order
    // 1. Try lyrics.ovh
    try {
      final lyrics = await _fetchFromLyricsOvh(trackName, artistName);
      if (lyrics != null) {
        await _saveToCache(cacheKey, lyrics);
        return lyrics;
      }
    } catch (e) {
      print('lyrics.ovh error: $e');
    }

    // 2. Try Lyrist API
    try {
      final lyrics = await _fetchFromLyrist(trackName, artistName);
      if (lyrics != null) {
        await _saveToCache(cacheKey, lyrics);
        return lyrics;
      }
    } catch (e) {
      print('Lyrist API error: $e');
    }

    print('No lyrics found for: $trackName by $artistName');
    return null;
  }

  /// Fetch lyrics from lyrics.ovh API (free, no API key needed)
  static Future<LyricsData?> _fetchFromLyricsOvh(
    String trackName,
    String artistName,
  ) async {
    try {
      // Clean up artist and track names
      final cleanArtist = artistName.trim();
      final cleanTrack = trackName.trim();
      
      final url = Uri.parse(
        '$_lyricsOvhUrl/$cleanArtist/$cleanTrack',
      );
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lyrics = data['lyrics'] as String?;
        
        if (lyrics != null && lyrics.isNotEmpty) {
          return LyricsData(
            trackName: trackName,
            artistName: artistName,
            lyrics: lyrics.trim(),
            syncedLyrics: null,
            source: 'lyrics.ovh',
            url: null,
          );
        }
      } else {
        print('Lyrics API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Lyrics.ovh API error: $e');
    }
    return null;
  }

  /// Fetch lyrics from Lyrist API (alternative free API)
  static Future<LyricsData?> _fetchFromLyrist(
    String trackName,
    String artistName,
  ) async {
    try {
      final cleanArtist = artistName.trim();
      final cleanTrack = trackName.trim();
      
      final url = Uri.parse(
        '$_lyristUrl/$cleanArtist/$cleanTrack',
      );
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lyrics = data['lyrics'] as String?;
        
        if (lyrics != null && lyrics.isNotEmpty) {
          return LyricsData(
            trackName: trackName,
            artistName: artistName,
            lyrics: lyrics.trim(),
            syncedLyrics: null,
            source: 'Lyrist',
            url: null,
          );
        }
      }
    } catch (e) {
      print('Lyrist API error: $e');
    }
    return null;
  }

  /// Get cache key
  static String _getCacheKey(String trackName, String artistName) {
    final normalized = '${trackName.toLowerCase()}_${artistName.toLowerCase()}'
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '$_cacheKeyPrefix$normalized';
  }

  /// Get lyrics from cache
  static Future<LyricsData?> _getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      
      if (cached != null) {
        final data = json.decode(cached);
        final timestamp = DateTime.parse(data['timestamp']);
        
        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return LyricsData.fromJson(data['lyrics']);
        } else {
          // Cache expired, remove it
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache read error: $e');
    }
    return null;
  }

  /// Save lyrics to cache
  static Future<void> _saveToCache(String key, LyricsData lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'lyrics': lyrics.toJson(),
      };
      await prefs.setString(key, json.encode(cacheData));
    } catch (e) {
      print('Cache write error: $e');
    }
  }

  /// Clear lyrics cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// Search in lyrics
  static List<int> searchInLyrics(String lyrics, String query) {
    if (query.isEmpty) return [];
    
    final lines = lyrics.split('\n');
    final results = <int>[];
    
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
        results.add(i);
      }
    }
    
    return results;
  }
}

/// Lyrics data model
class LyricsData {
  final String trackName;
  final String artistName;
  final String lyrics;
  final List<SyncedLyric>? syncedLyrics;
  final String source;
  final String? url;

  LyricsData({
    required this.trackName,
    required this.artistName,
    required this.lyrics,
    this.syncedLyrics,
    required this.source,
    this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'trackName': trackName,
      'artistName': artistName,
      'lyrics': lyrics,
      'syncedLyrics': syncedLyrics?.map((l) => l.toJson()).toList(),
      'source': source,
      'url': url,
    };
  }

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    return LyricsData(
      trackName: json['trackName'],
      artistName: json['artistName'],
      lyrics: json['lyrics'],
      syncedLyrics: json['syncedLyrics'] != null
          ? (json['syncedLyrics'] as List)
              .map((l) => SyncedLyric.fromJson(l))
              .toList()
          : null,
      source: json['source'],
      url: json['url'],
    );
  }
}

/// Synced lyric line with timestamp
class SyncedLyric {
  final Duration timestamp;
  final String text;

  SyncedLyric({
    required this.timestamp,
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.inMilliseconds,
      'text': text,
    };
  }

  factory SyncedLyric.fromJson(Map<String, dynamic> json) {
    return SyncedLyric(
      timestamp: Duration(milliseconds: json['timestamp']),
      text: json['text'],
    );
  }
}
