import 'package:flutter/material.dart';

/// Centralized visual identity for Block Fusion.
///
/// The look is the casual-puzzle house style: a warm indigo-to-violet
/// backdrop, a deep navy board panel that the bright candy-colored blocks
/// sit on top of, and gold accents for anything score-related.
abstract final class AppTheme {
  /// The app backdrop, top to bottom.
  static const Color backgroundTop = Color(0xFF5B4BD6);
  static const Color backgroundBottom = Color(0xFF2E2478);

  /// A single flat stand-in for the gradient, for surfaces that cannot
  /// paint one (the Flame canvas clear, Scaffold background).
  static const Color background = Color(0xFF453AAE);

  /// The board panel and the empty cells inside it.
  static const Color boardPanel = Color(0xFF1E2244);
  static const Color boardCell = Color(0xFF2C3164);

  static const Color surface = Color(0xFF3A2FA0);
  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFF00D2A0);

  /// Score gold, used for the crown and best-score row.
  static const Color accent = Color(0xFFFFCB3D);

  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFC6C2E8);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

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
          fontWeight: FontWeight.w900,
          color: onBackground,
          letterSpacing: 1.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: onBackground,
        ),
        bodyMedium: TextStyle(color: onBackground),
        bodySmall: TextStyle(color: muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF3A2A00),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
