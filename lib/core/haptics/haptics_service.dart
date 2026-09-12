import 'package:flutter/services.dart';
import '../logging/logger_service.dart';

/// Centralized tactile feedback service.
class HapticsService {
  static bool enabled = true;

  static Future<void> lightTap() async {
    if (!enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      LoggerService.d('Haptics', 'Haptics not supported or failed: $e');
    }
  }

  static Future<void> selectionClick() async {
    if (!enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> success() async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> warning() async {
    if (!enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> cardPlay() async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> gameWin() async {
    if (!enabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
