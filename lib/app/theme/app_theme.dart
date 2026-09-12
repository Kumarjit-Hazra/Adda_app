import 'package:flutter/material.dart';
import '../../shared/design_system/tokens/colors.dart';
import '../../shared/design_system/tokens/radius.dart';
import '../../shared/design_system/tokens/typography.dart';

/// ThemeData configurations for ADDA (Dark default + crisp Light).
abstract final class AddaTheme {
  static ThemeData get darkTheme {
    final textTheme = AddaTypography.createTextTheme(isDark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AddaColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AddaColors.coral,
        secondary: AddaColors.amber,
        tertiary: AddaColors.violet,
        surface: AddaColors.surfaceDark,
        error: AddaColors.rose,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AddaColors.textPrimaryDark,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AddaColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AddaRadius.radiusLg,
          side: const BorderSide(color: AddaColors.borderDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AddaColors.bgDark,
        foregroundColor: AddaColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AddaColors.surfaceDark,
        selectedItemColor: AddaColors.coral,
        unselectedItemColor: AddaColors.textMutedDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AddaColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AddaColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AddaRadius.radiusMd,
          borderSide: const BorderSide(color: AddaColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AddaRadius.radiusMd,
          borderSide: const BorderSide(color: AddaColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AddaRadius.radiusMd,
          borderSide: const BorderSide(color: AddaColors.coral, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AddaColors.textMutedDark,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = AddaTypography.createTextTheme(isDark: false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AddaColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AddaColors.coral,
        secondary: AddaColors.amber,
        tertiary: AddaColors.violet,
        surface: AddaColors.surfaceLight,
        error: AddaColors.rose,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AddaColors.textPrimaryLight,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AddaColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AddaRadius.radiusLg,
          side: const BorderSide(color: AddaColors.borderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AddaColors.bgLight,
        foregroundColor: AddaColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AddaColors.surfaceLight,
        selectedItemColor: AddaColors.coral,
        unselectedItemColor: AddaColors.textMutedLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AddaColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AddaColors.surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AddaRadius.radiusMd,
          borderSide: const BorderSide(color: AddaColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AddaRadius.radiusMd,
          borderSide: const BorderSide(color: AddaColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AddaRadius.radiusMd,
          borderSide: const BorderSide(color: AddaColors.coral, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AddaColors.textMutedLight,
          fontSize: 14,
        ),
      ),
    );
  }
}
