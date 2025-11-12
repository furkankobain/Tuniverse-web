import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'modern_design_system.dart';

class EnhancedTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'SFPro',
      colorScheme: ColorScheme.fromSeed(
        seedColor: ModernDesignSystem.primaryGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: ModernDesignSystem.lightBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF212121),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212121),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212121),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF212121),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF212121),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF757575),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1DB954),
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SFPro',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1DB954),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB3B3B3),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFFB3B3B3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFF1DB954),
        unselectedItemColor: Color(0xFFB3B3B3),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
}

// Custom theme extensions
@immutable
class MusicSpaceTheme extends ThemeExtension<MusicSpaceTheme> {
  const MusicSpaceTheme({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.successGradient,
    required this.warningGradient,
    required this.errorGradient,
    required this.spotifyGreen,
    required this.spotifyDark,
    required this.spotifyLight,
  });

  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient successGradient;
  final LinearGradient warningGradient;
  final LinearGradient errorGradient;
  final Color spotifyGreen;
  final Color spotifyDark;
  final Color spotifyLight;

  static const MusicSpaceTheme light = MusicSpaceTheme(
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    successGradient: LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    warningGradient: LinearGradient(
      colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    errorGradient: LinearGradient(
      colors: [Color(0xFFFF5252), Color(0xFFFF7043)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    spotifyGreen: Color(0xFF1DB954),
    spotifyDark: Color(0xFF191414),
    spotifyLight: Color(0xFFF5F5F5),
  );

  static const MusicSpaceTheme dark = MusicSpaceTheme(
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    successGradient: LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    warningGradient: LinearGradient(
      colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    errorGradient: LinearGradient(
      colors: [Color(0xFFFF5252), Color(0xFFFF7043)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    spotifyGreen: Color(0xFF1DB954),
    spotifyDark: Color(0xFF121212),
    spotifyLight: Color(0xFF1E1E1E),
  );

  @override
  MusicSpaceTheme copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
    LinearGradient? successGradient,
    LinearGradient? warningGradient,
    LinearGradient? errorGradient,
    Color? spotifyGreen,
    Color? spotifyDark,
    Color? spotifyLight,
  }) {
    return MusicSpaceTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      successGradient: successGradient ?? this.successGradient,
      warningGradient: warningGradient ?? this.warningGradient,
      errorGradient: errorGradient ?? this.errorGradient,
      spotifyGreen: spotifyGreen ?? this.spotifyGreen,
      spotifyDark: spotifyDark ?? this.spotifyDark,
      spotifyLight: spotifyLight ?? this.spotifyLight,
    );
  }

  @override
  MusicSpaceTheme lerp(ThemeExtension<MusicSpaceTheme>? other, double t) {
    if (other is! MusicSpaceTheme) {
      return this;
    }
    return MusicSpaceTheme(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ?? primaryGradient,
      secondaryGradient: LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t) ?? secondaryGradient,
      successGradient: LinearGradient.lerp(successGradient, other.successGradient, t) ?? successGradient,
      warningGradient: LinearGradient.lerp(warningGradient, other.warningGradient, t) ?? warningGradient,
      errorGradient: LinearGradient.lerp(errorGradient, other.errorGradient, t) ?? errorGradient,
      spotifyGreen: Color.lerp(spotifyGreen, other.spotifyGreen, t) ?? spotifyGreen,
      spotifyDark: Color.lerp(spotifyDark, other.spotifyDark, t) ?? spotifyDark,
      spotifyLight: Color.lerp(spotifyLight, other.spotifyLight, t) ?? spotifyLight,
    );
  }
}
