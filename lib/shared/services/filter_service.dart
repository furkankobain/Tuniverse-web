import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing search and playlist filters
class FilterService {
  static const String _filterPresetsKey = 'filter_presets';
  static const String _activeFiltersKey = 'active_filters';

  // Filter categories
  static const List<String> genres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'Electronic',
    'R&B',
    'Jazz',
    'Classical',
    'Country',
    'Latin',
    'Metal',
    'Indie',
    'Alternative',
    'Blues',
    'Reggae',
    'Funk',
  ];

  static const List<String> decades = [
    '2020s',
    '2010s',
    '2000s',
    '1990s',
    '1980s',
    '1970s',
    '1960s',
    '1950s',
  ];

  static const List<String> moods = [
    'Happy',
    'Sad',
    'Energetic',
    'Chill',
    'Romantic',
    'Aggressive',
    'Melancholic',
    'Uplifting',
  ];

  static const List<String> tempos = [
    'Slow',
    'Medium',
    'Fast',
    'Very Fast',
  ];

  /// Get active filters
  static Future<Map<String, dynamic>> getActiveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = prefs.getString(_activeFiltersKey);
      
      if (filtersJson != null) {
        return Map<String, dynamic>.from(json.decode(filtersJson));
      }
      
      return {};
    } catch (e) {
      print('Error getting active filters: $e');
      return {};
    }
  }

  /// Set active filters
  static Future<bool> setActiveFilters(Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeFiltersKey, json.encode(filters));
      return true;
    } catch (e) {
      print('Error setting active filters: $e');
      return false;
    }
  }

  /// Clear active filters
  static Future<bool> clearActiveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeFiltersKey);
      return true;
    } catch (e) {
      print('Error clearing active filters: $e');
      return false;
    }
  }

  /// Save filter preset
  static Future<bool> saveFilterPreset(String name, Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_filterPresetsKey);
      
      Map<String, dynamic> presets = {};
      if (presetsJson != null) {
        presets = Map<String, dynamic>.from(json.decode(presetsJson));
      }
      
      presets[name] = filters;
      await prefs.setString(_filterPresetsKey, json.encode(presets));
      return true;
    } catch (e) {
      print('Error saving filter preset: $e');
      return false;
    }
  }

  /// Get filter presets
  static Future<Map<String, dynamic>> getFilterPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_filterPresetsKey);
      
      if (presetsJson != null) {
        return Map<String, dynamic>.from(json.decode(presetsJson));
      }
      
      return {};
    } catch (e) {
      print('Error getting filter presets: $e');
      return {};
    }
  }

  /// Delete filter preset
  static Future<bool> deleteFilterPreset(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_filterPresetsKey);
      
      if (presetsJson != null) {
        final presets = Map<String, dynamic>.from(json.decode(presetsJson));
        presets.remove(name);
        await prefs.setString(_filterPresetsKey, json.encode(presets));
      }
      
      return true;
    } catch (e) {
      print('Error deleting filter preset: $e');
      return false;
    }
  }

  /// Apply filters to tracks
  static List<Map<String, dynamic>> applyFilters(
    List<Map<String, dynamic>> tracks,
    Map<String, dynamic> filters,
  ) {
    var filtered = tracks;

    // Genre filter
    if (filters.containsKey('genres') && (filters['genres'] as List).isNotEmpty) {
      final selectedGenres = List<String>.from(filters['genres']);
      filtered = filtered.where((track) {
        final trackGenres = List<String>.from(track['genres'] ?? []);
        return trackGenres.any((genre) => selectedGenres.contains(genre));
      }).toList();
    }

    // Decade filter
    if (filters.containsKey('decades') && (filters['decades'] as List).isNotEmpty) {
      final selectedDecades = List<String>.from(filters['decades']);
      filtered = filtered.where((track) {
        final year = track['year'] as int?;
        if (year == null) return false;
        
        final decade = '${(year ~/ 10) * 10}s';
        return selectedDecades.contains(decade);
      }).toList();
    }

    // Mood filter
    if (filters.containsKey('moods') && (filters['moods'] as List).isNotEmpty) {
      final selectedMoods = List<String>.from(filters['moods']);
      filtered = filtered.where((track) {
        final trackMood = track['mood'] as String?;
        return trackMood != null && selectedMoods.contains(trackMood);
      }).toList();
    }

    // Tempo filter
    if (filters.containsKey('tempo')) {
      final tempo = filters['tempo'] as String;
      filtered = filtered.where((track) {
        final trackTempo = track['tempo'] as String?;
        return trackTempo == tempo;
      }).toList();
    }

    // Duration filter (min/max in seconds)
    if (filters.containsKey('minDuration')) {
      final minDuration = filters['minDuration'] as int;
      filtered = filtered.where((track) {
        final duration = track['duration'] as int?;
        return duration != null && duration >= minDuration;
      }).toList();
    }

    if (filters.containsKey('maxDuration')) {
      final maxDuration = filters['maxDuration'] as int;
      filtered = filtered.where((track) {
        final duration = track['duration'] as int?;
        return duration != null && duration <= maxDuration;
      }).toList();
    }

    // Popularity filter (0-100)
    if (filters.containsKey('minPopularity')) {
      final minPopularity = filters['minPopularity'] as int;
      filtered = filtered.where((track) {
        final popularity = track['popularity'] as int?;
        return popularity != null && popularity >= minPopularity;
      }).toList();
    }

    // Explicit content filter
    if (filters.containsKey('explicit')) {
      final explicit = filters['explicit'] as bool;
      filtered = filtered.where((track) {
        final isExplicit = track['explicit'] as bool? ?? false;
        return explicit ? isExplicit : !isExplicit;
      }).toList();
    }

    return filtered;
  }

  /// Get filter summary text
  static String getFilterSummary(Map<String, dynamic> filters) {
    if (filters.isEmpty) return 'Filtre yok';

    final parts = <String>[];

    if (filters.containsKey('genres') && (filters['genres'] as List).isNotEmpty) {
      final genres = filters['genres'] as List;
      parts.add('${genres.length} tür');
    }

    if (filters.containsKey('decades') && (filters['decades'] as List).isNotEmpty) {
      final decades = filters['decades'] as List;
      parts.add('${decades.length} dönem');
    }

    if (filters.containsKey('moods') && (filters['moods'] as List).isNotEmpty) {
      final moods = filters['moods'] as List;
      parts.add('${moods.length} ruh hali');
    }

    if (filters.containsKey('tempo')) {
      parts.add('Tempo: ${filters['tempo']}');
    }

    if (filters.containsKey('minDuration') || filters.containsKey('maxDuration')) {
      parts.add('Süre filtresi');
    }

    if (filters.containsKey('minPopularity')) {
      parts.add('Popülerlik ≥ ${filters['minPopularity']}');
    }

    if (filters.containsKey('explicit')) {
      parts.add(filters['explicit'] ? 'Açık içerik' : 'Temiz içerik');
    }

    return parts.join(', ');
  }

  /// Check if any filters are active
  static bool hasActiveFilters(Map<String, dynamic> filters) {
    if (filters.isEmpty) return false;

    // Check for non-empty list filters
    if (filters.containsKey('genres') && (filters['genres'] as List).isNotEmpty) {
      return true;
    }
    if (filters.containsKey('decades') && (filters['decades'] as List).isNotEmpty) {
      return true;
    }
    if (filters.containsKey('moods') && (filters['moods'] as List).isNotEmpty) {
      return true;
    }

    // Check for other filter types
    return filters.containsKey('tempo') ||
        filters.containsKey('minDuration') ||
        filters.containsKey('maxDuration') ||
        filters.containsKey('minPopularity') ||
        filters.containsKey('explicit');
  }
}
