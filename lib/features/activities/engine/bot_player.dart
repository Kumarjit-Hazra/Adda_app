import 'dart:math' as math;
import 'player_action.dart';

/// Difficulty level for a bot player.
enum BotDifficulty { easy, medium, hard }

/// Abstract contract for an AI bot player.
///
/// Bots act as action producers. They inspect the current game state and
/// return a [PlayerAction]. They do not mutate state directly, nor do they
/// bypass the normal action validation pipeline.
abstract class BotPlayer<TState> {
  final String playerId;
  final BotDifficulty difficulty;
  final math.Random random;

  BotPlayer({
    required this.playerId,
    this.difficulty = BotDifficulty.medium,
    math.Random? random,
  }) : random = random ?? math.Random();

  /// Computes the next action for this bot given the current [state].
  ///
  /// Returns a valid [PlayerAction] that the engine can process, or `null`
  /// if no action is currently possible or the bot chooses to wait.
  PlayerAction? computeNextAction(TState state);
}
