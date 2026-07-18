import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class AppTheme {
  static ThemeData getLightTheme(Color primaryColor) {
    final baseTextTheme = ThemeData.light().textTheme;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        headlineLarge: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: AppColors.textDark),
        headlineMedium: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: AppColors.textDark),
        headlineSmall: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: AppColors.textDark),
        titleLarge: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark),
        titleMedium: GoogleFonts.oswald(fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: AppColors.uenrGreen,
        surface: const Color(0xFFF5F5F5),
        onSurface: AppColors.textDark,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surfaceWhite,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: const BorderSide(color: AppColors.borderGray, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: false,
        titleTextStyle: GoogleFonts.oswald(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme(Color primaryColor) {
    const darkBg = Color(0xFF000000);
    const darkSurface = Color(0xFF0A0A0A);
    const darkBorder = Color(0xFF1A1F1A);

    final baseTextTheme = const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        headlineLarge: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        titleMedium: GoogleFonts.oswald(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: primaryColor == Colors.black ? Colors.white : Colors.white,
        surface: darkSurface,
        onSurface: const Color(0xFFE0E0E0),
        onSurfaceVariant: Colors.white70,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0, 
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.oswald(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
