import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// AI Mood Detection Service
/// Analyzes listening patterns to detect user mood and generate playlists
class AIMoodDetectionService {
  static final _firestore = FirebaseFirestore.instance;

  /// Detect current mood based on recent listening history
  static Future<MoodAnalysis> detectMood(String userId) async {
    try {
      // Get listening history from last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      final historySnapshot = await _firestore
          .collection('listeningHistory')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: yesterday)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (historySnapshot.docs.isEmpty) {
        return MoodAnalysis.defaultMood();
      }

      // Analyze audio features
      final tracks = historySnapshot.docs.map((doc) => doc.data()).toList();
      
      double avgEnergy = 0;
      double avgValence = 0;
      double avgTempo = 0;
      double avgDanceability = 0;
      int count = 0;

      for (var track in tracks) {
        if (track['audioFeatures'] != null) {
          final features = track['audioFeatures'] as Map<String, dynamic>;
          avgEnergy += (features['energy'] ?? 0.5) as double;
          avgValence += (features['valence'] ?? 0.5) as double;
          avgTempo += (features['tempo'] ?? 120) as double;
          avgDanceability += (features['danceability'] ?? 0.5) as double;
          count++;
        }
      }

      if (count == 0) {
        return MoodAnalysis.defaultMood();
      }

      avgEnergy /= count;
      avgValence /= count;
      avgTempo /= count;
      avgDanceability /= count;

      // Determine mood based on audio features
      final mood = _analyzeMoodFromFeatures(
        avgEnergy,
        avgValence,
        avgTempo,
        avgDanceability,
      );

      return MoodAnalysis(
        mood: mood,
        confidence: _calculateConfidence(count),
        energy: avgEnergy,
        valence: avgValence,
        tempo: avgTempo,
        danceability: avgDanceability,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error detecting mood: $e');
      return MoodAnalysis.defaultMood();
    }
  }

  /// Analyze mood from audio features
  static MoodType _analyzeMoodFromFeatures(
    double energy,
    double valence,
    double tempo,
    double danceability,
  ) {
    // High energy + High valence = Happy/Energetic
    if (energy > 0.7 && valence > 0.6) {
      return MoodType.energetic;
    }
    
    // High energy + Low valence = Angry/Intense
    if (energy > 0.7 && valence < 0.4) {
      return MoodType.intense;
    }
    
    // Low energy + High valence = Calm/Peaceful
    if (energy < 0.4 && valence > 0.5) {
      return MoodType.calm;
    }
    
    // Low energy + Low valence = Sad/Melancholic
    if (energy < 0.4 && valence < 0.4) {
      return MoodType.melancholic;
    }
    
    // High danceability = Party mood
    if (danceability > 0.7) {
      return MoodType.party;
    }
    
    // Medium tempo + balanced = Focus
    if (tempo > 100 && tempo < 130 && energy > 0.4 && energy < 0.7) {
      return MoodType.focus;
    }

    // Default to neutral
    return MoodType.neutral;
  }

  /// Calculate confidence score
  static double _calculateConfidence(int trackCount) {
    if (trackCount >= 30) return 0.9;
    if (trackCount >= 20) return 0.75;
    if (trackCount >= 10) return 0.6;
    return 0.4;
  }

