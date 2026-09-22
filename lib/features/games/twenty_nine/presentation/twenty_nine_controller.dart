import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../activities/engine/player_action.dart';
import '../../domain/game_session_notifier.dart';

/// Small action controller that handles dispatching events to the TwentyNine game session.
/// Keeps the TwentyNineBoard presentation-focused.
class TwentyNineController {
  final WidgetRef ref;
  final String gameId = 'twenty_nine';

  TwentyNineController(this.ref);

  void dispatch(
    String type,
    Map<String, dynamic> payload, {
    required String playerId,
    required int currentVersion,
  }) {
    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: playerId,
      activityId: gameId,
      type: type,
      payload: payload,
      clientSequence: currentVersion,
    );

    final notifier = ref.read(gameSessionNotifierProvider(gameId).notifier);
    if (notifier.dispatchAction(action)) {
      AudioService.playCardPlay();
      HapticsService.cardPlay();
    }
  }

  void playCard(Map<String, dynamic> cardMap, String playerId, int version) {
    dispatch(
      'play_card',
      {'card': cardMap},
      playerId: playerId,
      currentVersion: version,
    );
  }

  void bid(int amount, String playerId, int version) {
    dispatch(
      'bid',
      {'bid': amount},
      playerId: playerId,
      currentVersion: version,
    );
  }

  void passBid(String playerId, int version) {
    dispatch(
      'bid',
      {'pass': true},
      playerId: playerId,
      currentVersion: version,
    );
  }

  void revealTrump(String playerId, int version) {
    dispatch('reveal_trump', {}, playerId: playerId, currentVersion: version);
  }
}
