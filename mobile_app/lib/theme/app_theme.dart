import 'package:flutter/material.dart';

/// Central design system for Skin Care Centre.
///
/// A clinical, professional palette (deep navy + teal accent) with
/// consistent spacing, elevation, and typography so every screen feels
/// like part of the same product instead of a collection of default
/// Material widgets.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0F3D5C); // deep clinical navy
  static const Color primaryLight = Color(0xFF1F6F8B); // teal accent
  static const Color secondary = Color(0xFF14B8A6); // fresh teal
  static const Color background = Color(0xFFF4F7FA);
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE0A100);
  static const Color danger = Color(0xFFD64545);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
    );

    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: primary),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: primary,
          fontSize: 13,
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        dividerThickness: 0.6,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFEFF3F6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: primary),
        selectedLabelTextStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.black.withValues(alpha: 0.45),
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.55),
        ),
        indicatorColor: primary.withValues(alpha: 0.12),
        useIndicator: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.4,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: Colors.black.withValues(alpha: 0.65),
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: Colors.black.withValues(alpha: 0.65),
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: Colors.black.withValues(alpha: 0.55),
      ),
    );
  }
}

/// Consistent spacing scale used across screens.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// A small palette of accent colors used to give avatars / icon badges
/// visual variety while staying on-brand.
const List<Color> avatarPalette = [
  Color(0xFF0F3D5C),
  Color(0xFF14B8A6),
  Color(0xFF6D5DD3),
  Color(0xFFDA6C2E),
  Color(0xFF2E9E6B),
  Color(0xFFC0447A),
];

Color colorForSeed(String seed) {
  final index = seed.isEmpty ? 0 : seed.codeUnitAt(0) % avatarPalette.length;
  return avatarPalette[index];
}
