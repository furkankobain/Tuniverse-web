import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/services/advanced_quiz_service.dart';
import '../../../../shared/services/pro_status_service.dart';
import '../../../../shared/services/admob_service.dart';
import 'guess_song_setup_page.dart';
import 'guess_artist_setup_page.dart';

class QuizMainPage extends StatefulWidget {
  const QuizMainPage({super.key});

  @override
  State<QuizMainPage> createState() => _QuizMainPageState();
}

class _QuizMainPageState extends State<QuizMainPage> {
  int _remainingGames = 0;
  bool _isPro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isPro = await ProStatusService.isProUser();
    final remaining = await AdvancedQuizService.getRemainingGames(
      user.uid,
      isPro: isPro,
    );

    setState(() {
      _isPro = isPro;
      _remainingGames = remaining;
      _isLoading = false;
    });
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
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPro ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPro ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _isPro ? 'PRO ∞' : '$_remainingGames games left',
                  style: TextStyle(
                    color: _isPro ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B46C1), Color(0xFF2D1B69)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Title
                      const Text(
                        '♪ Music Quiz ♪',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Total plays counter
                      Text(
                        '▷ 855,629 plays',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Select Mode subtitle
                      const Text(
                        'Select Mode',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Game modes
                      _buildModernGameModeCard(
                        context,
                        title: 'Guess the Song',
                        icon: Icons.music_note,
                        onTap: () => _startGuessTheSong(context),
                      ),
                      const SizedBox(height: 16),
                      _buildModernGameModeCard(
                        context,
                        title: 'Guess the Artist',
                        icon: Icons.mic,
                        onTap: () => _startGuessTheArtist(context),
                      ),
                      const SizedBox(height: 32),

                      // Leaderboard button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/leaderboard'),
                          icon: const Icon(Icons.leaderboard, size: 24),
                          label: const Text(
                            'View Leaderboard',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      // Rewarded ad + Pro upgrade prompt for free users with 0 games
                      if (!_isPro && _remainingGames == 0) ...[
                        const SizedBox(height: 32),
                        _buildRewardedAdButton(context),
                        const SizedBox(height: 16),
                        _buildProUpgradePrompt(context),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildModernGameModeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B46C1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardedAdButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.videocam,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Watch Ad for Extra Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch a short ad and get 1 extra quiz attempt!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _watchRewardedAd(context),
            icon: const Icon(Icons.play_circle_filled),
            label: const Text(
              'Watch Ad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _watchRewardedAd(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
      
      // Show rewarded ad
      final earned = await AdMobService.showRewardedAd();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (earned) {
        // User watched the ad, give them 1 extra game
        setState(() {
          _remainingGames += 1;
        });
        
        if (!mounted) return;
        
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Extra Game Earned!'),
              ],
            ),
            content: const Text(
              'You earned 1 extra quiz attempt! 🎉',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text('Let\'s Play!'),
              ),
            ],
          ),
        );
      } else {
        // Ad not ready or user didn't watch
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available right now. Try again later!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error showing rewarded ad: $e');
      if (!mounted) return;
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load ad. Try again!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProUpgradePrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Want Unlimited Games?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to PRO for unlimited games, no ads, and more!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/pro-membership'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Upgrade to PRO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _startGuessTheSong(BuildContext context) async {
    if (_remainingGames == 0 && !_isPro) {
      _showNoGamesDialog(context);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GuessSongSetupPage(),
      ),
    );
    
    // Refresh remaining games after quiz
    _loadUserStatus();
  }

  void _startGuessTheArtist(BuildContext context) async {
    if (_remainingGames == 0 && !_isPro) {
      _showNoGamesDialog(context);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GuessArtistSetupPage(),
      ),
    );
    
    // Refresh remaining games after quiz
    _loadUserStatus();
  }

  void _showNoGamesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('No Games Left'),
          ],
        ),
        content: const Text(
          'You\'ve used all your free games for today. Upgrade to PRO for unlimited games!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/pro-membership');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Upgrade to PRO'),
          ),
        ],
      ),
    );
  }
}
