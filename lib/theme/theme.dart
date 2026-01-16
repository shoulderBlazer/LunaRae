import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dreamy Adaptive Theme for LunaRae
/// Automatically adapts between soft daylight mode and calm nighttime mode
class LunaTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // ☀️ DREAMY LIGHT MODE (Day) COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color lightGradientStart = Color(0xFFF6F4FF);
  static const Color lightGradientEnd = Color(0xFFEAE4FF);
  static const Color lightPrimary = Color(0xFFB9A8E5);       // Lavender
  static const Color lightSecondary = Color(0xFFFFD6C9);     // Soft peach
  static const Color lightCard = Color(0xFFFFFFFF);          // White
  static const Color lightTextPrimary = Color(0xFF2A2A2A);   // Charcoal
  static const Color lightTextSecondary = Color(0xFF6B6B6B); // Muted grey
  static const Color lightInputBg = Color(0xFFFFFBF5);       // Light cream

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌙 DREAMY NIGHT MODE (Bedtime) COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkGradientStart = Color(0xFF0F1026);
  static const Color darkGradientEnd = Color(0xFF1A1740);
  static const Color darkPrimary = Color(0xFFEBD9A3);        // Moon gold
  static const Color darkSecondary = Color(0xFF9F8CFF);      // Lavender glow
  static const Color darkCard = Color(0xFF1E1B3A);           // Dark card
  static const Color darkTextPrimary = Color(0xFFF4F1E8);    // Soft cream
  static const Color darkTextSecondary = Color(0xFFB8B6C9);  // Moon grey
  static const Color darkInputBg = Color(0xFF2A2654);        // Dark soft purple

  // ═══════════════════════════════════════════════════════════════════════════
  // RADIUS & SPACING
  // ═══════════════════════════════════════════════════════════════════════════
  static const double radiusCard = 28;
  static const double radiusButton = 50;
  static const double radiusInput = 50;
  static const double radiusAd = 16;
  static const double cardPadding = 24;

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color gradientStart(BuildContext context) =>
      isDarkMode(context) ? darkGradientStart : lightGradientStart;

  static Color gradientEnd(BuildContext context) =>
      isDarkMode(context) ? darkGradientEnd : lightGradientEnd;

  static Color primary(BuildContext context) =>
      isDarkMode(context) ? darkPrimary : lightPrimary;

  static Color secondary(BuildContext context) =>
      isDarkMode(context) ? darkSecondary : lightSecondary;

  static Color cardColor(BuildContext context) =>
      isDarkMode(context) ? darkCard : lightCard;

  static Color textPrimary(BuildContext context) =>
      isDarkMode(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDarkMode(context) ? darkTextSecondary : lightTextSecondary;

  static Color inputBackground(BuildContext context) =>
      isDarkMode(context) ? darkInputBg : lightInputBg;

  /// Background gradient decoration
  static BoxDecoration backgroundGradient(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientStart(context), gradientEnd(context)],
      ),
    );
  }

  /// Card shadow with theme-appropriate glow
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = isDarkMode(context);
    return [
      BoxShadow(
        color: isDark
            ? darkPrimary.withOpacity(0.15)  // Moon glow
            : lightPrimary.withOpacity(0.25), // Lavender glow
        blurRadius: 24,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Button gradient
  static LinearGradient buttonGradient(BuildContext context) {
    final isDark = isDarkMode(context);
    return LinearGradient(
      colors: isDark
          ? [darkPrimary, darkPrimary.withOpacity(0.85)]
          : [lightPrimary, lightPrimary.withOpacity(0.85)],
    );
  }

  /// Secondary button gradient
  static LinearGradient secondaryButtonGradient(BuildContext context) {
    final isDark = isDarkMode(context);
    return LinearGradient(
      colors: isDark
          ? [darkSecondary.withOpacity(0.3), darkSecondary.withOpacity(0.2)]
          : [lightSecondary.withOpacity(0.6), lightSecondary.withOpacity(0.4)],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT STYLES (using Google Fonts - Nunito for storybook feel)
  // ═══════════════════════════════════════════════════════════════════════════

  /// App title style (for "LunaRae" branding)
  static TextStyle appTitle(BuildContext context) => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary(context),
        letterSpacing: 1.2,
      );

  /// Story body text style
  static TextStyle storyBody(BuildContext context) => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: textPrimary(context),
        height: 1.7,
      );

  /// Primary body text
  static TextStyle body(BuildContext context) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary(context),
        height: 1.5,
      );

  /// Button text style
  static TextStyle buttonText(BuildContext context) => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: isDarkMode(context) ? darkCard : lightCard,
      );

  /// Hint/placeholder text
  static TextStyle hintText(BuildContext context) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary(context).withOpacity(0.7),
        fontStyle: FontStyle.italic,
      );

  /// Ad label text
  static TextStyle adLabel(BuildContext context) => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary(context).withOpacity(0.6),
        letterSpacing: 0.5,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME DATA BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightGradientEnd,
      textTheme: GoogleFonts.nunitoTextTheme(),
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightCard,
        onPrimary: lightCard,
        onSecondary: lightTextPrimary,
        onSurface: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkGradientEnd,
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.dark().textTheme,
      ),
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkCard,
        onPrimary: darkCard,
        onSecondary: darkTextPrimary,
        onSurface: darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
    );
  }
} 