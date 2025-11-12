import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/music_player_service.dart';
import '../../core/theme/modern_design_system.dart';

class MiniMusicPlayer extends StatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _trackName;
  String? _artistName;
  String? _imageUrl;
  double _volume = 1.0;
  bool _showVolumeSlider = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _updateState();
  }

  void _setupListeners() {
    MusicPlayerService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    MusicPlayerService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    MusicPlayerService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  void _updateState() {
    setState(() {
      _isPlaying = MusicPlayerService.isPlaying;
      _currentPosition = MusicPlayerService.currentPosition;
      _totalDuration = MusicPlayerService.totalDuration;
      _trackName = MusicPlayerService.currentTrackName;
      _artistName = MusicPlayerService.currentArtistName;
      _imageUrl = MusicPlayerService.currentImageUrl;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Don't show player if no track is loaded
    if (_trackName == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: _totalDuration.inMilliseconds > 0
                ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                : 0,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(ModernDesignSystem.primaryGreen),
            minHeight: 3,
          ),

          // Player Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(Icons.music_note),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Icon(Icons.music_note),
                        ),
                ),

                const SizedBox(width: 12),

                // Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _trackName ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _artistName ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Time Display
                Text(
                  '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),

                const SizedBox(width: 12),

                // Volume Control
                IconButton(
                  icon: Icon(
                    _volume > 0.5
                        ? Icons.volume_up
                        : _volume > 0
                            ? Icons.volume_down
                            : Icons.volume_off,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    setState(() {
                      _showVolumeSlider = !_showVolumeSlider;
                    });
                  },
                ),

                // Play/Pause Button
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 40,
                    color: ModernDesignSystem.primaryGreen,
                  ),
                  onPressed: () async {
                    if (_isPlaying) {
                      await MusicPlayerService.pause();
                    } else {
                      await MusicPlayerService.resume();
                    }
                  },
                ),

                // Close Button
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () async {
                    await MusicPlayerService.clear();
                    setState(() {
                      _trackName = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // Volume Slider (shown when volume button is pressed)
          if (_showVolumeSlider)
            Padding(
              padding: const EdgeInsets.only(left: 78, right: 16, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_down,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                        });
                        MusicPlayerService.setVolume(value);
                      },
                      activeColor: ModernDesignSystem.primaryGreen,
                    ),
                  ),
                  Icon(
                    Icons.volume_up,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
