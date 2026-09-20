import 'package:uuid/uuid.dart';
import '../../activities/engine/bot_player.dart';
import '../../activities/engine/player_action.dart';

import 'bluff_models.dart';

class BluffBotPlayer extends BotPlayer<BluffState> {
  BluffBotPlayer({
    required super.playerId,
    super.difficulty = BotDifficulty.medium,
    super.random,
  });

  @override
  PlayerAction? computeNextAction(BluffState state) {
    if (state.winnerId != null) return null;

    final currentTurnId = state.playerIds[state.currentTurnIndex];
    if (currentTurnId != playerId) return null;

    final hand = state.hands[playerId] ?? [];
    if (hand.isEmpty) return null;

    // Bot plays 1 to 3 random cards
    final maxPlay = hand.length > 3 ? 3 : hand.length;
    final playCount = random.nextInt(maxPlay) + 1;

    final chosen = List.of(hand)..shuffle(random);
    final selectedCards = chosen.take(playCount).toList();

    return PlayerAction(
      actionId: const Uuid().v4(),
      playerId: playerId,
      activityId: 'bluff',
      type: 'play_cards',
      payload: {'cards': selectedCards.map((c) => c.toMap()).toList()},
      clientSequence: state.version,
    );
  }
}
