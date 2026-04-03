import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0B0B);
  static const Color cardSurface = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFFD4AF37); // Gold
  static const Color accentBlue = Color(0xFF007AFF); // Electric Blue
  static const Color success = Color(0xFF2ECC71); // Emerald Green
  static const Color error = Color(0xFFFF5C5C); // Sunset Orange
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A8D9F);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentBlue,
        surface: cardSurface,
        error: error,
        onSurface: textLight,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: textLight, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.inter(color: textLight),
        bodyMedium: GoogleFonts.inter(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
