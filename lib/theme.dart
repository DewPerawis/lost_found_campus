import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const cream = Color(0xFFFFF6DE);
  static const peach = Color(0xFFF0A78A);
  static const softYellow = Color(0xFFF7DE8A);
  static const brownText = Color(0xFF5A4B3A);
  static const greyText = Color(0xFF9A9A9A);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: peach,
      primary: peach,
      secondary: softYellow,
      surface: cream, // แทน background (deprecated)
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: brownText,
      displayColor: brownText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8), // แทน withOpacity
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: peach, width: 2),
      ),
      hintStyle: const TextStyle(color: greyText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: softYellow,
        foregroundColor: brownText,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: brownText,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
