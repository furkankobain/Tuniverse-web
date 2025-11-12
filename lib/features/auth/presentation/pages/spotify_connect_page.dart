import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:url_launcher/url_launcher.dart'; // Unused import

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/enhanced_spotify_provider.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';

class SpotifyConnectPage extends ConsumerStatefulWidget {
  const SpotifyConnectPage({super.key});

  @override
  ConsumerState<SpotifyConnectPage> createState() => _SpotifyConnectPageState();
}

class _SpotifyConnectPageState extends ConsumerState<SpotifyConnectPage> {
  @override
  void initState() {
    super.initState();
    _checkSpotifyAuth();
  }

  Future<void> _checkSpotifyAuth() async {
    await EnhancedSpotifyService.loadConnectionState();
    if (EnhancedSpotifyService.isConnected && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = ref.watch(enhancedSpotifyProvider);
    final isLoading = spotifyState.isLoading;
    final error = spotifyState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Spotify'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spotify Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Connect Your Spotify',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Connect your Spotify account to sync your music history, discover new tracks, and rate your favorite songs.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Features List
                _buildFeaturesList(),
                
                const SizedBox(height: 48),
                
                // Error Message
                if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Connect Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _connectSpotify,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.music_note, size: 24),
                    label: Text(
                      isLoading ? 'Connecting...' : 'Connect Spotify',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Skip Button
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Terms Text
                Text(
                  'By connecting Spotify, you agree to share your music data with MusicShare for a personalized experience.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Sync your listening history',
      'Rate songs and albums',
      'Discover new music',
      'Track your music journey',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Future<void> _connectSpotify() async {
    try {
      // Start loading
      ref.read(enhancedSpotifyProvider.notifier).setLoading(true);
      ref.read(enhancedSpotifyProvider.notifier).clearError();

      // Start Spotify OAuth flow
      final success = await EnhancedSpotifyService.authenticate();
      
      if (success) {
        // Show success message
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Spotify yetkilendirmesi başlatıldı. Lütfen tarayıcıda işlemi tamamlayın.',
            type: SnackbarType.info,
          );
        }
        
        // Note: The actual token exchange will be handled by the deep link callback
        // Close this page after launching browser
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ref.read(enhancedSpotifyProvider.notifier).setError(
          'Spotify bağlantısı başlatılamadı. Lütfen tekrar deneyin.'
        );
      }
    } catch (e) {
      ref.read(enhancedSpotifyProvider.notifier).setError(
        'Bir hata oluştu: ${e.toString()}'
      );
    } finally {
      ref.read(enhancedSpotifyProvider.notifier).setLoading(false);
    }
  }
}
