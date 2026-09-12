import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Clean typography hierarchy for ADDA.
abstract final class AddaTypography {
  static TextTheme createTextTheme({required bool isDark}) {
    final primaryColor = isDark
        ? AddaColors.textPrimaryDark
        : AddaColors.textPrimaryLight;
    final secondaryColor = isDark
        ? AddaColors.textSecondaryDark
        : AddaColors.textSecondaryLight;
    final mutedColor = isDark
        ? AddaColors.textMutedDark
        : AddaColors.textMutedLight;

    TextStyle baseStyle(
      double size,
      FontWeight weight,
      Color color, {
      double? height,
      double? letterSpacing,
    }) {
      try {
        return GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      } catch (_) {
        return TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      }
    }

    return TextTheme(
      displayLarge: baseStyle(
        32,
        FontWeight.w800,
        primaryColor,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: baseStyle(
        28,
        FontWeight.w700,
        primaryColor,
        height: 1.25,
        letterSpacing: -0.4,
      ),
      displaySmall: baseStyle(
        24,
        FontWeight.w700,
        primaryColor,
        height: 1.3,
        letterSpacing: -0.3,
      ),
      headlineMedium: baseStyle(
        20,
        FontWeight.w700,
        primaryColor,
        height: 1.35,
      ),
      headlineSmall: baseStyle(18, FontWeight.w600, primaryColor, height: 1.4),
      titleLarge: baseStyle(16, FontWeight.w600, primaryColor, height: 1.4),
      titleMedium: baseStyle(15, FontWeight.w600, primaryColor, height: 1.4),
      titleSmall: baseStyle(14, FontWeight.w600, secondaryColor, height: 1.4),
      bodyLarge: baseStyle(15, FontWeight.w400, primaryColor, height: 1.5),
      bodyMedium: baseStyle(14, FontWeight.w400, secondaryColor, height: 1.5),
      bodySmall: baseStyle(12, FontWeight.w400, mutedColor, height: 1.4),
      labelLarge: baseStyle(
        14,
        FontWeight.w600,
        primaryColor,
        letterSpacing: 0.2,
      ),
      labelMedium: baseStyle(
        12,
        FontWeight.w600,
        secondaryColor,
        letterSpacing: 0.3,
      ),
      labelSmall: baseStyle(
        11,
        FontWeight.w500,
        mutedColor,
        letterSpacing: 0.4,
      ),
    );
  }
}
