import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Search History Service
/// Manages search history with local storage
class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 20;

  /// Add search query to history
  static Future<void> addSearchQuery(String query, {String? type}) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    // Create search item
    final searchItem = SearchHistoryItem(
      query: query.trim(),
      type: type ?? 'all',
      timestamp: DateTime.now(),
    );

    // Remove duplicate if exists
    history.removeWhere((item) => 
      item.query.toLowerCase() == query.trim().toLowerCase() &&
      item.type == searchItem.type
    );

    // Add to beginning
    history.insert(0, searchItem);

    // Keep only max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // Save to storage
    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// Get search history
  static Future<List<SearchHistoryItem>> getSearchHistory({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final history = jsonList
          .map((json) => SearchHistoryItem.fromJson(json))
          .toList();

      // Filter by type if specified
      if (type != null && type != 'all') {
        return history.where((item) => item.type == type).toList();
      }

      return history;
    } catch (e) {
      print('Error loading search history: $e');
      return [];
    }
  }

  /// Get recent searches (last 5)
  static Future<List<SearchHistoryItem>> getRecentSearches({int count = 5}) async {
    final history = await getSearchHistory();
    return history.take(count).toList();
  }

  /// Remove specific search from history
  static Future<void> removeSearch(String query, {String? type}) async {
    final history = await getSearchHistory();
    history.removeWhere((item) => 
      item.query.toLowerCase() == query.toLowerCase() &&
      (type == null || item.type == type)
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// Clear all search history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Get search suggestions based on query
  static Future<List<String>> getSuggestions(String query, {String? type}) async {
    if (query.trim().isEmpty) return [];

    final history = await getSearchHistory(type: type);
    final queryLower = query.toLowerCase();

    // Filter history items that match query
    final suggestions = history
        .where((item) => item.query.toLowerCase().contains(queryLower))
        .map((item) => item.query)
        .toSet() // Remove duplicates
        .take(5)
        .toList();

    return suggestions;
  }

  /// Get trending searches (most frequent)
  static Future<List<SearchHistoryItem>> getTrendingSearches({int count = 5}) async {
    final history = await getSearchHistory();
    
    // Count frequency of each query
    final frequency = <String, int>{};
    for (var item in history) {
      final key = item.query.toLowerCase();
      frequency[key] = (frequency[key] ?? 0) + 1;
    }

    // Sort by frequency
    final trendingQueries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get unique trending items
    final trending = <SearchHistoryItem>[];
    for (var entry in trendingQueries.take(count)) {
      final item = history.firstWhere(
        (h) => h.query.toLowerCase() == entry.key,
      );
      trending.add(item);
    }

    return trending;
  }

  /// Get popular search terms (aggregated data - could be from server)
  static List<String> getPopularSearchTerms() {
    // This could fetch from a server in production
    return [
      'Müzik Türü: Pop',
      'Sanatçı: Taylor Swift',
      'Albüm: Midnights',
      'Playlist: Çalışma Müzikleri',
      'Yıl: 2024',
      'Ruh Hali: Sakin',
      'Tempo: Hızlı',
      'Dil: Türkçe',
    ];
  }
}

/// Search History Item Model
class SearchHistoryItem {
  final String query;
  final String type; // 'all', 'track', 'artist', 'album', 'user'
  final DateTime timestamp;

  SearchHistoryItem({
    required this.query,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Get time ago string
  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  // Get type icon
  String get typeIcon {
    switch (type) {
      case 'track':
        return '🎵';
      case 'artist':
        return '👤';
      case 'album':
        return '💿';
      case 'user':
        return '👥';
      default:
        return '🔍';
    }
  }
}

/// Search Filter Model
class SearchFilter {
  final String? genre;
  final int? minYear;
  final int? maxYear;
  final String? mood;
  final String? tempo;
  final double? minRating;
  final String? sortBy; // 'relevance', 'date', 'popularity', 'rating'

  SearchFilter({
    this.genre,
    this.minYear,
    this.maxYear,
    this.mood,
    this.tempo,
    this.minRating,
    this.sortBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'genre': genre,
      'minYear': minYear,
      'maxYear': maxYear,
      'mood': mood,
      'tempo': tempo,
      'minRating': minRating,
      'sortBy': sortBy,
    };
  }

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      genre: json['genre'] as String?,
      minYear: json['minYear'] as int?,
      maxYear: json['maxYear'] as int?,
      mood: json['mood'] as String?,
      tempo: json['tempo'] as String?,
      minRating: json['minRating'] as double?,
      sortBy: json['sortBy'] as String?,
    );
  }

  bool get isEmpty {
    return genre == null &&
        minYear == null &&
        maxYear == null &&
        mood == null &&
        tempo == null &&
        minRating == null &&
        sortBy == null;
  }

  // Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (genre != null) count++;
    if (minYear != null || maxYear != null) count++;
    if (mood != null) count++;
    if (tempo != null) count++;
    if (minRating != null) count++;
    return count;
  }

  SearchFilter copyWith({
    String? genre,
    int? minYear,
    int? maxYear,
    String? mood,
    String? tempo,
    double? minRating,
    String? sortBy,
  }) {
    return SearchFilter(
      genre: genre ?? this.genre,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      mood: mood ?? this.mood,
      tempo: tempo ?? this.tempo,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  SearchFilter clear() {
    return SearchFilter();
  }
}
