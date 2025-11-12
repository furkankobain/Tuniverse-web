import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../shared/models/quiz_question.dart';
import '../../../../shared/services/advanced_quiz_service.dart';
import 'quiz_result_page.dart';

class QuizGamePage extends StatefulWidget {
  final QuizSession session;

  const QuizGamePage({super.key, required this.session});

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage> {
  late AudioPlayer _audioPlayer;
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  bool _isPlaying = false;
  final Map<String, String> _userAnswers = {};
  
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadAndPlayPreview();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlayPreview() async {
    final question = widget.session.questions[_currentQuestionIndex];
    
    // Skip if no preview URL
    if (question.previewUrl.isEmpty) {
      print('⚠️ No preview available for this question');
      return;
    }
    
    try {
      await _audioPlayer.setUrl(question.previewUrl);
      await _audioPlayer.play();
      setState(() => _isPlaying = true);
      
      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _audioPlayer.pause();
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });

    final question = widget.session.questions[_currentQuestionIndex];
    _userAnswers[question.id] = answer;

    // Auto advance after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < widget.session.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
      await _loadAndPlayPreview();
    } else {
      // Quiz completed
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    // Update session with answers
    final updatedSession = QuizSession(
      id: widget.session.id,
      userId: widget.session.userId,
      type: widget.session.type,
      questions: widget.session.questions,
      userAnswers: _userAnswers,
      score: 0,
      startedAt: widget.session.startedAt,
      completedAt: DateTime.now(),
    );

    // Calculate score
    final score = await AdvancedQuizService.completeQuiz(updatedSession);

    if (!mounted) return;

    // Navigate to results
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultPage(
          session: updatedSession,
          score: score,
        ),
      ),
    );
  }

  Future<void> _replayAudio() async {
    final question = widget.session.questions[_currentQuestionIndex];
    
    // Skip if no preview
    if (question.previewUrl.isEmpty) return;
    
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      setState(() => _isPlaying = true);
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _audioPlayer.pause();
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      print('Error replaying audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.session.questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Quit Quiz?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Your progress will be lost. Are you sure?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue', style: TextStyle(color: Color(0xFFFFD700))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Quit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Quit Quiz?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Your progress will be lost.',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Continue', style: TextStyle(color: Color(0xFFFFD700))),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Quit', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (shouldPop == true && mounted) {
                Navigator.pop(context);
              }
            },
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
          child: SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  // Question dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.session.questions.length, (index) {
                      final isCompleted = index < _currentQuestionIndex;
                      final isCurrent = index == _currentQuestionIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFFFFD700)
                              : isCurrent
                                  ? const Color(0xFFFF4444)
                                  : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Audio player card (only show if preview available)
                  if (question.previewUrl.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Play button
                          GestureDetector(
                            onTap: _hasAnswered ? null : _replayAudio,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isPlaying
                                      ? [Color(0xFFFFD700), Color(0xFFFFA500)]
                                      : [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isPlaying ? Color(0xFFFFD700) : Color(0xFF6B46C1))
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isPlaying ? '🎵 Playing Preview...' : 'Tap to Play',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '5 seconds',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // No preview warning
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Audio preview not available',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Question text
                  Text(
                    question.type == 'guess_song'
                        ? '🎵 Which song is this?'
                        : '🎤 Who is the artist?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (question.metadata['artistName'] != null &&
                      question.type == 'guess_song') ...[
                    const SizedBox(height: 8),
                    Text(
                      'by ${question.metadata['artistName']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Options
                  ...question.options.map((option) {
                    final isSelected = _selectedAnswer == option;
                    final isCorrect = option == question.correctAnswer;
                    final showResult = _hasAnswered;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionCard(
                        option: option,
                        onTap: () => _selectAnswer(option),
                        showResult: showResult,
                        isCorrect: isCorrect,
                        isSelected: isSelected,
                        metadata: question.metadata,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String option,
    required VoidCallback onTap,
    required bool showResult,
    required bool isCorrect,
    required bool isSelected,
    required Map<String, dynamic> metadata,
  }) {
    // Get image URL - could be artist image or track cover
    final artistImages = metadata['artistImages'] as Map<String, dynamic>?;
    final trackCovers = metadata['trackCovers'] as Map<String, dynamic>?;
    final imageUrl = artistImages?[option] as String? ?? trackCovers?[option] as String?;

    // Modern color scheme
    Color? cardColor;
    Color? cardBorderColor;
    BoxShadow? cardShadow;

    if (showResult) {
      if (isSelected && isCorrect) {
        cardColor = const Color(0xFF10B981);
        cardBorderColor = const Color(0xFF10B981);
        cardShadow = BoxShadow(
          color: const Color(0xFF10B981).withOpacity(0.4),
          blurRadius: 15,
          offset: const Offset(0, 5),
        );
      } else if (isSelected && !isCorrect) {
        cardColor = const Color(0xFFEF4444);
        cardBorderColor = const Color(0xFFEF4444);
        cardShadow = BoxShadow(
          color: const Color(0xFFEF4444).withOpacity(0.4),
          blurRadius: 15,
          offset: const Offset(0, 5),
        );
      } else if (isCorrect) {
        cardColor = const Color(0xFF10B981);
        cardBorderColor = const Color(0xFF10B981);
      } else {
        cardColor = const Color(0xFF1E293B);
        cardBorderColor = Colors.white.withOpacity(0.2);
      }
    } else {
      cardColor = const Color(0xFF1E293B);
      cardBorderColor = Colors.white.withOpacity(0.2);
      cardShadow = BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 3),
      );
    }

    return GestureDetector(
      onTap: _hasAnswered ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorderColor!,
            width: 2,
          ),
          boxShadow: cardShadow != null ? [cardShadow] : [],
        ),
        child: Row(
          children: [
            // Album cover or Artist image (if available)
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[800],
                      child: Icon(
                        trackCovers != null ? Icons.music_note : Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ] else if (trackCovers != null || artistImages != null) ...[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  trackCovers != null ? Icons.music_note : Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
            ],

            // Option text
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            // Result icon
            if (showResult && (isCorrect || isSelected))
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
