import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../services/enhanced_spotify_service.dart';
import '../providers/enhanced_spotify_provider.dart';
import '../../features/music/presentation/pages/rate_music_page.dart';

class EnhancedSpotifyPlayerWidget extends ConsumerStatefulWidget {
  const EnhancedSpotifyPlayerWidget({super.key});

  @override
  ConsumerState<EnhancedSpotifyPlayerWidget> createState() => _EnhancedSpotifyPlayerWidgetState();
}

class _EnhancedSpotifyPlayerWidgetState extends ConsumerState<EnhancedSpotifyPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation if playing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnimations();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateAnimations() {
    final isPlaying = ref.read(enhancedSpotifyProvider).isPlaying;
    if (isPlaying) {
      _pulseController.repeat(reverse: true);
      _progressController.repeat();
    } else {
      _pulseController.stop();
      _progressController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = ref.watch(enhancedSpotifyProvider);
    final currentTrack = spotifyState.currentTrack;

    if (!spotifyState.isConnected) {
      return _buildConnectionCard();
    }

    if (currentTrack == null) {
      return _buildNoTrackCard();
    }

    return _buildPlayerCard(currentTrack, spotifyState);
  }

  Widget _buildConnectionCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.music_note,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Spotify\'a Bağlan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Müzik dinleme deneyimini geliştirmek için Spotify hesabınızı bağlayın',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/spotify-connect',
                  );
                  if (result == true) {
                    // Provider will auto-refresh
                  }
                },
                icon: const Icon(Icons.music_note),
                label: const Text('Spotify\'a Bağlan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTrackCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.music_note,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Spotify Bağlı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Şu anda çalan müzik yok',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> track, EnhancedSpotifyState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Track Info
              _buildTrackInfo(track),
              
              const SizedBox(height: 16),
              
              // Progress Bar
              _buildProgressBar(state),
              
              const SizedBox(height: 16),
              
              // Controls
              _buildControls(track, state),
              
              const SizedBox(height: 12),
              
              // Additional Actions
              _buildAdditionalActions(track),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(Map<String, dynamic> track) {
    return Row(
      children: [
        // Album Art with Animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                  child: track['image_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: track['image_url'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(width: 16),
        
        // Track Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track['name'] ?? 'Bilinmeyen Şarkı',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                track['artist'] ?? 'Bilinmeyen Sanatçı',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (track['album'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  track['album'],
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (track['popularity'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${track['popularity']}% Popülerlik',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(EnhancedSpotifyState state) {
    final progress = state.playbackProgress;
    
    return Column(
      children: [
        // Progress Bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: state.isPlaying ? _progressAnimation.value * progress : progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
              minHeight: 4,
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Time Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(state.currentPosition),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              _formatDuration(state.trackDuration),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls(Map<String, dynamic> track, EnhancedSpotifyState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous Button
        IconButton(
          onPressed: state.isConnected ? () async {
            await EnhancedSpotifyService.skipToPrevious();
            // Provider will auto-refresh
          } : null,
          icon: const Icon(Icons.skip_previous),
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        
        // Play/Pause Button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: state.isPlaying ? _pulseAnimation.value : 1.0,
              child: IconButton(
                onPressed: state.isConnected ? () async {
                  await EnhancedSpotifyService.togglePlayPause();
                  _updateAnimations();
                  // Provider will auto-refresh
                } : null,
                icon: Icon(
                  state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                ),
                iconSize: 48,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            );
          },
        ),
        
        // Next Button
        IconButton(
          onPressed: state.isConnected ? () async {
            await EnhancedSpotifyService.skipToNext();
            // Provider will auto-refresh
          } : null,
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalActions(Map<String, dynamic> track) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rate Button
        IconButton(
          onPressed: () => _openRateMusicPage(track),
          icon: const Icon(Icons.star_border),
          tooltip: 'Bu şarkıyı puanla',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
          ),
        ),
        
        // Save Button
        IconButton(
          onPressed: () => _saveTrack(track),
          icon: const Icon(Icons.favorite_border),
          tooltip: 'Kütüphaneye ekle',
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.1),
          ),
        ),
        
        // Share Button
        IconButton(
          onPressed: () => _shareTrack(track),
          icon: const Icon(Icons.share),
          tooltip: 'Paylaş',
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        
        // Info Button
        IconButton(
          onPressed: () => _showTrackInfo(track),
          icon: const Icon(Icons.info_outline),
          tooltip: 'Şarkı bilgileri',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _openRateMusicPage(Map<String, dynamic> track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateMusicPage(track: track),
      ),
    );
  }

  void _saveTrack(Map<String, dynamic> track) async {
    final trackId = track['id'] as String?;
    if (trackId == null) return;

    final success = await EnhancedSpotifyService.saveTrack(trackId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Şarkı kütüphaneye eklendi!' : 'Şarkı eklenemedi',
          ),
          backgroundColor: success ? AppTheme.primaryColor : AppTheme.errorColor,
        ),
      );
    }
  }

  void _shareTrack(Map<String, dynamic> track) {
    final trackName = track['name'] ?? 'Bilinmeyen Şarkı';
    final artistName = track['artist'] ?? 'Bilinmeyen Sanatçı';
    final shareText = 'Şu anda "$trackName - $artistName" dinliyorum! 🎵';
    
    // In a real app, you'd use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paylaşım metni: $shareText'),
        action: SnackBarAction(
          label: 'Kopyala',
          onPressed: () {
            // Copy to clipboard
          },
        ),
      ),
    );
  }

  void _showTrackInfo(Map<String, dynamic> track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şarkı Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şarkı: ${track['name'] ?? 'Bilinmeyen'}'),
            Text('Sanatçı: ${track['artist'] ?? 'Bilinmeyen'}'),
            Text('Albüm: ${track['album'] ?? 'Bilinmeyen'}'),
            if (track['popularity'] != null)
              Text('Popülerlik: ${track['popularity']}%'),
            if (track['duration_ms'] != null)
              Text('Süre: ${_formatDuration(track['duration_ms'])}'),
            if (track['features'] != null) ...[
              const SizedBox(height: 8),
              const Text('Audio Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ..._buildAudioFeatures(track['features']),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAudioFeatures(Map<String, dynamic> features) {
    return features.entries.map((entry) {
      final value = entry.value;
      final displayValue = value is double ? (value * 100).toStringAsFixed(0) : value.toString();
      return Text('${entry.key}: $displayValue%');
    }).toList();
  }
}
