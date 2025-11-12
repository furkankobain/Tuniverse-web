import 'package:flutter/material.dart';

class ModernDesignSystem {
  // Modern Color Palette - Enhanced
  static const Color primaryGreen = Color(0xFFFF5E5E);  // Changed to red
  static const Color secondaryGreen = Color(0xFFFF5E5E);  // Changed to red
  static const Color accentPurple = Color(0xFF9333EA);
  static const Color accentBlue = Color(0xFF0EA5E9);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentYellow = Color(0xFFFBBF24);
  
  // Logo Background Color
  static const Color logoBackground = Color(0xFF46484D);
  
  // Dark Theme Colors - More depth
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0F0F0F);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkElevated = Color(0xFF252525);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8F9FA);
  static const Color lightBorder = Color(0xFFE5E7EB);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnLight = Color(0xFF1F2937);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, secondaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accentPurple, Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [accentBlue, Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient modernGradient = LinearGradient(
    colors: [primaryGreen, accentTeal, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [accentOrange, accentPink, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [accentBlue, accentTeal, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Spacing System (8pt grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius System
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;
  
  // Elevation System
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Typography Scale
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 24.0;
  static const double fontSizeXXL = 32.0;
  static const double fontSizeXXXL = 48.0;
  
  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  
  // Button Heights
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 40.0;
  static const double buttonHeightL = 48.0;
  static const double buttonHeightXL = 56.0;
  
  // Card Heights
  static const double cardHeightS = 80.0;
  static const double cardHeightM = 120.0;
  static const double cardHeightL = 160.0;
  static const double cardHeightXL = 200.0;
  
  // Breakpoints for Responsive Design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  // Modern Shadows
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Glassmorphism Effect - Enhanced
  static BoxDecoration get glassmorphism => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, -2),
      ),
    ],
  );
  
  static BoxDecoration get darkGlassmorphism => BoxDecoration(
    color: Colors.black.withValues(alpha: 0.4),
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.08),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primaryGreen.withValues(alpha: 0.05),
        blurRadius: 32,
        offset: const Offset(0, 0),
      ),
    ],
  );
  
  // Neumorphism Effect
  static BoxDecoration neumorphismLight(BuildContext context) => BoxDecoration(
    color: lightBackground,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.8),
        blurRadius: 15,
        offset: const Offset(-8, -8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 15,
        offset: const Offset(8, 8),
      ),
    ],
  );
  
  static BoxDecoration neumorphismDark(BuildContext context) => BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.03),
        blurRadius: 15,
        offset: const Offset(-8, -8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 15,
        offset: const Offset(8, 8),
      ),
    ],
  );
  
  // Glow Effect
  static List<BoxShadow> getGlowEffect(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 30,
      offset: const Offset(0, 0),
    ),
    BoxShadow(
      color: color.withValues(alpha: intensity * 0.5),
      blurRadius: 60,
      offset: const Offset(0, 0),
    ),
  ];
  
  // Modern Card with Gradient Border
  static BoxDecoration modernCardWithGradient({
    required Gradient gradient,
    bool isDark = false,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(radiusL),
    gradient: LinearGradient(
      colors: [
        isDark ? darkCard : lightCard,
        isDark ? darkSurface : lightSurface,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Responsive Helper Methods
  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) => width >= mobileBreakpoint && width < tabletBreakpoint;
  static bool isDesktop(double width) => width >= desktopBreakpoint;
  
  static double getResponsiveSpacing(double width) {
    if (isMobile(width)) return spacingS;
    if (isTablet(width)) return spacingM;
    return spacingL;
  }
  
  static double getResponsivePadding(double width) {
    if (isMobile(width)) return spacingM;
    if (isTablet(width)) return spacingL;
    return spacingXL;
  }
  
  static int getResponsiveColumns(double width) {
    if (isMobile(width)) return 2;
    if (isTablet(width)) return 3;
    return 4;
  }
  
  // Modern Button Styles
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: elevationS,
      shadowColor: primaryGreen.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
    );
  }
  
  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: primaryGreen,
      elevation: 0,
      side: BorderSide(color: primaryGreen, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
    );
  }
  
  // Modern Card Styles
  static BoxDecoration getModernCardDecoration(BuildContext context, {bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? darkCard : lightCard,
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: isDark ? darkBorder : lightBorder,
        width: 1,
      ),
      boxShadow: isDark ? strongShadow : mediumShadow,
    );
  }
  
  // Modern Text Styles
  static TextStyle getHeadingStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: fontSizeXXL,
      fontWeight: FontWeight.bold,
      color: isDark ? textOnDark : textPrimary,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle getSubheadingStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: fontSizeXL,
      fontWeight: FontWeight.w600,
      color: isDark ? textOnDark : textPrimary,
      letterSpacing: -0.25,
    );
  }
  
  static TextStyle getBodyStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: fontSizeM,
      fontWeight: FontWeight.normal,
      color: isDark ? textOnDark.withValues(alpha: 0.8) : textSecondary,
      height: 1.5,
    );
  }
  
  static TextStyle getCaptionStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: fontSizeS,
      fontWeight: FontWeight.normal,
      color: isDark ? textOnDark.withValues(alpha: 0.6) : textTertiary,
    );
  }
  
  // Modern Input Styles
  static InputDecoration getModernInputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDark = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? darkSurface : lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
    );
  }
}
