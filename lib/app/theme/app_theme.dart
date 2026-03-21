import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const background = Color(0xFF070B11);
    const surface = Color(0xFF101825);
    const surfaceContainer = Color(0xFF172133);
    const outline = Color(0xFF314157);
    const primary = Color(0xFFFF6A1A);
    const secondary = Color(0xFF16C7FF);
    const tertiary = Color(0xFFE33DFF);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHighest: Color(0xFF202D42),
      error: Color(0xFFFF5D73),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFF4F7FB),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      focusColor: primary.withValues(alpha: 0.18),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, height: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF91A0B7)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: primary.withValues(alpha: 0.2),
        secondarySelectedColor: primary.withValues(alpha: 0.2),
        disabledColor: surfaceContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      dividerTheme: const DividerThemeData(color: outline),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
