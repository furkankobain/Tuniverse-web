// Web stub
class CrashlyticsService {
  static Future<void> initialize() async {}
  static Future<void> recordError(dynamic exception, StackTrace? stack) async {}
  static Future<void> log(String message) async {}
  static void testCrash() {}
  static Future<void> logError(String message, {StackTrace? stackTrace, String? reason}) async {}
  static Future<void> setCustomKey(String key, dynamic value) async {}
}
