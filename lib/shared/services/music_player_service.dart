import 'package:audioplayers/audioplayers.dart';

class MusicPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? _currentTrackId;
  static String? _currentTrackName;
  static String? _currentArtistName;
  static String? _currentImageUrl;
  static bool _isPlaying = false;
  static Duration _currentPosition = Duration.zero;
  static Duration _totalDuration = Duration.zero;

  // Stream controllers for reactive updates
  static Stream<PlayerState> get playerStateStream => _audioPlayer.onPlayerStateChanged;
  static Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  static Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // Getters
  static bool get isPlaying => _isPlaying;
  static String? get currentTrackId => _currentTrackId;
  static String? get currentTrackName => _currentTrackName;
  static String? get currentArtistName => _currentArtistName;
  static String? get currentImageUrl => _currentImageUrl;
  static Duration get currentPosition => _currentPosition;
  static Duration get totalDuration => _totalDuration;
  static double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  static Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
  }

  /// Play a track preview
  static Future<void> playTrack({
    required String trackId,
    required String previewUrl,
    required String trackName,
    required String artistName,
    String? imageUrl,
  }) async {
    try {
      print('🎵 Attempting to play track: $trackName');
      print('   Preview URL: $previewUrl');
      print('   Track ID: $trackId');
      
      // If same track, toggle play/pause
      if (_currentTrackId == trackId && _isPlaying) {
        print('⏸️ Pausing current track');
        await pause();
        return;
      } else if (_currentTrackId == trackId && !_isPlaying) {
        print('▶️ Resuming current track');
        await resume();
        return;
      }

      // Stop current track if playing
      if (_isPlaying) {
        print('⏹️ Stopping previous track');
        await stop();
      }

      // Update current track info
      _currentTrackId = trackId;
      _currentTrackName = trackName;
      _currentArtistName = artistName;
      _currentImageUrl = imageUrl;

      // Play the preview
      print('🎧 Playing preview from URL...');
      await _audioPlayer.play(UrlSource(previewUrl));
      _isPlaying = true;
      print('✅ Track playback started successfully');
    } catch (e, stackTrace) {
      print('❌ Error playing track: $e');
      print('Stack trace: $stackTrace');
      _isPlaying = false;
      rethrow; // Re-throw to let UI handle it
    }
  }

  /// Pause playback
  static Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  /// Resume playback
  static Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      print('Error resuming: $e');
    }
  }

  /// Stop playback
  static Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentPosition = Duration.zero;
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  /// Seek to position
  static Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Clear current track
  static Future<void> clear() async {
    await stop();
    _currentTrackId = null;
    _currentTrackName = null;
    _currentArtistName = null;
    _currentImageUrl = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
