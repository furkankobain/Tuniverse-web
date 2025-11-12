class QuizQuestion {
  final String id;
  final String type; // 'guess_song' or 'guess_artist'
  final String previewUrl;
  final String correctAnswer;
  final List<String> options;
  final Map<String, dynamic> metadata; // Additional info like images, artist names, etc.
  
  QuizQuestion({
    required this.id,
    required this.type,
    required this.previewUrl,
    required this.correctAnswer,
    required this.options,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'previewUrl': previewUrl,
    'correctAnswer': correctAnswer,
    'options': options,
    'metadata': metadata,
  };
  
  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['id'],
    type: json['type'],
    previewUrl: json['previewUrl'],
    correctAnswer: json['correctAnswer'],
    options: List<String>.from(json['options']),
    metadata: json['metadata'],
  );
}

class QuizSession {
  final String id;
  final String userId;
  final String type; // 'guess_song' or 'guess_artist'
  final List<QuizQuestion> questions;
  final Map<String, String> userAnswers; // questionId -> answer
  final int score;
  final DateTime startedAt;
  final DateTime? completedAt;
  
  QuizSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.startedAt,
    this.completedAt,
  });
  
  int get correctAnswers => userAnswers.entries
      .where((entry) {
        final question = questions.firstWhere((q) => q.id == entry.key);
        return question.correctAnswer == entry.value;
      })
      .length;
  
  double get accuracy => questions.isEmpty ? 0 : (correctAnswers / questions.length);
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type,
    'questions': questions.map((q) => q.toJson()).toList(),
    'userAnswers': userAnswers,
    'score': score,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };
  
  factory QuizSession.fromJson(Map<String, dynamic> json) => QuizSession(
    id: json['id'],
    userId: json['userId'],
    type: json['type'],
    questions: (json['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList(),
    userAnswers: Map<String, String>.from(json['userAnswers']),
    score: json['score'],
    startedAt: DateTime.parse(json['startedAt']),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
  );
}
