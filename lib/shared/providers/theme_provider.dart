import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// AMOLED theme provider
final amoledModeProvider = StateNotifierProvider<AmoledModeNotifier, bool>((ref) {
  return AmoledModeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 1; // Default to dark (index 1)
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setTheme(ThemeMode.dark);
    } else {
      setTheme(ThemeMode.light);
    }
  }

  bool get isDarkMode => state == ThemeMode.dark;
  bool get isLightMode => state == ThemeMode.light;
  bool get isSystemMode => state == ThemeMode.system;
}

class AmoledModeNotifier extends StateNotifier<bool> {
  AmoledModeNotifier() : super(false) {
    _loadAmoledMode();
  }

  static const String _amoledKey = 'amoled_mode';

  Future<void> _loadAmoledMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_amoledKey) ?? false;
  }

  Future<void> setAmoledMode(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, enabled);
  }

  void toggleAmoledMode() {
    setAmoledMode(!state);
  }
}

// Theme colors provider
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final themeMode = ref.watch(themeProvider);
  return ThemeColors(themeMode);
});

class ThemeColors {
  final ThemeMode themeMode;
  
  ThemeColors(this.themeMode);

  bool get isDark => themeMode == ThemeMode.dark;
  
  Color get primaryColor => const Color(0xFF1DB954); // Spotify Green
  Color get secondaryColor => const Color(0xFF1ED760);
  Color get accentColor => const Color(0xFFFF6B6B);
  
  Color get backgroundColor => isDark 
      ? const Color(0xFF121212) 
      : const Color(0xFFFAFAFA);
  
  Color get surfaceColor => isDark 
      ? const Color(0xFF1E1E1E) 
      : Colors.white;
  
  Color get cardColor => isDark 
      ? const Color(0xFF2A2A2A) 
      : Colors.white;
  
  Color get textPrimary => isDark 
      ? Colors.white 
      : const Color(0xFF212121);
  
  Color get textSecondary => isDark 
      ? const Color(0xFFB3B3B3) 
      : const Color(0xFF757575);
  
  Color get dividerColor => isDark 
      ? const Color(0xFF404040) 
      : const Color(0xFFE0E0E0);
  
  Color get errorColor => const Color(0xFFFF5252);
  Color get successColor => const Color(0xFF4CAF50);
  Color get warningColor => const Color(0xFFFF9800);
  
  // Gradient colors
  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  LinearGradient get backgroundGradient => LinearGradient(
    colors: isDark 
        ? [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)]
        : [const Color(0xFFF5F5F5), const Color(0xFFE8E8E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shadow colors
  Color get shadowColor => isDark 
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);
}

// Animation provider
final animationProvider = StateNotifierProvider<AnimationNotifier, AnimationState>((ref) {
  return AnimationNotifier();
});

class AnimationNotifier extends StateNotifier<AnimationState> {
  AnimationNotifier() : super(const AnimationState());

  void enableAnimations() {
    state = state.copyWith(animationsEnabled: true);
  }

  void disableAnimations() {
    state = state.copyWith(animationsEnabled: false);
  }

  void setAnimationDuration(Duration duration) {
    state = state.copyWith(animationDuration: duration);
  }
}

class AnimationState {
  final bool animationsEnabled;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimationState({
    this.animationsEnabled = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  AnimationState copyWith({
    bool? animationsEnabled,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return AnimationState(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}

// Accessibility provider
final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, AccessibilityState>((ref) {
  return AccessibilityNotifier();
});

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  AccessibilityNotifier() : super(const AccessibilityState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      highContrast: prefs.getBool('high_contrast') ?? false,
      largeText: prefs.getBool('large_text') ?? false,
      reducedMotion: prefs.getBool('reduced_motion') ?? false,
      screenReader: prefs.getBool('screen_reader') ?? false,
    );
  }

  Future<void> setHighContrast(bool enabled) async {
    state = state.copyWith(highContrast: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', enabled);
  }

  Future<void> setLargeText(bool enabled) async {
    state = state.copyWith(largeText: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('large_text', enabled);
  }

  Future<void> setReducedMotion(bool enabled) async {
    state = state.copyWith(reducedMotion: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduced_motion', enabled);
  }

  Future<void> setScreenReader(bool enabled) async {
    state = state.copyWith(screenReader: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screen_reader', enabled);
  }
}

class AccessibilityState {
  final bool highContrast;
  final bool largeText;
  final bool reducedMotion;
  final bool screenReader;

  const AccessibilityState({
    this.highContrast = false,
    this.largeText = false,
    this.reducedMotion = false,
    this.screenReader = false,
  });

  AccessibilityState copyWith({
    bool? highContrast,
    bool? largeText,
    bool? reducedMotion,
    bool? screenReader,
  }) {
    return AccessibilityState(
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      screenReader: screenReader ?? this.screenReader,
    );
  }
}
