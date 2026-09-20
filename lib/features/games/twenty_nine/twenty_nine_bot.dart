import 'package:uuid/uuid.dart';
import '../../activities/engine/bot_player.dart';
import '../../activities/engine/player_action.dart';

import 'twenty_nine_models.dart';

class TwentyNineBotPlayer extends BotPlayer<TwentyNineState> {
  TwentyNineBotPlayer({
    required super.playerId,
    super.difficulty = BotDifficulty.medium,
    super.random,
  });

  @override
  PlayerAction? computeNextAction(TwentyNineState state) {
    if (state.phase == TwentyNinePhase.finished) return null;

    final currentTurnId = state.playerIds[state.currentTurnIndex];
    if (currentTurnId != playerId) return null;

    final hand = state.hands[playerId] ?? [];

    if (state.phase == TwentyNinePhase.bidding) {
      // Very simple heuristic: pass
      return PlayerAction(
        actionId: const Uuid().v4(),
        playerId: playerId,
        activityId: 'twenty_nine',
        type: 'bid',
        payload: {'pass': true},
        clientSequence: state.version,
      );
    } else if (state.phase == TwentyNinePhase.playing && hand.isNotEmpty) {
      // Play legal card
      PlayingCard cardToPlay = hand[random.nextInt(hand.length)];
      if (state.currentTrick.isNotEmpty) {
        final leadSuit = state.currentTrick.first.card.suit;
        final match = hand.where((c) => c.suit == leadSuit).toList();
        if (match.isNotEmpty) {
          cardToPlay = match[random.nextInt(match.length)];
        }
      }

      return PlayerAction(
        actionId: const Uuid().v4(),
        playerId: playerId,
        activityId: 'twenty_nine',
        type: 'play_card',
        payload: {'card': cardToPlay.toMap()},
        clientSequence: state.version,
      );
    }

    return null;
  }
}
