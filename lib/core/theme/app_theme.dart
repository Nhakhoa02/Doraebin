import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Color Scheme from "Bé Học Tiếng Việt"
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Primary (Green Tones)
    primary: Color(0xFF576A4B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4E9C3),
    onPrimaryContainer: Color(0xFF45573A),
    
    // Secondary (Teal Tones)
    secondary: Color(0xFF3C6B75),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFBAEBF5),
    onSecondaryContainer: Color(0xFF285861),
    
    // Tertiary (Warm Accents)
    tertiary: Color(0xFF93543B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFAD8F),
    onTertiaryContainer: Color(0xFF632D17),
    
    // Error
    error: Color(0xFFAE4025),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFD795A),
    onErrorContainer: Color(0xFF6E1400),
    
    // Surfaces & Backgrounds
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF3A3A0F),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFEFBD0),
    surfaceContainer: Color(0xFFF9F6C5),
    surfaceContainerHigh: Color(0xFFF3F0BC),
    surfaceContainerHighest: Color(0xFFEDEBB0),
    onSurfaceVariant: Color(0xFF676737),
    
    // Outlines
    outline: Color(0xFF848351),
    outlineVariant: Color(0xFFBEBC85),
    
    // Deprecated but still used in some places in Flutter
    background: Color(0xFFFFFBFF),
    onBackground: Color(0xFF3A3A0F),
  );

  // 2. Typography
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display/Headline: Plus Jakarta Sans
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -0.25),
      displayMedium: GoogleFonts.plusJakartaSans(fontSize: 45, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
      
      // Title/Body/Label: Be Vietnam Pro (crucial for Vietnamese diacritics legibility)
      titleLarge: GoogleFonts.beVietnamPro(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleSmall: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      
      bodyLarge: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5),
      bodyMedium: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25),
      bodySmall: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.4),
      
      labelLarge: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.1),
      labelMedium: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      labelSmall: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    ).apply(
      displayColor: _colorScheme.onSurface,
      bodyColor: _colorScheme.onSurface,
    );
  }

  // 3. The Global Theme Data
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    textTheme: _buildTextTheme(),
    
    // Unified Button Styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _colorScheme.onPrimary,
        backgroundColor: _colorScheme.primary, // Using primary since true gradient isn't supported inside generic style without a custom container
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 64), // For kids touch targets
      ),
    ),
    
    // Default Card Styling for "No-Line" rule
    cardTheme: CardThemeData(
      color: _colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
  );
}
