import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification enabled state
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

// Notification settings provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettings {
  final bool musicRecommendations;
  final bool newReleases;
  final bool trendingTracks;
  final bool ratingReminders;
  final bool weeklyDigest;

  const NotificationSettings({
    this.musicRecommendations = true,
    this.newReleases = true,
    this.trendingTracks = true,
    this.ratingReminders = true,
    this.weeklyDigest = true,
  });

  NotificationSettings copyWith({
    bool? musicRecommendations,
    bool? newReleases,
    bool? trendingTracks,
    bool? ratingReminders,
    bool? weeklyDigest,
  }) {
    return NotificationSettings(
      musicRecommendations: musicRecommendations ?? this.musicRecommendations,
      newReleases: newReleases ?? this.newReleases,
      trendingTracks: trendingTracks ?? this.trendingTracks,
      ratingReminders: ratingReminders ?? this.ratingReminders,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void toggleMusicRecommendations() {
    state = state.copyWith(musicRecommendations: !state.musicRecommendations);
  }

  void toggleNewReleases() {
    state = state.copyWith(newReleases: !state.newReleases);
  }

  void toggleTrendingTracks() {
    state = state.copyWith(trendingTracks: !state.trendingTracks);
  }

  void toggleRatingReminders() {
    state = state.copyWith(ratingReminders: !state.ratingReminders);
  }

  void toggleWeeklyDigest() {
    state = state.copyWith(weeklyDigest: !state.weeklyDigest);
  }
}

// Mock notification data provider
final mockNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));
  
  return [
    {
      'id': '1',
      'title': 'Yeni Müzik Önerisi 🎵',
      'body': 'Anti-Hero - Taylor Swift',
      'type': 'music_recommendation',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': false,
      'image': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
    },
    {
      'id': '2',
      'title': 'Yeni Albüm Çıktı! 🎤',
      'body': 'Midnights - Taylor Swift',
      'type': 'new_release',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'read': true,
      'image': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
    },
    {
      'id': '3',
      'title': 'Trend Şarkı 🔥',
      'body': 'As It Was - Harry Styles',
      'type': 'trending_track',
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'read': false,
      'image': 'https://i.scdn.co/image/ab67616d0000b273f7b7174bef6f3fbfda3a0bb7',
    },
    {
      'id': '4',
      'title': 'Şarkıyı Puanlamayı Unutmayın ⭐',
      'body': 'Heat Waves - Glass Animals',
      'type': 'rating_reminder',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
      'image': 'https://i.scdn.co/image/ab67616d0000b2737c05b5e35713c6643bb9a7c0',
    },
    {
      'id': '5',
      'title': 'Haftalık Özet 📊',
      'body': 'Bu hafta 15 şarkı dinlediniz',
      'type': 'weekly_digest',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'read': false,
      'image': null,
    },
  ];
});
