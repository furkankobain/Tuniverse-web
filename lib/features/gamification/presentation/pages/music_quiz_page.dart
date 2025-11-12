import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/music_quiz_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class MusicQuizPage extends StatelessWidget {
  const MusicQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Quiz')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _QuizTypeCard(
            icon: '🎵',
            title: 'Guess the Song',
            description: 'Identify songs from audio',
            color: Colors.blue,
                onTap: () => _startQuiz(context, QuizType.guessTheSong),
          ),
          _QuizTypeCard(
            icon: '🎤',
            title: 'Guess the Artist',
            description: 'Name the artist',
            color: Colors.purple,
                onTap: () => _startQuiz(context, QuizType.guessTheArtist),
          ),
          _QuizTypeCard(
            icon: '📅',
            title: 'Guess the Year',
            description: 'When was it released?',
            color: Colors.orange,
                onTap: () => _startQuiz(context, QuizType.guessTheYear),
          ),
          _QuizTypeCard(
            icon: '🎸',
            title: 'Guess the Genre',
            description: 'What genre is this?',
            color: Colors.green,
                onTap: () => _startQuiz(context, QuizType.guessTheGenre),
          ),
          _QuizTypeCard(
            icon: '📝',
            title: 'Finish Lyrics',
            description: 'Complete the song',
            color: Colors.pink,
                onTap: () => _startQuiz(context, QuizType.finishTheLyrics),
          ),
          _QuizTypeCard(
            icon: '🖼️',
            title: 'Album Cover',
            description: 'Guess from cover art',
            color: Colors.teal,
                onTap: () => _startQuiz(context, QuizType.albumCover),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz(BuildContext context, QuizType type) async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final quiz = await MusicQuizService.generateQuiz(
      type: type,
      userId: currentUser.userId,
      questionCount: 10,
    );

    if (context.mounted) {
      Navigator.pop(context);
      if (quiz.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz generated! Feature coming soon.')),
        );
      }
    }
  }
}

class _QuizTypeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuizTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
