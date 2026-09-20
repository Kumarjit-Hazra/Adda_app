import 'package:uuid/uuid.dart';
import '../../activities/engine/bot_player.dart';
import '../../activities/engine/player_action.dart';

import 'uno_models.dart';

class UnoBotPlayer extends BotPlayer<UnoState> {
  UnoBotPlayer({
    required super.playerId,
    super.difficulty = BotDifficulty.medium,
    super.random,
  });

  @override
  PlayerAction? computeNextAction(UnoState state) {
    if (state.winnerId != null) return null;

    final currentTurnId = state.playerIds[state.currentTurnIndex];
    if (currentTurnId != playerId) return null;

    final hand = state.hands[playerId] ?? [];
    if (hand.isEmpty) return null;

    // Find legal play
    final legalCards = hand.where((c) {
      if (c.isWild) return true;
      if (c.color == state.activeColor) return true;
      if (c.value == state.topDiscard.value) return true;
      return false;
    }).toList();

    if (legalCards.isNotEmpty) {
      final cardToPlay = legalCards[random.nextInt(legalCards.length)];
      UnoColor? chosenColor;
      if (cardToPlay.isWild) {
        final colors = UnoColor.values
            .where((c) => c != UnoColor.wild)
            .toList();
        chosenColor = colors[random.nextInt(colors.length)];
      }

      return PlayerAction(
        actionId: const Uuid().v4(),
        playerId: playerId,
        activityId: 'uno',
        type: 'play_card',
        payload: {
          'card': cardToPlay.toMap(),
          if (chosenColor != null) 'chosenColor': chosenColor.name,
        },
        clientSequence: state.version,
      );
    } else {
      // Draw card
      return PlayerAction(
        actionId: const Uuid().v4(),
        playerId: playerId,
        activityId: 'uno',
        type: 'draw_card',
        payload: {},
        clientSequence: state.version,
      );
    }
  }
}
