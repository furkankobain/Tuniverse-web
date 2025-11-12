import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/services/advanced_quiz_service.dart';
import 'quiz_game_page.dart';

class GuessArtistSetupPage extends StatefulWidget {
  const GuessArtistSetupPage({super.key});

  @override
  State<GuessArtistSetupPage> createState() => _GuessArtistSetupPageState();
}

class _GuessArtistSetupPageState extends State<GuessArtistSetupPage> {
  String? _selectedGenre;
  bool _isGenerating = false;

  Future<void> _startQuiz() async {
    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a genre first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Generate quiz
      final session = await AdvancedQuizService.generateGuessArtistQuiz(
        userId: user.uid,
        genre: _selectedGenre!,
        questionCount: 10,
      );

      if (!mounted) return;

      if (session.questions.isEmpty) {
        throw Exception('No songs with previews found for this genre');
      }

      // Save session to Firebase (skip for now due to permission issues)
      try {
        await AdvancedQuizService.saveQuizSession(session);
      } catch (e) {
        print('⚠️ Could not save session to Firebase, continuing anyway: $e');
      }

      // Navigate to game page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizGamePage(session: session),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isGenerating = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B46C1), Color(0xFF2D1B69)],
          ),
        ),
        child: _isGenerating
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Generating your quiz...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Finding $_selectedGenre artists',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Tab Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mic, color: Color(0xFFFFD700), size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Guess the Artist',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      const Text(
                        'Listen for 5 seconds and guess the artist',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Select Genres Title
                      const Text(
                        'Select Genres',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Turkish Genres
                      const Row(
                        children: [
                          Text('🇹🇷', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Turkish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AdvancedQuizService.turkishGenres.map((genre) {
                          return _buildModernGenreChip(genre, true);
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Global Genres
                      const Row(
                        children: [
                          Text('🌍', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Global',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AdvancedQuizService.globalGenres.map((genre) {
                          return _buildModernGenreChip(genre, false);
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      // PLAY Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4444).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _selectedGenre != null ? _startQuiz : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _selectedGenre != null ? 'PLAY' : 'SELECT A GENRE',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildModernGenreChip(String genre, bool isTurkish) {
    final isSelected = _selectedGenre == genre;
    final genreIcon = _getGenreIcon(genre, isTurkish);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGenre = isSelected ? null : genre;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              genreIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              genre,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGenreIcon(String genre, bool isTurkish) {
    if (isTurkish) return '🇹🇷';
    
    switch (genre) {
      case 'Pop': return '🎵';
      case 'Rock': return '🎸';
      case 'Hip-Hop': return '🎤';
      case 'Electronic': return '🎶';
      case 'R&B': return '🎹';
      case 'Country': return '🤠';
      case 'Jazz': return '🎷';
      case 'Classical': return '🎻';
      case 'Latin': return '🎺';
      case 'Metal': return '🤘';
      case 'Indie': return '🎧';
      case 'K-Pop': return '🇰🇷';
      default: return '🎵';
    }
  }

  Widget _buildInstructionItem(String number, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
