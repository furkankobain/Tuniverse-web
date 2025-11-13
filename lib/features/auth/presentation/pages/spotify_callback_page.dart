import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/spotify_sync_service.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Page to handle Spotify OAuth callback
class SpotifyCallbackPage extends StatefulWidget {
  final String? code;
  final String? state;
  final String? error;

  const SpotifyCallbackPage({
    super.key,
    this.code,
    this.state,
    this.error,
  });

  @override
  State<SpotifyCallbackPage> createState() => _SpotifyCallbackPageState();
}

class _SpotifyCallbackPageState extends State<SpotifyCallbackPage> {
  bool _isProcessing = true;
  String _statusMessage = 'Spotify bağlantısı kuruluyor...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Check for errors from Spotify
      if (widget.error != null) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _statusMessage = 'Spotify authorization cancelled';
        });
        return;
      }

      // Check if we have the authorization code
      if (widget.code == null || widget.state == null) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _statusMessage = 'Invalid authorization code';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Exchanging token...';
      });

      // Exchange authorization code for access token
      final success = await EnhancedSpotifyService.handleAuthCallback(
        widget.code!,
        widget.state!,
      );

      if (success) {
        setState(() { _statusMessage = 'Fetching profile...'; });
        final profile = await EnhancedSpotifyService.fetchUserProfile();
        
        final email = profile?['email'] as String?;
        final displayName = (profile?['display_name'] as String?)?.trim();
        final images = (profile?['images'] as List?) ?? [];
        final photoURL = images.isNotEmpty ? (images.first['url'] as String?) : null;
        final spotifyId = profile?['id'] as String?;

        // Check if user already exists (already logged in)
        User? currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null) {
          // User is logged in, just update Spotify connection
          setState(() { _statusMessage = 'Updating Spotify connection...'; });
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
            'spotifyConnected': true,
            'spotifyId': spotifyId,
            'photoURL': photoURL ?? currentUser.photoURL,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          setState(() { _statusMessage = 'Syncing Spotify data...'; });
          await SpotifySyncService.fullSync();
          
          setState(() { _isProcessing = false; _statusMessage = 'Connected successfully!'; });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) { context.go('/'); }
          return;
        }

        // No user logged in - check if email exists in database
        if (email != null) {
          setState(() { _statusMessage = 'Checking existing account...'; });
          final usersQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          
          if (usersQuery.docs.isNotEmpty) {
            // User exists but not logged in - redirect to login
            if (mounted) {
              EnhancedSnackbar.show(
                context,
                message: 'Account exists with this email. Please login.',
                type: SnackbarType.info,
              );
              context.go('/login');
            }
            return;
          }
        }

        // New user - create account with Spotify
        setState(() { _statusMessage = 'Creating account...'; });
        
        // Create anonymous Firebase account
        final cred = await FirebaseAuth.instance.signInAnonymously();
        final user = cred.user;
        
        if (user != null) {
          // Generate username
          String username = (displayName ?? 'user').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (username.isEmpty) username = 'user';
          
          // Check uniqueness
          final q = await FirebaseFirestore.instance.collection('users')
            .where('username', isEqualTo: username).limit(1).get();
          if (q.docs.isNotEmpty) {
            username = '${username}_${DateTime.now().millisecondsSinceEpoch % 10000}';
          }
          
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'username': username,
            'displayName': displayName ?? 'Tuniverse User',
            'photoURL': photoURL,
            'profileImageUrl': photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'provider': 'spotify',
            'spotifyConnected': true,
            'spotifyId': spotifyId,
            'isActive': true,
            'onboardingCompleted': false,
          });
          
          setState(() { _statusMessage = 'Syncing Spotify data...'; });
          await SpotifySyncService.fullSync();
          
          setState(() { _isProcessing = false; _statusMessage = 'Connected successfully!'; });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) { context.go('/'); }
        }
      } else {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _statusMessage = 'Failed to connect to Spotify';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.lightBackground.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: _hasError
                          ? LinearGradient(
                              colors: [
                                ModernDesignSystem.error,
                                ModernDesignSystem.error.withValues(alpha: 0.7),
                              ],
                            )
                          : ModernDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXXL),
                      boxShadow: [
                        BoxShadow(
                          color: (_hasError
                                  ? ModernDesignSystem.error
                                  : ModernDesignSystem.primaryGreen)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _hasError
                          ? Icons.error_outline
                          : _isProcessing
                              ? Icons.music_note
                              : Icons.check_circle_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: ModernDesignSystem.spacingXXL),

                  // Loading indicator
                  if (_isProcessing)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ModernDesignSystem.primaryGreen,
                      ),
                    ),

                  const SizedBox(height: ModernDesignSystem.spacingXL),

                  // Status message
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? ModernDesignSystem.textOnDark
                          : ModernDesignSystem.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

        if (_hasError) ...[
                    const SizedBox(height: ModernDesignSystem.spacingXXL),
                    EnhancedButton(
                      text: 'Go Back',
                      type: ButtonType.primary,
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
