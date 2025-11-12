import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuniverse/shared/services/enhanced_spotify_service.dart';

/// Quiz types
enum QuizType {
  guessTheSong,      // Guess song from lyrics snippet
  guessTheArtist,    // Guess artist from song
  guessTheYear,      // Guess release year
  guessTheGenre,     // Guess genre
  finishTheLyrics,   // Complete the lyrics
  albumCover,        // Guess song/album from cover
}

/// Music quiz service - trivia, challenges, and scoring
class MusicQuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // ==================== QUIZ TYPES ====================

  // ==================== GENERATE QUIZ ====================

  /// Generate a quiz
  static Future<Map<String, dynamic>> generateQuiz({
    required QuizType type,
    required String userId,
    int questionCount = 10,
  }) async {
    try {
      final questions = <Map<String, dynamic>>[];
      
      // Get user's favorite tracks for personalized questions
      final favoriteTracks = await EnhancedSpotifyService.getTopTracks(timeRange: 'medium_term', limit: 50);
      
      for (var i = 0; i < questionCount; i++) {
        Map<String, dynamic>? question;
        
        switch (type) {
          case QuizType.guessTheSong:
            question = await _generateGuessTheSongQuestion(favoriteTracks);
            break;
          case QuizType.guessTheArtist:
            question = await _generateGuessTheArtistQuestion(favoriteTracks);
            break;
          case QuizType.guessTheYear:
            question = await _generateGuessTheYearQuestion(favoriteTracks);
            break;
          case QuizType.guessTheGenre:
            question = await _generateGuessTheGenreQuestion(favoriteTracks);
            break;
          case QuizType.finishTheLyrics:
            question = await _generateFinishTheLyricsQuestion(favoriteTracks);
            break;
          case QuizType.albumCover:
            question = await _generateAlbumCoverQuestion(favoriteTracks);
            break;
        }
        
        if (question != null) {
          questions.add({...question, 'questionNumber': i + 1});
        }
      }
      
      // Create quiz session
      final quizId = _firestore.collection('quizzes').doc().id;
      await _firestore.collection('quizzes').doc(quizId).set({
        'userId': userId,
        'type': type.toString(),
        'questions': questions,
        'createdAt': FieldValue.serverTimestamp(),
        'completed': false,
        'score': 0,
      });
      
      return {
        'quizId': quizId,
        'type': type.toString(),
        'questions': questions,
      };
    } catch (e) {
      print('Error generating quiz: $e');
      return {};
    }
  }

  /// Generate "Guess the Song" question
  static Future<Map<String, dynamic>?> _generateGuessTheSongQuestion(List<dynamic> tracks) async {
    if (tracks.isEmpty) return null;
    
    final correctTrack = tracks[_random.nextInt(tracks.length)];
    final options = [correctTrack];
    
    // Add 3 random wrong answers
    while (options.length < 4) {
      final randomTrack = tracks[_random.nextInt(tracks.length)];
      if (!options.any((t) => t['id'] == randomTrack['id'])) {
        options.add(randomTrack);
      }
    }
    
    options.shuffle();
    
    return {
      'type': 'guessTheSong',
      'question': 'Which song is this?',
      'hint': 'Artist: ${correctTrack['artists'][0]['name']}',
      'previewUrl': correctTrack['preview_url'],
      'options': options.map((t) => t['name']).toList(),
      'correctAnswer': correctTrack['name'],
      'points': 10,
    };
  }

  /// Generate "Guess the Artist" question
  static Future<Map<String, dynamic>?> _generateGuessTheArtistQuestion(List<dynamic> tracks) async {
    if (tracks.isEmpty) return null;
    
    final correctTrack = tracks[_random.nextInt(tracks.length)];
    final correctArtist = correctTrack['artists'][0]['name'];
    final options = [correctArtist];
    
    // Add 3 random wrong answers
    while (options.length < 4) {
      final randomTrack = tracks[_random.nextInt(tracks.length)];
      final artistName = randomTrack['artists'][0]['name'];
      if (!options.contains(artistName)) {
        options.add(artistName);
      }
    }
    
    options.shuffle();
    
    return {
      'type': 'guessTheArtist',
      'question': 'Who is the artist of "${correctTrack['name']}"?',
      'albumCover': correctTrack['album']['images'][0]['url'],
      'options': options,
      'correctAnswer': correctArtist,
      'points': 10,
    };
  }

  /// Generate "Guess the Year" question
  static Future<Map<String, dynamic>?> _generateGuessTheYearQuestion(List<dynamic> tracks) async {
    if (tracks.isEmpty) return null;
    
    final correctTrack = tracks[_random.nextInt(tracks.length)];
    final releaseDate = correctTrack['album']['release_date'] as String;
    final correctYear = int.parse(releaseDate.split('-')[0]);
    
    // Generate options with +/- random years
    final options = <int>{correctYear};
    while (options.length < 4) {
      final offset = _random.nextInt(10) - 5; // -5 to +5 years
      final year = correctYear + offset;
      if (year > 1950 && year <= DateTime.now().year) {
        options.add(year);
      }
    }
    
    final optionsList = options.toList()..shuffle();
    
    return {
      'type': 'guessTheYear',
      'question': 'When was "${correctTrack['name']}" by ${correctTrack['artists'][0]['name']} released?',
      'albumCover': correctTrack['album']['images'][0]['url'],
      'options': optionsList.map((y) => y.toString()).toList(),
      'correctAnswer': correctYear.toString(),
      'points': 15,
    };
  }

  /// Generate "Guess the Genre" question
  static Future<Map<String, dynamic>?> _generateGuessTheGenreQuestion(List<dynamic> tracks) async {
    if (tracks.isEmpty) return null;
    
    final correctTrack = tracks[_random.nextInt(tracks.length)];
    
    // Common genres
    final allGenres = ['Pop', 'Rock', 'Hip Hop', 'Electronic', 'R&B', 'Country', 'Jazz', 'Classical', 'Metal', 'Indie'];
    final correctGenre = allGenres[_random.nextInt(allGenres.length)];
    final options = {correctGenre};
    
    while (options.length < 4) {
      options.add(allGenres[_random.nextInt(allGenres.length)]);
    }
    
    final optionsList = options.toList()..shuffle();
    
    return {
      'type': 'guessTheGenre',
      'question': 'What genre is "${correctTrack['name']}"?',
      'albumCover': correctTrack['album']['images'][0]['url'],
      'previewUrl': correctTrack['preview_url'],
      'options': optionsList,
      'correctAnswer': correctGenre,
      'points': 10,
    };
  }

  /// Generate "Finish the Lyrics" question
  static Future<Map<String, dynamic>?> _generateFinishTheLyricsQuestion(List<dynamic> tracks) async {
    if (tracks.isEmpty) return null;
    
    final correctTrack = tracks[_random.nextInt(tracks.length)];
    
    // Mock lyrics snippet (in real app, fetch from lyrics API)
    final lyricSnippet = 'I will always love you...';
    
    return {
      'type': 'finishTheLyrics',
      'question': 'Finish the lyrics from "${correctTrack['name']}":',
      'lyricSnippet': lyricSnippet,
      'isTextInput': true,
      'correctAnswer': 'and I will always love you',
      'points': 20,
    };
  }

  /// Generate "Album Cover" question
  static Future<Map<String, dynamic>?> _generateAlbumCoverQuestion(List<dynamic> tracks) async {
    if (tracks.isEmpty) return null;
    
    final correctTrack = tracks[_random.nextInt(tracks.length)];
    final options = [correctTrack['album']['name']];
    
    // Add 3 random wrong answers
    while (options.length < 4) {
      final randomTrack = tracks[_random.nextInt(tracks.length)];
      final albumName = randomTrack['album']['name'];
      if (!options.contains(albumName)) {
        options.add(albumName);
      }
    }
    
    options.shuffle();
    
    return {
      'type': 'albumCover',
      'question': 'Which album is this?',
      'albumCover': correctTrack['album']['images'][0]['url'],
      'options': options,
      'correctAnswer': correctTrack['album']['name'],
      'points': 15,
    };
  }

  // ==================== SUBMIT ANSWER ====================

  /// Submit answer and calculate score
  static Future<Map<String, dynamic>> submitAnswer({
    required String quizId,
    required int questionNumber,
    required String answer,
  }) async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        return {'error': 'Quiz not found'};
      }
      
      final quizData = quizDoc.data()!;
      final questions = List<Map<String, dynamic>>.from(quizData['questions']);
      final question = questions.firstWhere((q) => q['questionNumber'] == questionNumber);
      
      final correctAnswer = question['correctAnswer'] as String;
      final isCorrect = answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
      final points = isCorrect ? (question['points'] as int) : 0;
      
      // Update quiz progress
      question['userAnswer'] = answer;
      question['isCorrect'] = isCorrect;
      question['pointsEarned'] = points;
      
      await _firestore.collection('quizzes').doc(quizId).update({
        'questions': questions,
        'score': FieldValue.increment(points),
      });
      
      return {
        'isCorrect': isCorrect,
        'correctAnswer': correctAnswer,
        'pointsEarned': points,
      };
    } catch (e) {
      print('Error submitting answer: $e');
      return {'error': e.toString()};
    }
  }

  /// Complete quiz
  static Future<Map<String, dynamic>> completeQuiz(String quizId) async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        return {'error': 'Quiz not found'};
      }
      
      final quizData = quizDoc.data()!;
      final questions = List<Map<String, dynamic>>.from(quizData['questions']);
      final totalScore = quizData['score'] as int;
      final maxScore = questions.fold<int>(0, (sum, q) => sum + (q['points'] as int));
      final percentage = (totalScore / maxScore * 100).round();
      
      await _firestore.collection('quizzes').doc(quizId).update({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'maxScore': maxScore,
        'percentage': percentage,
      });
      
      // Award achievement points to user
      final userId = quizData['userId'] as String;
      await _awardQuizPoints(userId, totalScore);
      
      return {
        'score': totalScore,
        'maxScore': maxScore,
        'percentage': percentage,
        'grade': _getGrade(percentage),
      };
    } catch (e) {
      print('Error completing quiz: $e');
      return {'error': e.toString()};
    }
  }

  /// Award quiz points to user
  static Future<void> _awardQuizPoints(String userId, int points) async {
    await _firestore.collection('users').doc(userId).update({
      'totalPoints': FieldValue.increment(points),
      'quizzesCompleted': FieldValue.increment(1),
    });
  }

  /// Get grade from percentage
  static String _getGrade(int percentage) {
    if (percentage >= 90) return 'A+ 🏆';
    if (percentage >= 80) return 'A 🥇';
    if (percentage >= 70) return 'B 🥈';
    if (percentage >= 60) return 'C 🥉';
    if (percentage >= 50) return 'D 📚';
    return 'F 😢';
  }

  // ==================== WEEKLY CHALLENGES ====================

  /// Get weekly challenge
  static Future<Map<String, dynamic>> getWeeklyChallenge() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekId = '${weekStart.year}-W${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      
      final doc = await _firestore.collection('weekly_challenges').doc(weekId).get();
      
      if (doc.exists) {
        return doc.data()!;
      }
      
      // Create new weekly challenge
      final challenge = _generateWeeklyChallenge();
      await _firestore.collection('weekly_challenges').doc(weekId).set({
        ...challenge,
        'weekId': weekId,
        'startDate': Timestamp.fromDate(weekStart),
        'endDate': Timestamp.fromDate(weekStart.add(const Duration(days: 7))),
      });
      
      return challenge;
    } catch (e) {
      print('Error getting weekly challenge: $e');
      return {};
    }
  }

  /// Generate weekly challenge
  static Map<String, dynamic> _generateWeeklyChallenge() {
    final challenges = [
      {'name': 'Master Quizzer', 'description': 'Complete 5 quizzes this week', 'target': 5, 'type': 'quizzes', 'reward': 100},
      {'name': 'Perfect Score', 'description': 'Get 100% on any quiz', 'target': 100, 'type': 'percentage', 'reward': 200},
      {'name': 'Streak Master', 'description': 'Maintain a 7-day listening streak', 'target': 7, 'type': 'streak', 'reward': 150},
      {'name': 'Social Butterfly', 'description': 'Like 20 reviews this week', 'target': 20, 'type': 'likes', 'reward': 75},
      {'name': 'Critic\'s Choice', 'description': 'Write 5 reviews this week', 'target': 5, 'type': 'reviews', 'reward': 125},
    ];
    
    return challenges[_random.nextInt(challenges.length)];
  }

  /// Get user's weekly challenge progress
  static Future<Map<String, dynamic>> getUserWeeklyChallengeProgress(String userId) async {
    try {
      final challenge = await getWeeklyChallenge();
      if (challenge.isEmpty) return {};
      
      final weekId = challenge['weekId'] as String;
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_challenge_progress')
          .doc(weekId)
          .get();
      
      if (!doc.exists) {
        return {...challenge, 'progress': 0, 'completed': false};
      }
      
      final progress = doc.data()!;
      return {...challenge, ...progress};
    } catch (e) {
      print('Error getting challenge progress: $e');
      return {};
    }
  }

  /// Update weekly challenge progress
  static Future<void> updateWeeklyChallengeProgress(String userId, String type, int value) async {
    try {
      final challenge = await getWeeklyChallenge();
      if (challenge.isEmpty || challenge['type'] != type) return;
      
      final weekId = challenge['weekId'] as String;
      final progressRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_challenge_progress')
          .doc(weekId);
      
      final doc = await progressRef.get();
      final currentProgress = doc.exists ? (doc.data()!['progress'] as int? ?? 0) : 0;
      final newProgress = currentProgress + value;
      final target = challenge['target'] as int;
      
      await progressRef.set({
        'progress': newProgress,
        'completed': newProgress >= target,
        'completedAt': newProgress >= target ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));
      
      // Award reward if completed
      if (newProgress >= target && currentProgress < target) {
        await _firestore.collection('users').doc(userId).update({
          'totalPoints': FieldValue.increment(challenge['reward'] as int),
        });
      }
    } catch (e) {
      print('Error updating challenge progress: $e');
    }
  }

  // ==================== QUIZ HISTORY ====================

  /// Get user's quiz history
  static Future<List<Map<String, dynamic>>> getUserQuizHistory(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((d) {
        final data = d.data();
        return {
          'quizId': d.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting quiz history: $e');
      return [];
    }
  }

  /// Get quiz leaderboard
  static Future<List<Map<String, dynamic>>> getQuizLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('quizzesCompleted', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        return {
          'rank': entry.key + 1,
          'userId': entry.value.id,
          'username': data['username'],
          'quizzesCompleted': data['quizzesCompleted'] ?? 0,
          'totalPoints': data['totalPoints'] ?? 0,
          'profileImage': data['profileImage'],
        };
      }).toList();
    } catch (e) {
      print('Error getting quiz leaderboard: $e');
      return [];
    }
  }
}
