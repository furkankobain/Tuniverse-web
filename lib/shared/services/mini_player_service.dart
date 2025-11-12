import 'package:flutter/foundation.dart';

class MiniPlayerService extends ChangeNotifier {
  static final MiniPlayerService _instance = MiniPlayerService._internal();
  factory MiniPlayerService() => _instance;
  MiniPlayerService._internal();

  Map<String, dynamic>? _currentTrack;
  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  Map<String, dynamic>? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  double get progress => _progress;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get hasTrack => _currentTrack != null;

  void playTrack(Map<String, dynamic> track) {
    _currentTrack = track;
    _isPlaying = true;
    _progress = 0.0;
    _currentPosition = Duration.zero;
    
    // Get duration from track if available
    final durationMs = track['duration_ms'];
    if (durationMs != null) {
      _totalDuration = Duration(milliseconds: durationMs);
    } else {
      _totalDuration = const Duration(minutes: 3); // Default
    }
    
    notifyListeners();
    _simulatePlayback();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    _isPlaying = true;
    notifyListeners();
    _simulatePlayback();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  void seekTo(double progress) {
    _progress = progress;
    _currentPosition = Duration(
      milliseconds: (_totalDuration.inMilliseconds * progress).round(),
    );
    notifyListeners();
  }

  void stop() {
    _currentTrack = null;
    _isPlaying = false;
    _progress = 0.0;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  // Simulate playback progress
  void _simulatePlayback() async {
    while (_isPlaying && _progress < 1.0) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isPlaying) {
        _currentPosition = _currentPosition + const Duration(seconds: 1);
        _progress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isPlaying = false;
        }
        notifyListeners();
      }
    }
  }

  String getFormattedPosition() {
    final minutes = _currentPosition.inMinutes;
    final seconds = _currentPosition.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getFormattedDuration() {
    final minutes = _totalDuration.inMinutes;
    final seconds = _totalDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
