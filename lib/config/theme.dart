import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFF2C5F6F); // Deep Teal
  static const Color secondaryColor = Color(0xFFFF8C7A); // Soft Coral
  static const Color backgroundColor = Color(0xFFF5F8FA); // Pale Blue-Grey
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      brightness: Brightness.light,
    ),

    // Typography
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
      displayMedium:
          TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
      displaySmall: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
      headlineLarge:
          TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
      headlineMedium:
          TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
      headlineSmall:
          TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
      bodyLarge: TextStyle(color: Colors.grey[800]),
      bodyMedium: TextStyle(color: Colors.grey[700]),
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      iconTheme: IconThemeData(color: primaryColor),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.all(8),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor),
      ),
      labelStyle: TextStyle(color: Colors.grey[600]),
      hintStyle: TextStyle(color: Colors.grey[400]),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      selectedColor: primaryColor.withOpacity(0.1),
      secondarySelectedColor: primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: Colors.grey[700]),
      secondaryLabelStyle:
          TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    ),
  );
}
