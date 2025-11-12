import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/services/advanced_quiz_service.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/models/quiz_question.dart';
import 'quiz_game_page.dart';

class GuessSongSetupPage extends StatefulWidget {
  const GuessSongSetupPage({super.key});

  @override
  State<GuessSongSetupPage> createState() => _GuessSongSetupPageState();
}

class _GuessSongSetupPageState extends State<GuessSongSetupPage> {
  final List<TextEditingController> _artistControllers = [TextEditingController()];
  bool _isGenerating = false;

  @override
  void dispose() {
    for (var controller in _artistControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addArtistField() {
    if (_artistControllers.length < 5) {
      setState(() {
        _artistControllers.add(TextEditingController());
      });
    }
  }

  void _removeArtistField(int index) {
    if (_artistControllers.length > 1) {
      setState(() {
        _artistControllers[index].dispose();
        _artistControllers.removeAt(index);
      });
    }
  }

  Future<void> _startQuiz() async {
    final artistNames = _artistControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (artistNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one artist name'),
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
      final session = await AdvancedQuizService.generateGuessSongQuiz(
        userId: user.uid,
        artistNames: artistNames,
        questionCount: 10,
      );

      if (!mounted) return;

      if (session.questions.isEmpty) {
        throw Exception('No songs with previews found for these artists');
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
      backgroundColor: Colors.transparent,
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
        child: SafeArea(
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
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Finding songs with previews',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Text('🎵', style: TextStyle(fontSize: 28)),
                            SizedBox(width: 12),
                            Text(
                              'Guess the Song',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Enter 1-5 artists and guess their songs!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Artist Names Section
                      const Text(
                        'Select Artists',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_artistControllers.length}/5 artists selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Artist input fields with autocomplete
                      ...List.generate(_artistControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.length < 2) {
                                return const Iterable<String>.empty();
                              }
                              try {
                                final artists = await EnhancedSpotifyService.searchArtists(
                                  textEditingValue.text,
                                  limit: 5,
                                );
                                return artists.map((a) => a['name'] as String);
                              } catch (e) {
                                return const Iterable<String>.empty();
                              }
                            },
                            onSelected: (String selection) {
                              _artistControllers[index].text = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              // Sync with our controller
                              if (_artistControllers[index].text.isNotEmpty && 
                                  controller.text != _artistControllers[index].text) {
                                controller.text = _artistControllers[index].text;
                              }
                              controller.addListener(() {
                                if (_artistControllers[index].text != controller.text) {
                                  _artistControllers[index].text = controller.text;
                                }
                              });
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Taylor Swift, Tarkan',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                                    suffixIcon: _artistControllers.length > 1
                                        ? IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () => _removeArtistField(index),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, i) {
                                        final option = options.elementAt(i);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: Color(0xFFFFD700),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    option,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),

                      // Add artist button
                      if (_artistControllers.length < 5)
                        GestureDetector(
                          onTap: _addArtistField,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 2,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Color(0xFFFFD700)),
                                SizedBox(width: 8),
                                Text(
                                  'Add Another Artist',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                          onPressed: _startQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'PLAY',
                            style: TextStyle(
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
}
