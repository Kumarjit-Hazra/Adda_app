import 'package:flutter/material.dart';

/// Design tokens for the ADDA color palette.
/// Provides deep night lounge darks, calm crisp lights, and radiant social accents.
abstract final class AddaColors {
  // Dark Palette (Primary experience)
  static const Color bgDark = Color(0xFF090C15);
  static const Color surfaceDark = Color(0xFF111625);
  static const Color surfaceVariantDark = Color(0xFF182033);
  static const Color surfaceElevatedDark = Color(0xFF222B42);
  static const Color borderDark = Color(0x1FFFFFFF);
  static const Color borderLuminousDark = Color(0x33FFFFFF);

  // Light Palette
  static const Color bgLight = Color(0xFFF6F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEFF3FA);
  static const Color surfaceElevatedLight = Color(0xFFE4EAF4);
  static const Color borderLight = Color(0x14000000);
  static const Color borderLuminousLight = Color(0x28000000);

  // Vibrant Social Accents
  static const Color coral = Color(0xFFFF5E5B);
  static const Color amber = Color(0xFFFFAB00);
  static const Color violet = Color(0xFF8C52FF);
  static const Color emerald = Color(0xFF00E096);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color rose = Color(0xFFFF3366);

  // Text colors
  static const Color textPrimaryDark = Color(0xFFF3F5FA);
  static const Color textSecondaryDark = Color(0xFF98A2B8);
  static const Color textMutedDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [coral, amber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [violet, Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF00C853), emerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roomAmbientDark = LinearGradient(
    colors: [Color(0xFF13182B), Color(0xFF090C15)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
