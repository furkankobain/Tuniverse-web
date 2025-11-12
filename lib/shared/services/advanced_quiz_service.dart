import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_question.dart';
import 'enhanced_spotify_service.dart';
import 'apple_music_service.dart';

/// Advanced Music Quiz Service
/// Two game modes:
/// 1. Guess the Song - User enters 1-5 artists, plays 5sec preview, 3 song options
/// 2. Guess the Artist - User selects genre (Turkish or Global), plays 5sec preview, 3 artist options
class AdvancedQuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();
  
  // Turkish artists pool (for Turkish genres)
  static const List<String> turkishArtists = [
    'Tarkan', 'Sezen Aksu', 'Barış Manço', 'Ajda Pekkan', 'Sertab Erener',
    'Teoman', 'Mor ve Ötesi', 'Duman', 'Manga', 'Athena',
    'Ezhel', 'Ceza', 'Sagopa Kajmer', 'Norm Ender', 'Şanışer',
  ];
  
  // Genre lists
  static const List<String> turkishGenres = [
    'Türkçe Pop',
    'Türkçe Rock',
    'Türkçe Hip-Hop',
  ];
  
  static const List<String> globalGenres = [
    'Pop',
    'Rock',
    'Hip-Hop',
    'Electronic',
    'R&B',
    'Country',
    'Jazz',
    'Classical',
    'Latin',
    'Metal',
    'Indie',
    'K-Pop',
  ];
  
  // ==================== GAME MODE 1: GUESS THE SONG ====================
  
  /// Generate "Guess the Song" quiz
  /// User provides 1-5 artist names
  /// For each question: play 5sec preview, show 3 song options (1 correct + 2 similar)
  static Future<QuizSession> generateGuessSongQuiz({
    required String userId,
    required List<String> artistNames,
    int questionCount = 10,
  }) async {
    if (artistNames.isEmpty || artistNames.length > 5) {
      throw Exception('Artist count must be between 1 and 5');
    }
    
    final questions = <QuizQuestion>[];
    final tracks = <Map<String, dynamic>>[];
    
    // Get tracks from all specified artists
    print('🎵 Generating quiz for artists: $artistNames');
    for (final artistName in artistNames) {
      try {
        print('🔍 Searching tracks for: $artistName');
        // First get popular tracks which usually have previews
        final artistTracks = await EnhancedSpotifyService.searchTracks(
          '$artistName',
          limit: 50,
        );
        print('✅ Found ${artistTracks.length} tracks for $artistName');
        tracks.addAll(artistTracks);
      } catch (e) {
        print('❌ Error fetching tracks for $artistName: $e');
      }
    }
    print('📊 Total tracks collected: ${tracks.length}');
    
    if (tracks.isEmpty) {
      print('❌ No tracks found for any artist!');
      throw Exception('No tracks found for the specified artists');
    }
    
    // Filter tracks with preview URLs  
    final tracksWithPreview = tracks.where((t) => t['preview_url'] != null).toList();
    print('🎧 Tracks with preview: ${tracksWithPreview.length}/${tracks.length}');
    
    // Debug: Log first few tracks to see structure
    if (tracks.isNotEmpty) {
      print('🔍 Sample track keys: ${tracks[0].keys.toList()}');
      print('🔍 Sample preview_url: ${tracks[0]['preview_url']}');
    }
    
    // If no previews available, use all tracks (fallback mode)
    final tracksToUse = tracksWithPreview.isNotEmpty ? tracksWithPreview : tracks;
    print('🎵 Using ${tracksToUse.length} tracks (${tracksWithPreview.isEmpty ? "NO PREVIEW MODE" : "WITH PREVIEWS"})');
    
    if (tracksToUse.isEmpty) {
      throw Exception('No songs found for these artists');
    }
    
    // Generate questions
    final usedTrackNames = <String>{};
    for (var i = 0; i < questionCount && tracksToUse.length >= 3; i++) {
      // Pick a random correct track that hasn't been used
      Map<String, dynamic>? correctTrack;
      for (var attempt = 0; attempt < 50; attempt++) {
        final track = tracksToUse[_random.nextInt(tracksToUse.length)];
        final trackName = track['name'] as String;
        if (!usedTrackNames.contains(trackName)) {
          correctTrack = track;
          usedTrackNames.add(trackName);
          break;
        }
      }
      
      if (correctTrack == null) {
        print('⚠️ Could not find unique track for question ${i + 1}');
        continue;
      }
      
      final correctTrackName = correctTrack['name'] as String;
      
      // Get wrong options (different tracks from same pool)
      final wrongTracks = <Map<String, dynamic>>[];
      for (var attempt = 0; attempt < 100 && wrongTracks.length < 2; attempt++) {
        final randomTrack = tracksToUse[_random.nextInt(tracksToUse.length)];
        final trackName = randomTrack['name'] as String;
        
        if (trackName != correctTrackName && 
            !wrongTracks.any((t) => t['name'] == trackName)) {
          wrongTracks.add(randomTrack);
        }
      }
      
      if (wrongTracks.length < 2) {
        print('⚠️ Could not find enough wrong options for question ${i + 1}');
        continue;
      }
      
      // Create options
      final options = <String>[
        correctTrackName,
        ...wrongTracks.map((t) => t['name'] as String),
      ]..shuffle();
      
      // Get album covers for all options
      final trackCovers = <String, String>{};
      trackCovers[correctTrackName] = correctTrack['album']?['images']?[0]?['url'] ?? '';
      for (final wrongTrack in wrongTracks) {
        trackCovers[wrongTrack['name'] as String] = wrongTrack['album']?['images']?[0]?['url'] ?? '';
      }
      
      print('✅ Question ${i + 1}: ${correctTrackName} vs ${wrongTracks.map((t) => t["name"]).join(", ")}');
      
      // Get preview URL - try Spotify first, then Apple Music as fallback
      String previewUrl = correctTrack['preview_url'] ?? '';
      if (previewUrl.isEmpty) {
        print('🍎 Spotify preview not available, trying Apple Music...');
        final applePreview = await AppleMusicService.getTrackPreview(
          trackName: correctTrackName,
          artistName: correctTrack['artists'][0]['name'],
        );
        if (applePreview != null) {
          previewUrl = applePreview;
          print('✅ Using Apple Music preview');
        }
      }
      
      questions.add(QuizQuestion(
        id: 'q_${i + 1}',
        type: 'guess_song',
        previewUrl: previewUrl,
        correctAnswer: correctTrackName,
        options: options,
        metadata: {
          'artistName': correctTrack['artists'][0]['name'],
          'albumCover': correctTrack['album']?['images']?[0]?['url'] ?? '',
          'trackCovers': trackCovers, // All track covers
          'trackId': correctTrack['id'],
          'hasPreview': previewUrl.isNotEmpty,
        },
      ));
    }
    
    final sessionId = _firestore.collection('quiz_sessions').doc().id;
    
    return QuizSession(
      id: sessionId,
      userId: userId,
      type: 'guess_song',
      questions: questions,
      userAnswers: {},
      score: 0,
      startedAt: DateTime.now(),
    );
  }
  
  // ==================== GAME MODE 2: GUESS THE ARTIST ====================
  
  /// Generate "Guess the Artist" quiz
  /// User selects a genre (Turkish or Global)
  /// For each question: play 5sec preview, show 3 artist options (1 correct + 2 from same genre)
  static Future<QuizSession> generateGuessArtistQuiz({
    required String userId,
    required String genre,
    int questionCount = 10,
  }) async {
    print('🎸 Generating artist quiz for genre: $genre');
    final isTurkish = turkishGenres.contains(genre);
    final tracks = <Map<String, dynamic>>[];
    
    if (isTurkish) {
      // For Turkish genres, search with Turkish artists
      print('🇹🇷 Turkish genre detected');
      final genreKey = genre.replaceAll('Türkçe ', '').toLowerCase();
      for (final artist in turkishArtists.take(10)) {
        try {
          print('🔍 Searching: $artist');
          final artistTracks = await EnhancedSpotifyService.searchTracks(
            '$artist',
            limit: 20,
          );
          print('✅ Found ${artistTracks.length} tracks for $artist');
          tracks.addAll(artistTracks);
        } catch (e) {
          print('❌ Error fetching Turkish tracks: $e');
        }
      }
    } else {
      // For global genres, search with genre
      print('🌍 Global genre: ${genre.toLowerCase()}');
      try {
        // Search for popular artists in genre
        final genreTracks = await EnhancedSpotifyService.searchTracks(
          'genre ${genre.toLowerCase()}',
          limit: 50,
        );
        print('✅ Found ${genreTracks.length} tracks');
        tracks.addAll(genreTracks);
      } catch (e) {
        print('❌ Error fetching global tracks: $e');
      }
    }
    print('📊 Total tracks collected: ${tracks.length}');
    
    if (tracks.isEmpty) {
      print('❌ No tracks found for genre: $genre');
      throw Exception('No tracks found for genre: $genre');
    }
    
    // Filter tracks with preview URLs
    final tracksWithPreview = tracks.where((t) => t['preview_url'] != null).toList();
    print('🎧 Tracks with preview: ${tracksWithPreview.length}/${tracks.length}');
    
    // Use all tracks if no previews (fallback mode)
    final tracksToUse = tracksWithPreview.isNotEmpty ? tracksWithPreview : tracks;
    print('🎸 Using ${tracksToUse.length} tracks for genre quiz');
    
    if (tracksToUse.isEmpty) {
      throw Exception('No songs found for this genre');
    }
    
    final questions = <QuizQuestion>[];
    final usedArtists = <String>{};
    
    // Generate questions
    for (var i = 0; i < questionCount && tracksToUse.isNotEmpty; i++) {
      // Pick a random correct track
      Map<String, dynamic>? correctTrack;
      for (var attempt = 0; attempt < 20; attempt++) {
        final track = tracksToUse[_random.nextInt(tracksToUse.length)];
        final artistName = track['artists']?[0]?['name'] as String?;
        
        if (artistName != null && !usedArtists.contains(artistName)) {
          correctTrack = track;
          usedArtists.add(artistName);
          break;
        }
      }
      
      if (correctTrack == null) continue;
      
      final correctArtistName = correctTrack['artists'][0]['name'] as String;
      
      // Get wrong options (different artists from same pool)
      final wrongArtists = <String>[];
      for (var attempt = 0; attempt < 50 && wrongArtists.length < 2; attempt++) {
        final randomTrack = tracksToUse[_random.nextInt(tracksToUse.length)];
        final artistName = randomTrack['artists']?[0]?['name'] as String?;
        
        if (artistName != null && 
            artistName != correctArtistName && 
            !wrongArtists.contains(artistName)) {
          wrongArtists.add(artistName);
        }
      }
      
      if (wrongArtists.length < 2) continue;
      
      // Create options
      final options = <String>[
        correctArtistName,
        ...wrongArtists,
      ]..shuffle();
      
      // Get artist images if available
      final artistImages = <String, String>{};
      for (final artistName in options) {
        try {
          final artists = await EnhancedSpotifyService.searchArtists(artistName, limit: 1);
          if (artists.isNotEmpty && artists[0]['images'] != null && artists[0]['images'].isNotEmpty) {
            artistImages[artistName] = artists[0]['images'][0]['url'];
          }
        } catch (e) {
          print('Error fetching artist image: $e');
        }
      }
      
      // Get preview URL - try Spotify first, then Apple Music
      String previewUrl = correctTrack['preview_url'] ?? '';
      if (previewUrl.isEmpty) {
        print('🍎 Spotify preview not available, trying Apple Music...');
        final applePreview = await AppleMusicService.getTrackPreview(
          trackName: correctTrack['name'],
          artistName: correctArtistName,
        );
        if (applePreview != null) {
          previewUrl = applePreview;
          print('✅ Using Apple Music preview');
        }
      }
      
      questions.add(QuizQuestion(
        id: 'q_${i + 1}',
        type: 'guess_artist',
        previewUrl: previewUrl,
        correctAnswer: correctArtistName,
        options: options,
        metadata: {
          'trackName': correctTrack['name'],
          'genre': genre,
          'artistImages': artistImages,
          'hasPreview': previewUrl.isNotEmpty,
        },
      ));
    }
    
    final sessionId = _firestore.collection('quiz_sessions').doc().id;
    
    return QuizSession(
      id: sessionId,
      userId: userId,
      type: 'guess_artist',
      questions: questions,
      userAnswers: {},
      score: 0,
      startedAt: DateTime.now(),
    );
  }
  
  // ==================== HELPER METHODS ====================
  
  
  // ==================== SESSION MANAGEMENT ====================
  
  /// Save quiz session to Firebase
  static Future<void> saveQuizSession(QuizSession session) async {
    try {
      print('💾 Saving quiz session: ${session.id}');
      await _firestore.collection('quiz_sessions').doc(session.id).set(session.toJson());
      print('✅ Quiz session saved successfully');
    } catch (e) {
      print('❌ Error saving quiz session: $e');
      print('❌ Session data: ${session.toJson()}');
      rethrow;
    }
  }
  
  /// Update user answer
  static Future<void> submitAnswer(
    String sessionId,
    String questionId,
    String answer,
  ) async {
    await _firestore.collection('quiz_sessions').doc(sessionId).update({
      'userAnswers.$questionId': answer,
    });
  }
  
  /// Complete quiz and calculate score
  static Future<int> completeQuiz(QuizSession session) async {
    final score = session.correctAnswers * 10; // 10 points per correct answer
    
    await _firestore.collection('quiz_sessions').doc(session.id).update({
      'score': score,
      'completedAt': FieldValue.serverTimestamp(),
      'accuracy': session.accuracy,
    });
    
    // Update user's total score in leaderboard
    await _updateLeaderboard(session.userId, score);
    
    return score;
  }
  
  /// Update leaderboard
  static Future<void> _updateLeaderboard(String userId, int score) async {
    final leaderboardRef = _firestore.collection('leaderboard').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(leaderboardRef);
      
      if (doc.exists) {
        final currentScore = doc.data()?['totalScore'] ?? 0;
        final gamesPlayed = doc.data()?['gamesPlayed'] ?? 0;
        
        transaction.update(leaderboardRef, {
          'totalScore': currentScore + score,
          'gamesPlayed': gamesPlayed + 1,
          'lastPlayed': FieldValue.serverTimestamp(),
        });
      } else {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        
        transaction.set(leaderboardRef, {
          'userId': userId,
          'username': userDoc.data()?['username'] ?? 'Unknown',
          'profileImageUrl': userDoc.data()?['profileImageUrl'] ?? '',
          'totalScore': score,
          'gamesPlayed': 1,
          'lastPlayed': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  
  // ==================== LEADERBOARD ====================
  
  /// Get monthly leaderboard
  static Future<List<Map<String, dynamic>>> getMonthlyLeaderboard({int limit = 50}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final snapshot = await _firestore
        .collection('leaderboard')
        .where('lastPlayed', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .orderBy('lastPlayed', descending: false)
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }
  
  /// Get user's leaderboard rank
  static Future<int> getUserRank(String userId) async {
    final userDoc = await _firestore.collection('leaderboard').doc(userId).get();
    
    if (!userDoc.exists) return -1;
    
    final userScore = userDoc.data()?['totalScore'] ?? 0;
    
    final higherScores = await _firestore
        .collection('leaderboard')
        .where('totalScore', isGreaterThan: userScore)
        .get();
    
    return higherScores.docs.length + 1;
  }
  
  // ==================== DAILY LIMIT (FREE USERS) ====================
  
  /// Check if user can play (free users: 3 games/day)
  static Future<bool> canUserPlay(String userId, {required bool isPro}) async {
    if (isPro) return true; // Pro users have unlimited games
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final todayGames = await _firestore
        .collection('quiz_sessions')
        .where('userId', isEqualTo: userId)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    return todayGames.docs.length < 3;
  }
  
  /// Get remaining games for today
  static Future<int> getRemainingGames(String userId, {required bool isPro}) async {
    if (isPro) return 999; // Pro users have unlimited
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final todayGames = await _firestore
        .collection('quiz_sessions')
        .where('userId', isEqualTo: userId)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    return max(0, 3 - todayGames.docs.length);
  }
}
