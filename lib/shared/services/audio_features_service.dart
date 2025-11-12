import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching and analyzing Spotify audio features
/// Provides detailed audio analysis including tempo, energy, danceability, etc.
class AudioFeaturesService {
  static const String _spotifyApiUrl = 'https://api.spotify.com/v1';
  
  // TODO: Implement proper Spotify OAuth token management
  static String? _accessToken;

  /// Set Spotify access token
  static void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Get audio features for a track
  static Future<AudioFeatures?> getAudioFeatures(String trackId) async {
    if (_accessToken == null) {
      print('Spotify access token not set');
      return _getMockAudioFeatures(trackId);
    }

    try {
      final url = Uri.parse('$_spotifyApiUrl/audio-features/$trackId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AudioFeatures.fromJson(data);
      } else {
        print('Failed to fetch audio features: ${response.statusCode}');
        return _getMockAudioFeatures(trackId);
      }
    } catch (e) {
      print('Error fetching audio features: $e');
      return _getMockAudioFeatures(trackId);
    }
  }

  /// Get audio analysis for a track (more detailed)
  static Future<AudioAnalysis?> getAudioAnalysis(String trackId) async {
    if (_accessToken == null) {
      print('Spotify access token not set');
      return null;
    }

    try {
      final url = Uri.parse('$_spotifyApiUrl/audio-analysis/$trackId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AudioAnalysis.fromJson(data);
      }
    } catch (e) {
      print('Error fetching audio analysis: $e');
    }
    return null;
  }

  /// Generate mock audio features for demo
  static AudioFeatures _getMockAudioFeatures(String trackId) {
    // Generate semi-random but realistic values based on track ID hash
    final hash = trackId.hashCode.abs();
    
    return AudioFeatures(
      trackId: trackId,
      danceability: (hash % 40 + 40) / 100, // 0.4 - 0.8
      energy: (hash % 50 + 30) / 100, // 0.3 - 0.8
      key: hash % 12, // 0-11 (C, C#, D, ... B)
      loudness: -15.0 + (hash % 10), // -15 to -5 dB
      mode: hash % 2, // 0 (minor) or 1 (major)
      speechiness: (hash % 30) / 100, // 0.0 - 0.3
      acousticness: (hash % 60 + 20) / 100, // 0.2 - 0.8
      instrumentalness: (hash % 50) / 100, // 0.0 - 0.5
      liveness: (hash % 40 + 10) / 100, // 0.1 - 0.5
      valence: (hash % 60 + 20) / 100, // 0.2 - 0.8
      tempo: 90.0 + (hash % 80), // 90 - 170 BPM
      duration: 180000 + (hash % 120000), // 3-5 minutes
      timeSignature: [3, 4, 5][hash % 3], // 3/4, 4/4, or 5/4
    );
  }

  /// Get key name from key number
  static String getKeyName(int key) {
    const keys = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];
    return keys[key % 12];
  }

  /// Get mode name
  static String getModeName(int mode) {
    return mode == 1 ? 'Major' : 'Minor';
  }

  /// Get tempo description
  static String getTempoDescription(double tempo) {
    if (tempo < 80) return 'Çok Yavaş';
    if (tempo < 100) return 'Yavaş';
    if (tempo < 120) return 'Orta';
    if (tempo < 140) return 'Hızlı';
    if (tempo < 170) return 'Çok Hızlı';
    return 'Aşırı Hızlı';
  }

  /// Get energy description
  static String getEnergyDescription(double energy) {
    if (energy < 0.3) return 'Sakin';
    if (energy < 0.5) return 'Orta';
    if (energy < 0.7) return 'Enerjik';
    return 'Çok Enerjik';
  }

  /// Get danceability description
  static String getDanceabilityDescription(double danceability) {
    if (danceability < 0.3) return 'Zor Dans Edilir';
    if (danceability < 0.5) return 'Orta';
    if (danceability < 0.7) return 'Dans Edilebilir';
    return 'Çok Dans Edilebilir';
  }

  /// Get valence (mood) description
  static String getValenceDescription(double valence) {
    if (valence < 0.3) return 'Hüzünlü';
    if (valence < 0.5) return 'Nötr';
    if (valence < 0.7) return 'Mutlu';
    return 'Çok Mutlu';
  }

  /// Get acousticness description
  static String getAcousticnessDescription(double acousticness) {
    if (acousticness < 0.3) return 'Elektronik';
    if (acousticness < 0.6) return 'Hibrit';
    return 'Akustik';
  }
}

