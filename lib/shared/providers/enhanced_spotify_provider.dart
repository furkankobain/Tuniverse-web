import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_spotify_service.dart';

// Enhanced Spotify connection provider
final enhancedSpotifyProvider = StateNotifierProvider<EnhancedSpotifyNotifier, EnhancedSpotifyState>((ref) {
  return EnhancedSpotifyNotifier();
});

// Enhanced Spotify state
class EnhancedSpotifyState {
  final bool isConnected;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? currentTrack;
  final bool isPlaying;
  final int currentPosition;
  final int trackDuration;
  final double playbackProgress;
  final List<Map<String, dynamic>> topTracks;
  final List<Map<String, dynamic>> recentlyPlayed;
  final List<Map<String, dynamic>> recommendations;

  const EnhancedSpotifyState({
    this.isConnected = false,
    this.isLoading = false,
    this.error,
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = 0,
    this.trackDuration = 0,
    this.playbackProgress = 0.0,
    this.topTracks = const [],
    this.recentlyPlayed = const [],
    this.recommendations = const [],
  });

  EnhancedSpotifyState copyWith({
    bool? isConnected,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? currentTrack,
    bool? isPlaying,
    int? currentPosition,
    int? trackDuration,
    double? playbackProgress,
    List<Map<String, dynamic>>? topTracks,
    List<Map<String, dynamic>>? recentlyPlayed,
    List<Map<String, dynamic>>? recommendations,
  }) {
    return EnhancedSpotifyState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      trackDuration: trackDuration ?? this.trackDuration,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      topTracks: topTracks ?? this.topTracks,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

// Enhanced Spotify notifier
class EnhancedSpotifyNotifier extends StateNotifier<EnhancedSpotifyState> {
  EnhancedSpotifyNotifier() : super(const EnhancedSpotifyState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadConnectionState();
    await loadCurrentTrack();
    _startPeriodicUpdates();
  }

  Future<void> loadConnectionState() async {
    await EnhancedSpotifyService.loadConnectionState();
    state = state.copyWith(
      isConnected: EnhancedSpotifyService.isConnected,
    );
  }

  Future<void> loadCurrentTrack() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final track = await EnhancedSpotifyService.getCurrentTrack();
      final isPlaying = EnhancedSpotifyService.isPlaying;
      final currentPosition = EnhancedSpotifyService.currentPosition;
      final trackDuration = EnhancedSpotifyService.trackDuration;
      final playbackProgress = EnhancedSpotifyService.playbackProgress;

      state = state.copyWith(
        currentTrack: track,
        isPlaying: isPlaying,
        currentPosition: currentPosition,
        trackDuration: trackDuration,
        playbackProgress: playbackProgress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> authenticate() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await EnhancedSpotifyService.authenticate();
      
      state = state.copyWith(
        isConnected: success,
        isLoading: false,
        error: success ? null : 'Kimlik doğrulama başarısız',
      );

      if (success) {
        await loadCurrentTrack();
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> togglePlayPause() async {
    try {
      await EnhancedSpotifyService.togglePlayPause();
      await loadCurrentTrack();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> skipToNext() async {
    try {
      await EnhancedSpotifyService.skipToNext();
      await loadCurrentTrack();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> skipToPrevious() async {
    try {
      await EnhancedSpotifyService.skipToPrevious();
      await loadCurrentTrack();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> seekTo(int positionMs) async {
    try {
      await EnhancedSpotifyService.seekTo(positionMs);
      await loadCurrentTrack();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadTopTracks({String timeRange = 'medium_term', int limit = 20}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final tracks = await EnhancedSpotifyService.getTopTracks(
        timeRange: timeRange,
        limit: limit,
      );

      state = state.copyWith(
        topTracks: tracks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadRecentlyPlayed({int limit = 20}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final tracks = await EnhancedSpotifyService.getRecentlyPlayed(limit: limit);

      state = state.copyWith(
        recentlyPlayed: tracks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadRecommendations({String? seedTrackId, int limit = 10}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final tracks = await EnhancedSpotifyService.getTrackRecommendations(
        seedTrackId: seedTrackId,
        limit: limit,
      );

      state = state.copyWith(
        recommendations: tracks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> saveTrack(String trackId) async {
    try {
      final success = await EnhancedSpotifyService.saveTrack(trackId);
      if (!success) {
        state = state.copyWith(error: 'Şarkı kaydedilemedi');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTrack(String trackId) async {
    try {
      final success = await EnhancedSpotifyService.removeTrack(trackId);
      if (!success) {
        state = state.copyWith(error: 'Şarkı kaldırılamadı');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> disconnect() async {
    try {
      await EnhancedSpotifyService.disconnect();
      state = state.copyWith(
        isConnected: false,
        currentTrack: null,
        isPlaying: false,
        currentPosition: 0,
        trackDuration: 0,
        playbackProgress: 0.0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _startPeriodicUpdates() {
    // Update every 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (state.isConnected) {
        loadCurrentTrack();
      }
      _startPeriodicUpdates();
    });
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
  
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }
}

// Smart notification provider
final smartNotificationProvider = StateNotifierProvider<SmartNotificationNotifier, SmartNotificationState>((ref) {
  return SmartNotificationNotifier();
});

// Smart notification state
class SmartNotificationState {
  final bool isEnabled;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> analytics;
  final List<String> recentNotifications;

  const SmartNotificationState({
    this.isEnabled = true,
    this.isLoading = false,
    this.error,
    this.analytics = const {},
    this.recentNotifications = const [],
  });

  SmartNotificationState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? analytics,
    List<String>? recentNotifications,
  }) {
    return SmartNotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      analytics: analytics ?? this.analytics,
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }
}

// Smart notification notifier
class SmartNotificationNotifier extends StateNotifier<SmartNotificationState> {
  SmartNotificationNotifier() : super(const SmartNotificationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadAnalytics();
  }

  Future<void> enableNotifications() async {
    try {
      state = state.copyWith(isLoading: true);
      // Enable smart notifications logic
      state = state.copyWith(
        isEnabled: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> disableNotifications() async {
    try {
      state = state.copyWith(isLoading: true);
      // Disable smart notifications logic
      state = state.copyWith(
        isEnabled: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadAnalytics() async {
    try {
      // Load notification analytics
      // This would be implemented with SmartNotificationService
      state = state.copyWith(
        analytics: {
          'totalNotifications': 45,
          'openedNotifications': 32,
          'clickThroughRate': 0.71,
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendTestNotification() async {
    try {
      // Send a test notification
      // This would be implemented with SmartNotificationService
      final newNotifications = List<String>.from(state.recentNotifications);
      newNotifications.insert(0, 'Test bildirimi - ${DateTime.now()}');
      
      state = state.copyWith(
        recentNotifications: newNotifications.take(10).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
