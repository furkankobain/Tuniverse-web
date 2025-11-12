import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/services/notification_service.dart';

// Language state notifier
class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier() : super(null) {
    _loadLanguage();
  }

  static const String _languageKey = 'app_language';

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    state = Locale(languageCode, '');
    print('🌍 Loaded language: $languageCode');
  }

  Future<void> setLanguage(String languageCode) async {
    print('🌍 Setting language to: $languageCode');
    state = Locale(languageCode, '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Update notification language
    await NotificationService.updateLanguage(languageCode);
    
    print('✅ Language saved: $languageCode');
  }

  Future<void> toggleLanguage() async {
    final currentLanguage = state?.languageCode ?? 'en';
    final newLanguage = currentLanguage == 'en' ? 'tr' : 'en';
    await setLanguage(newLanguage);
  }
}

// Provider
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  return LanguageNotifier();
});