  /// Generate mood-based playlist
  static Future<List<Map<String, dynamic>>> generateMoodPlaylist({
    required MoodType mood,
    required String userId,
    int limit = 30,
  }) async {
    try {
      final targetFeatures = _getMoodTargetFeatures(mood);
      
      // Get user's liked tracks
      final likedTracksSnapshot = await _firestore
          .collection('likedTracks')
          .where('userId', isEqualTo: userId)
          .limit(200)
          .get();

      final tracks = likedTracksSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      // Score and sort tracks by mood match
      final scoredTracks = tracks.map((track) {
        final score = _calculateMoodMatchScore(track, targetFeatures);
        return {'track': track, 'score': score};
      }).toList();

      scoredTracks.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Return top matching tracks
      return scoredTracks
          .take(limit)
          .map((item) => item['track'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error generating mood playlist: $e');
      return [];
    }
  }

  /// Get target audio features for mood
  static Map<String, double> _getMoodTargetFeatures(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return {
          'energy': 0.8,
          'valence': 0.7,
          'tempo': 130,
          'danceability': 0.7,
        };
      case MoodType.calm:
        return {
          'energy': 0.3,
          'valence': 0.6,
          'tempo': 90,
          'danceability': 0.3,
        };
      case MoodType.melancholic:
        return {
          'energy': 0.3,
          'valence': 0.3,
          'tempo': 80,
          'danceability': 0.3,
        };
      case MoodType.party:
        return {
          'energy': 0.9,
          'valence': 0.8,
          'tempo': 125,
          'danceability': 0.9,
        };
      case MoodType.focus:
        return {
          'energy': 0.5,
          'valence': 0.5,
          'tempo': 110,
          'danceability': 0.4,
        };
      case MoodType.intense:
        return {
          'energy': 0.9,
          'valence': 0.4,
          'tempo': 140,
          'danceability': 0.6,
        };
      case MoodType.neutral:
      default:
        return {
          'energy': 0.5,
          'valence': 0.5,
          'tempo': 120,
          'danceability': 0.5,
        };
    }
  }

  /// Calculate mood match score
  static double _calculateMoodMatchScore(
    Map<String, dynamic> track,
    Map<String, double> targetFeatures,
  ) {
    if (track['audioFeatures'] == null) return 0.0;

    final features = track['audioFeatures'] as Map<String, dynamic>;
    
    double score = 0;
    int count = 0;

    // Compare each feature
    for (var key in targetFeatures.keys) {
      if (features[key] != null) {
        final diff = ((features[key] as double) - targetFeatures[key]!).abs();
        score += (1 - diff);
        count++;
      }
    }

    return count > 0 ? score / count : 0.0;
  }

  /// Get mood color
  static int getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return 0xFFFF5E5E;
      case MoodType.calm:
        return 0xFF4CAF50;
      case MoodType.melancholic:
        return 0xFF5C6BC0;
      case MoodType.party:
        return 0xFFFF9800;
      case MoodType.focus:
        return 0xFF00BCD4;
      case MoodType.intense:
        return 0xFFE91E63;
      case MoodType.neutral:
        return 0xFF9E9E9E;
    }
  }

  /// Get mood emoji
  static String getMoodEmoji(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return '⚡';
      case MoodType.calm:
        return '🌊';
      case MoodType.melancholic:
        return '🌧️';
      case MoodType.party:
        return '🎉';
      case MoodType.focus:
        return '🎯';
      case MoodType.intense:
        return '🔥';
      case MoodType.neutral:
        return '😌';
    }
  }

  /// Get mood name in Turkish
  static String getMoodName(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return 'Enerjik';
      case MoodType.calm:
        return 'Sakin';
      case MoodType.melancholic:
        return 'Melankolik';
      case MoodType.party:
        return 'Parti';
      case MoodType.focus:
        return 'Odaklanmış';
      case MoodType.intense:
        return 'Yoğun';
      case MoodType.neutral:
        return 'Nötr';
    }
  }

  /// Get mood description
  static String getMoodDescription(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return 'Yüksek enerjili ve neşeli şarkılar dinliyorsun!';
      case MoodType.calm:
        return 'Rahatlatıcı ve huzurlu müzikler tercihin.';
      case MoodType.melancholic:
        return 'Duygusal ve düşündürücü şarkılarla vakit geçiriyorsun.';
      case MoodType.party:
        return 'Dans edilesi ritimler seni sardı!';
      case MoodType.focus:
        return 'Konsantrasyonu artıran şarkılar dinliyorsun.';
      case MoodType.intense:
        return 'Güçlü ve yoğun müziklerle doluyorsun!';
      case MoodType.neutral:
        return 'Dengeli bir müzik tercihin var.';
    }
  }
}

/// Mood Analysis Model
class MoodAnalysis {
  final MoodType mood;
  final double confidence;
  final double energy;
  final double valence;
  final double tempo;
  final double danceability;
  final DateTime timestamp;

  MoodAnalysis({
    required this.mood,
    required this.confidence,
    required this.energy,
    required this.valence,
    required this.tempo,
    required this.danceability,
    required this.timestamp,
  });

  factory MoodAnalysis.defaultMood() {
    return MoodAnalysis(
      mood: MoodType.neutral,
      confidence: 0.5,
      energy: 0.5,
      valence: 0.5,
      tempo: 120,
      danceability: 0.5,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood.name,
      'confidence': confidence,
      'energy': energy,
      'valence': valence,
      'tempo': tempo,
      'danceability': danceability,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Mood Types
enum MoodType {
  energetic,
  calm,
  melancholic,
  party,
  focus,
  intense,
  neutral,
}
