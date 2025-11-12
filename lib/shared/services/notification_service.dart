// Web stub - notifications not supported on web
class NotificationService {
  static Future<void> initialize() async {}
  static Future<void> showNotification({required String title, required String body}) async {}
  static Future<void> updateLanguage(String languageCode) async {}
  static Future<void> showMusicRecommendation({String? title, String? body, String? trackName, String? artistName}) async {}
  static Future<void> showNewRelease({String? title, String? body, String? albumName, String? artistName}) async {}
  static Future<void> showTrendingTrack({String? title, String? body, String? trackName, String? artistName}) async {}
  static Future<void> showRatingReminder({String? trackName, String? artistName}) async {}
  static Future<void> clearAllNotifications() async {}
}
