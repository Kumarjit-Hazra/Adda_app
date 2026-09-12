import '../logging/logger_service.dart';

/// Centralized audio controller for UI & gameplay sound effects.
class AudioService {
  static bool masterEnabled = true;
  static bool sfxEnabled = true;
  static double masterVolume = 1.0;

  static Future<void> playUiTap() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: ui_tap');
  }

  static Future<void> playCardFlip() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: card_flip');
  }

  static Future<void> playCardDeal() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: card_deal');
  }

  static Future<void> playCardPlay() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: card_play');
  }

  static Future<void> playTick() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: countdown_tick');
  }

  static Future<void> playReaction() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: reaction_pop');
  }

  static Future<void> playWin() async {
    if (!masterEnabled || !sfxEnabled) return;
    LoggerService.d('Audio', 'play: win_fanfare');
  }
}