/// Audio features model
class AudioFeatures {
  final String trackId;
  final double danceability; // 0.0 - 1.0
  final double energy; // 0.0 - 1.0
  final int key; // 0-11 (pitch class)
  final double loudness; // dB
  final int mode; // 0 (minor) or 1 (major)
  final double speechiness; // 0.0 - 1.0
  final double acousticness; // 0.0 - 1.0
  final double instrumentalness; // 0.0 - 1.0
  final double liveness; // 0.0 - 1.0
  final double valence; // 0.0 - 1.0 (mood)
  final double tempo; // BPM
  final int duration; // milliseconds
  final int timeSignature; // beats per bar

  AudioFeatures({
    required this.trackId,
    required this.danceability,
    required this.energy,
    required this.key,
    required this.loudness,
    required this.mode,
    required this.speechiness,
    required this.acousticness,
    required this.instrumentalness,
    required this.liveness,
    required this.valence,
    required this.tempo,
    required this.duration,
    required this.timeSignature,
  });

  factory AudioFeatures.fromJson(Map<String, dynamic> json) {
    return AudioFeatures(
      trackId: json['id'] ?? '',
      danceability: (json['danceability'] ?? 0.5).toDouble(),
      energy: (json['energy'] ?? 0.5).toDouble(),
      key: json['key'] ?? 0,
      loudness: (json['loudness'] ?? -10.0).toDouble(),
      mode: json['mode'] ?? 1,
      speechiness: (json['speechiness'] ?? 0.05).toDouble(),
      acousticness: (json['acousticness'] ?? 0.5).toDouble(),
      instrumentalness: (json['instrumentalness'] ?? 0.0).toDouble(),
      liveness: (json['liveness'] ?? 0.1).toDouble(),
      valence: (json['valence'] ?? 0.5).toDouble(),
      tempo: (json['tempo'] ?? 120.0).toDouble(),
      duration: json['duration_ms'] ?? 180000,
      timeSignature: json['time_signature'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': trackId,
      'danceability': danceability,
      'energy': energy,
      'key': key,
      'loudness': loudness,
      'mode': mode,
      'speechiness': speechiness,
      'acousticness': acousticness,
      'instrumentalness': instrumentalness,
      'liveness': liveness,
      'valence': valence,
      'tempo': tempo,
      'duration_ms': duration,
      'time_signature': timeSignature,
    };
  }

  /// Get radar chart data points for visualization
  List<double> getRadarData() {
    return [
      danceability,
      energy,
      valence,
      acousticness,
      speechiness,
      liveness,
    ];
  }

  /// Get radar chart labels
  static List<String> getRadarLabels() {
    return [
      'Danceability',
      'Energy',
      'Mood',
      'Acousticness',
      'Speechiness',
      'Liveness',
    ];
  }
}

/// Audio analysis model (more detailed)
class AudioAnalysis {
  final List<AudioSection> sections;
  final List<AudioSegment> segments;
  final AudioTrack track;

  AudioAnalysis({
    required this.sections,
    required this.segments,
    required this.track,
  });

  factory AudioAnalysis.fromJson(Map<String, dynamic> json) {
    return AudioAnalysis(
      sections: (json['sections'] as List?)
              ?.map((s) => AudioSection.fromJson(s))
              .toList() ??
          [],
      segments: (json['segments'] as List?)
              ?.map((s) => AudioSegment.fromJson(s))
              .toList() ??
          [],
      track: AudioTrack.fromJson(json['track'] ?? {}),
    );
  }
}

/// Audio section (larger structural unit)
class AudioSection {
  final double start;
  final double duration;
  final double loudness;
  final double tempo;
  final int key;
  final int mode;

  AudioSection({
    required this.start,
    required this.duration,
    required this.loudness,
    required this.tempo,
    required this.key,
    required this.mode,
  });

  factory AudioSection.fromJson(Map<String, dynamic> json) {
    return AudioSection(
      start: (json['start'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 0.0).toDouble(),
      loudness: (json['loudness'] ?? -10.0).toDouble(),
      tempo: (json['tempo'] ?? 120.0).toDouble(),
      key: json['key'] ?? 0,
      mode: json['mode'] ?? 1,
    );
  }
}

/// Audio segment (smallest analysis unit)
class AudioSegment {
  final double start;
  final double duration;
  final double loudness;

  AudioSegment({
    required this.start,
    required this.duration,
    required this.loudness,
  });

  factory AudioSegment.fromJson(Map<String, dynamic> json) {
    return AudioSegment(
      start: (json['start'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 0.0).toDouble(),
      loudness: (json['loudness_start'] ?? -10.0).toDouble(),
    );
  }
}

/// Audio track metadata
class AudioTrack {
  final double duration;
  final int numSamples;
  final String analysisUrl;

  AudioTrack({
    required this.duration,
    required this.numSamples,
    required this.analysisUrl,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      duration: (json['duration'] ?? 0.0).toDouble(),
      numSamples: json['num_samples'] ?? 0,
      analysisUrl: json['analysis_url'] ?? '',
    );
  }
}
