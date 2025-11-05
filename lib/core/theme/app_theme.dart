import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Cores primárias (HSL: 214 100% 58%)
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Cores de fundo (HSL: 0 0% 98%)
  static const Color background = Color(0xFFFAFAFA);
  static const Color foreground = Color(0xFF334155); // HSL: 220 15% 20%

  // Cores secundárias (HSL: 214 20% 95%)
  static const Color secondary = Color(0xFFE2E8F0);
  static const Color secondaryForeground = Color(0xFF334155);

  // Cores muted
  static const Color muted = Color(0xFFF1F5F9); // HSL: 214 20% 96%
  static const Color mutedForeground = Color(0xFF64748B); // HSL: 220 10% 50%

  // Cores de accent/warning (HSL: 45 100% 75%)
  static const Color accent = Color(0xFFFEF3C7);
  static const Color accentForeground = Color(0xFF92400E); // HSL: 40 100% 20%

  // Cores de erro (HSL: 0 84.2% 60.2%)
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  // Borders e inputs
  static const Color border = Color(0xFFE2E8F0); // HSL: 214 20% 90%
  static const Color input = Color(0xFFE5E7EB); // HSL: 214 20% 92%

  // Card
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF334155);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        error: destructive,
        onError: destructiveForeground,
        surface: background,
        onSurface: foreground,
      ),

      // Scaffold
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: card,
        foregroundColor: foreground,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: foreground),
      ),

      // Card
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: secondary,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: mutedForeground,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
  }
}
