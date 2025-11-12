import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/music_player_service.dart';
import '../../services/haptic_service.dart';
import '../../../core/theme/modern_design_system.dart';
import '../../../features/player/presentation/pages/now_playing_animation_page.dart';
import 'package:audioplayers/audioplayers.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _hasTrack = false;
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Listen to player state changes
    MusicPlayerService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _hasTrack = MusicPlayerService.currentTrackId != null;
          
          if (_hasTrack) {
            _slideController.forward();
          } else {
            _slideController.reverse();
          }
        });
      }
    });

    // Listen to position changes for progress
    MusicPlayerService.positionStream.listen((position) {
      if (mounted && MusicPlayerService.totalDuration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / MusicPlayerService.totalDuration.inMilliseconds;
        });
      }
    });
    
    // Check initial state
    _hasTrack = MusicPlayerService.currentTrackId != null;
    _isPlaying = MusicPlayerService.isPlaying;
    if (_hasTrack) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasTrack) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackName = MusicPlayerService.currentTrackName ?? 'Unknown Track';
    final artistName = MusicPlayerService.currentArtistName ?? 'Unknown Artist';
    final imageUrl = MusicPlayerService.currentImageUrl;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Detect swipe up gesture
          if (details.primaryDelta! < -5) {
            // Navigate to Now Playing page
            if (MusicPlayerService.currentTrackId != null) {
              final track = {
                'id': MusicPlayerService.currentTrackId,
                'name': trackName,
                'artists': [{'name': artistName}],
                'album': {'images': imageUrl != null ? [{'url': imageUrl}] : []},
              };
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NowPlayingAnimationPage(track: track),
                ),
              );
            }
          }
        },
        onTap: () {
          // Tap to open Now Playing
          if (MusicPlayerService.currentTrackId != null) {
            context.push('/queue');
          }
        },
        child: Container(
          height: 70,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? ModernDesignSystem.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5E5E)),
              ),
            ),
            // Player content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Album art
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null
                          ? const Icon(Icons.music_note, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            trackName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                artistName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5E5E).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '30s Preview',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFF5E5E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFFFF5E5E),
                        size: 28,
                      ),
                      onPressed: () async {
                        HapticService.lightImpact();
                        if (_isPlaying) {
                          await MusicPlayerService.pause();
                        } else {
                          await MusicPlayerService.resume();
                        }
                      },
                    ),
                    // Close button
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () async {
                        HapticService.lightImpact();
                        await MusicPlayerService.stop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
