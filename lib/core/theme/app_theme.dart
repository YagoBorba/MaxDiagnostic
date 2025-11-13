import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_theme_colors.dart';

class AppTheme {
  AppTheme._();

  // ### Brand primary (fonte da verdade) ###
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Cores de fundo (HSL: 0 0% 98%)
  static const Color background = Color(0xFFF1F5F9);
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

  static final BrandThemeColors _brandLightColors = BrandThemeColors(
    primaryTintedBackground: Color.alphaBlend(
      primary.withValues(alpha: 0.08),
      card,
    ),
    primaryBorder: primary.withValues(alpha: 0.2),
    primaryHeadline: Color.alphaBlend(
      Colors.black.withValues(alpha: 0.2),
      primary,
    ),
    primaryBody: Color.alphaBlend(
      Colors.white.withValues(alpha: 0.1),
      primary,
    ),
    adviceCritical: const AdviceColors(
      background: Color(0xFFFEF2F2),
      icon: Color(0xFFEF4444),
      title: Color(0xFFB91C1C),
      text: Color(0xFF991B1B),
    ),
    adviceWarning: const AdviceColors(
      background: Color(0xFFFFFBEB),
      icon: Color(0xFFF59E0B),
      title: Color(0xFFB45309),
      text: Color(0xFF92400E),
    ),
    adviceGood: const AdviceColors(
      background: Color(0xFFF0FDF4),
      icon: Color(0xFF22C55E),
      title: Color(0xFF15803D),
      text: Color(0xFF166534),
    ),
    adviceInfo: const AdviceColors(
      background: Color(0xFFEFF6FF),
      icon: primary,
      title: Color(0xFF1E40AF),
      text: Color(0xFF1D4ED8),
    ),
    testRunning: const TestItemColors(
      background: Color(0xFFEFF6FF),
      border: Color(0xFF4D89FF),
      iconContainer: Color(0xFFDBEAFE),
      icon: Color(0xFF4D89FF),
      text: Color(0xFF2563EB),
      result: Color(0xFF2563EB),
    ),
    testComplete: const TestItemColors(
      background: Color(0xFFF0FDF4),
      border: Color(0xFF10B981),
      iconContainer: Color(0xFFD1FAE5),
      icon: Color(0xFF10B981),
      text: Color(0xFF059669),
      result: Color(0xFF047857),
    ),
    testError: const TestItemColors(
      background: Color(0xFFFEF2F2),
      border: Color(0xFFEF4444),
      iconContainer: Color(0xFFFEE2E2),
      icon: Color(0xFFEF4444),
      text: Color(0xFFDC2626),
      result: Color(0xFFB91C1C),
    ),
    testPending: const TestItemColors(
      background: card,
      border: Color(0xFFE5E7EB),
      iconContainer: Color(0xFFF1F5F9),
      icon: Color(0xFF94A3B8),
      text: Color(0xFF64748B),
      result: Color(0xFF94A3B8),
    ),
    signalExcellent: const Color(0xFF16A34A),
    signalNormal: const Color(0xFFD97706),
    signalPoor: const Color(0xFFDC2626),
  );

  static ThemeData get lightTheme {
    const baseTextTheme = TextTheme(
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
    );

    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

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
        surface: card,
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
      extensions: <ThemeExtension<dynamic>>[
        _brandLightColors,
      ],

      textTheme: textTheme,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
  }
}
