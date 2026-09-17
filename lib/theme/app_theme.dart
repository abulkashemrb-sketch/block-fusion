import 'package:flutter/material.dart';

/// Centralized visual identity for Block Fusion.
///
/// The palette is tuned for a dark, high-contrast puzzle-game look so that
/// colorful block pieces (defined later in the game layer) stand out clearly
/// against the board background.
abstract final class AppTheme {
  static const Color background = Color(0xFF12141C);
  static const Color surface = Color(0xFF1B1E2B);
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF00D2A0);
  static const Color onBackground = Color(0xFFEDEDF4);
  static const Color muted = Color(0xFF8A8DA6);

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: onBackground,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: onBackground,
        ),
        bodyMedium: TextStyle(color: onBackground),
        bodySmall: TextStyle(color: muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
