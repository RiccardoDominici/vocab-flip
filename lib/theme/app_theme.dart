import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Design size for ScreenUtil
  static const double designWidth = 393;
  static const double designHeight = 852;

  // Brand colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4A42D4);

  // Surface colors
  static const Color surfaceLight = Color(0xFFF8F9FE);
  static const Color surfaceMid = Color(0xFFEEF0F8);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textMuted = Color(0xFF9BA4AB);

  // Accent colors
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFA502);
  static const Color error = Color(0xFFFF4757);
  static const Color gold = Color(0xFFFFD700);

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      colorSchemeSeed: primary,
      brightness: Brightness.light,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: surfaceLight,
    );
  }

  static BoxDecoration get gradientBackground => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0EDFF),
            Color(0xFFF8F9FE),
            Color(0xFFEEF0F8),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );

  static BoxDecoration glassCard({
    double opacity = 0.65,
    double borderRadius = 20,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.8),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (shadowColor ?? primary).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration accentGlassCard({
    required Color color,
    double opacity = 0.12,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: color.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
