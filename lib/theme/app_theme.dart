import 'package:flutter/material.dart';

/// Central theme definition for the Velan app.
/// Green & white, Material 3, rounded corners, large tap targets.
class AppTheme {
  AppTheme._();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF81C784);
  static const Color backgroundLight = Color(0xFFF6F8FB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1C1E);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color cardDark = Color(0xFF1F2937);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: brightness,
      primary: isDark ? const Color(0xFF66BB6A) : primaryGreen,
      secondary: secondaryGreen,
      surface: isDark ? const Color(0xFF1E1E1E) : surfaceWhite,
    );

    final scaffoldBg = isDark ? const Color(0xFF121212) : backgroundLight;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : backgroundLight;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final appbarBg = isDark ? const Color(0xFF1E1E1E) : surfaceWhite;
    final textOnBg = isDark ? const Color(0xFFECEDEE) : textDark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: appbarBg,
        foregroundColor: textOnBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textOnBg,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: colorScheme.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fillColor,
        selectedColor: colorScheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        elevation: 2,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF37474F) : textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

/// Theme-aware color shortcuts so widgets follow light/dark mode
/// instead of hardcoding light-only colors.
extension AppColors on BuildContext {
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  Color get surfaceAlt => Theme.of(this).colorScheme.surfaceContainerLowest;

  Color get surfaceRaised => Theme.of(this).colorScheme.surfaceContainerHighest;

  Color get textPrimary => Theme.of(this).colorScheme.onSurface;

  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get borderColor => Theme.of(this).dividerTheme.color ?? Colors.grey.shade200;
}
