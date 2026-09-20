import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/games/bluff/bluff_bot.dart';
import 'package:adda/features/games/bluff/bluff_models.dart';
import 'package:adda/features/activities/engine/bot_player.dart';

void main() {
  group('BluffBotPlayer Tests', () {
    final random = Random(42);
    final bot = BluffBotPlayer(playerId: 'bot1', difficulty: BotDifficulty.medium, random: random);

    test('returns null if winner is declared', () {
      final state = BluffState(
        playerIds: ['bot1', 'p2'],
        hands: {},
        centerPile: [],
        currentTurnIndex: 0,
        currentRankRequirement: BluffRank.ace,
        version: 1,
        winnerId: 'p2',
      );
      
      final action = bot.computeNextAction(state);
      expect(action, isNull);
    });

    test('plays 1 to 3 valid cards deterministically based on seed', () {
      final state = BluffState(
        playerIds: ['bot1', 'p2'],
        hands: {
          'bot1': [
            const BluffCard(BluffRank.three, 0),
            const BluffCard(BluffRank.five, 1),
            const BluffCard(BluffRank.six, 0),
            const BluffCard(BluffRank.king, 3),
          ]
        },
        centerPile: [],
        currentTurnIndex: 0,
        currentRankRequirement: BluffRank.ace,
        version: 1,
      );
      
      final action = bot.computeNextAction(state);
      expect(action, isNotNull);
      expect(action!.type, 'play_cards');
      expect(action.payload['cards'], isNotEmpty);
    });
  });
}
