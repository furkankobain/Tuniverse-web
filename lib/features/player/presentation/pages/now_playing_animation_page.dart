import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/animations/app_animations.dart';

/// Now Playing Animation Page
/// Full-screen music player with visual animations and album color themes
class NowPlayingAnimationPage extends StatefulWidget {
  final Map<String, dynamic> track;

  const NowPlayingAnimationPage({
    super.key,
    required this.track,
  });

  @override
  State<NowPlayingAnimationPage> createState() => _NowPlayingAnimationPageState();
}

class _NowPlayingAnimationPageState extends State<NowPlayingAnimationPage>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _rotateController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 30.0; // 30 seconds preview
  VisualizerType _visualizerType = VisualizerType.wave;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Auto-play the preview
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    final previewUrl = widget.track['previewUrl'] as String?;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      try {
        await _audioPlayer.play(UrlSource(previewUrl));
        setState(() => _isPlaying = true);
        
        // Listen to position
        _audioPlayer.onPositionChanged.listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position.inSeconds.toDouble();
            });
          }
        });
        
        // Listen to completion
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } catch (e) {
        print('Error playing: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color get _dominantColor {
    // Extract dominant color from album art
    // In production, use palette_generator package
    return const Color(0xFFFF5E5E);
  }

  List<Color> get _gradientColors {
    return [
      _dominantColor,
      _dominantColor.withOpacity(0.7),
      _dominantColor.withOpacity(0.4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildVisualizer(),
                    _buildAlbumArt(),
                    _buildTrackInfo(),
                    _buildProgressBar(),
                    _buildControls(),
                    _buildVisualizerSelector(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Şimdi Çalıyor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizer() {
    switch (_visualizerType) {
      case VisualizerType.wave:
        return _buildWaveVisualizer();
      case VisualizerType.bars:
        return _buildBarsVisualizer();
      case VisualizerType.circle:
        return _buildCircleVisualizer();
    }
  }

  Widget _buildWaveVisualizer() {
    return SizedBox(
      height: 120,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveVisualizerPainter(
              animation: _waveController.value,
              isPlaying: _isPlaying,
            ),
            size: Size(MediaQuery.of(context).size.width, 120),
          );
        },
      ),
    );
  }

  Widget _buildBarsVisualizer() {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          20,
          (index) => AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final height = _isPlaying
                  ? 20 +
                      60 *
                          math.sin((_waveController.value * 2 * math.pi) +
                              (index * 0.3))
                  : 20.0;
              return Container(
                width: 4,
                height: height.abs(),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCircleVisualizer() {
    return SizedBox(
      height: 200,
      width: 200,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: CircleVisualizerPainter(
              animation: _waveController.value,
              isPlaying: _isPlaying,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumArt() {
    return RotationTransition(
      turns: _isPlaying ? _rotateController : AlwaysStoppedAnimation(0),
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipOval(
          child: widget.track['albumArt'] != null
              ? Image.network(
                  widget.track['albumArt'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderArt(),
                )
              : _buildPlaceholderArt(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      color: _dominantColor.withOpacity(0.3),
      child: const Icon(
        Icons.music_note,
        size: 100,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            widget.track['name'] ?? 'Unknown Track',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            widget.track['artist'] ?? 'Unknown Artist',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
            ),
            child: Slider(
              value: _currentPosition,
              min: 0,
              max: _totalDuration,
              onChanged: (value) async {
                setState(() => _currentPosition = value);
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.white),
            iconSize: 28,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            iconSize: 40,
            onPressed: () {},
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: _dominantColor,
              ),
              iconSize: 36,
              onPressed: () async {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                  _waveController.stop();
                  _rotateController.stop();
                } else {
                  await _audioPlayer.resume();
                  _waveController.repeat();
                  _rotateController.repeat();
                }
                setState(() => _isPlaying = !_isPlaying);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            iconSize: 40,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.repeat, color: Colors.white),
            iconSize: 28,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildVisualizerButton(VisualizerType.wave, Icons.graphic_eq),
          const SizedBox(width: 16),
          _buildVisualizerButton(VisualizerType.bars, Icons.equalizer),
          const SizedBox(width: 16),
          _buildVisualizerButton(VisualizerType.circle, Icons.album),
        ],
      ),
    );
  }

  Widget _buildVisualizerButton(VisualizerType type, IconData icon) {
    final isSelected = _visualizerType == type;
    return InkWell(
      onTap: () => setState(() => _visualizerType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

enum VisualizerType { wave, bars, circle }

/// Wave Visualizer Painter
class WaveVisualizerPainter extends CustomPainter {
  final double animation;
  final bool isPlaying;

  WaveVisualizerPainter({required this.animation, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = isPlaying ? 40.0 : 5.0;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height / 2 +
          waveHeight *
              math.sin((x / size.width * 4 * math.pi) +
                  (animation * 2 * math.pi));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveVisualizerPainter oldDelegate) => true;
}

/// Circle Visualizer Painter
class CircleVisualizerPainter extends CustomPainter {
  final double animation;
  final bool isPlaying;

  CircleVisualizerPainter({required this.animation, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final bars = 30;

    for (int i = 0; i < bars; i++) {
      final angle = (i / bars) * 2 * math.pi;
      final barHeight = isPlaying
          ? 30 +
              20 *
                  math.sin((animation * 2 * math.pi) + (i * 0.2))
          : 30.0;

      final startRadius = 60.0;
      final endRadius = startRadius + barHeight.abs();

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );

      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(CircleVisualizerPainter oldDelegate) => true;
}
