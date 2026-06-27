import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranyTheme {
  // ───────────────────── Brand palette ─────────────────────
  // Deep forest green — primary brand color
  static const Color primary = Color(0xFF24513B);
  static const Color primaryDark = Color(0xFF1D4432);
  static const Color forest = Color(0xFF131711);

  // Sage / olive secondary + accents
  static const Color secondary = Color(0xFF5F7464);
  static const Color sage = Color(0xFF98A998);
  static const Color accent = Color(0xFFA8B78E);
  static const Color gold = Color(0xFFC4CEC1);

  // Surfaces & backgrounds
  static const Color background = Color(0xFFFBF8ED); // warm ivory
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEFF2E7); // very light green
  static const Color section = Color(0xFFF4F6EF);

  // Text
  static const Color textPrimary = Color(0xFF131711);
  static const Color textSecondary = Color(0xFF5F7464);
  static const Color textMuted = Color(0xFF98A998);

  // Semantic
  static const Color success = Color(0xFF6E9E59);
  static const Color progress = Color(0xFFA5C57E);
  static const Color warning = Color(0xFFC28E2C); // muted amber
  static const Color danger = Color(0xFFC0533F); // muted terracotta

  // Lines & shadows
  static const Color border = Color(0x1424513B); // rgba(36,81,59,0.08)
  static const Color shadow = Color(0x1F24513B); // rgba(36,81,59,0.12)

  // ──────────────── Backward-compatible aliases ────────────────
  // Existing screens reference these names; they now map to the new palette.
  static const Color primaryGreen = primary; // #24513B
  static const Color darkGreen = primaryDark; // #1D4432
  static const Color primaryGold = accent; // soft olive accent
  static const Color lightGreen = surfaceSoft; // #EFF2E7
  static const Color cream = section; // #F4F6EF
  static const Color surfaceWhite = surface; // #FFFFFF
  static const Color correctGreen = success; // #6E9E59
  static const Color warningOrange = warning; // muted amber
  static const Color errorRed = danger; // muted terracotta

  // Radii used across cards/buttons
  static const double cardRadius = 22;
  static const double buttonRadius = 16;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
      ),
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        headlineLarge: GoogleFonts.amiri(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        headlineMedium: GoogleFonts.amiri(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        headlineSmall: GoogleFonts.amiri(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.cairo(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.cairo(fontSize: 14, color: textPrimary),
        bodySmall: GoogleFonts.cairo(fontSize: 12, color: textSecondary),
        labelLarge: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 48,
        iconTheme: const IconThemeData(color: primary, size: 24),
        actionsIconTheme: const IconThemeData(color: primary, size: 24),
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: shadow,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: border),
        ),
        color: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.cairo(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: sage,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSoft,
        selectedColor: primary,
        labelStyle: GoogleFonts.cairo(color: textPrimary),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: sage,
        secondary: accent,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    );
  }
}
