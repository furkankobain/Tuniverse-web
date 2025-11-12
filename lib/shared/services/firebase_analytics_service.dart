import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics tracking servisi
/// Kullanıcı davranışlarını track eder (Google Analytics)
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => 
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Analytics'i başlat
  static Future<void> initialize() async {
    // Debug modda analytics'i devre dışı bırak (opsiyonel)
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    
    if (kDebugMode) {
      print('📊 Firebase Analytics initialized');
    }
  }

  /// Kullanıcı bilgilerini ayarla
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    if (kDebugMode) {
      print('📊 User ID set: $userId');
    }
  }

  /// Kullanıcı özelliği ayarla
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Ekran görüntüleme logla
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
    
    if (kDebugMode) {
      print('📊 Screen: $screenName');
    }
  }

  /// Genel event logla
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
    );
    
    if (kDebugMode) {
      print('📊 Event: $name');
    }
  }

  // === AUTH EVENTS ===

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // === SEARCH & DISCOVERY ===

  static Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  static Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method ?? 'unknown',
    );
  }

  // === MUSIC EVENTS ===

  static Future<void> logTrackPlay(String trackId, String trackName) async {
    await logEvent(
      name: 'track_play',
      parameters: {
        'track_id': trackId,
        'track_name': trackName,
      },
    );
  }

  static Future<void> logPlaylistCreate(String playlistName) async {
    await logEvent(
      name: 'playlist_create',
      parameters: {'playlist_name': playlistName},
    );
  }

  static Future<void> logReviewSubmit(double rating) async {
    await logEvent(
      name: 'review_submit',
      parameters: {'rating': rating},
    );
  }

  static Future<void> logFollowUser() async {
    await logEvent(name: 'follow_user');
  }

  static Future<void> logMessageSend() async {
    await logEvent(name: 'message_send');
  }

  static Future<void> logSpotifyConnect() async {
    await logEvent(name: 'spotify_connect');
  }
}
