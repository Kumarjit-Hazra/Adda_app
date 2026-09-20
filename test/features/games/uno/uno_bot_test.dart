import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/games/uno/uno_bot.dart';
import 'package:adda/features/games/uno/uno_models.dart';
import 'package:adda/features/activities/engine/bot_player.dart';

void main() {
  group('UnoBotPlayer Tests', () {
    final random = Random(42);
    final bot = UnoBotPlayer(playerId: 'bot1', difficulty: BotDifficulty.medium, random: random);

    test('returns null if winner is declared', () {
      final state = UnoState(
        playerIds: ['bot1', 'p2'],
        hands: {},
        currentTurnIndex: 0,
        drawPile: [],
        discardPile: [const UnoCard(UnoColor.red, UnoValue.zero)],
        activeColor: UnoColor.red,
        version: 1,
        winnerId: 'p2',
      );
      
      final action = bot.computeNextAction(state);
      expect(action, isNull);
    });

    test('returns null if not bot turn', () {
      final state = UnoState(
        playerIds: ['p2', 'bot1'],
        hands: {'bot1': [const UnoCard(UnoColor.red, UnoValue.zero)]},
        currentTurnIndex: 0,
        drawPile: [],
        discardPile: [const UnoCard(UnoColor.red, UnoValue.zero)],
        activeColor: UnoColor.red,
        version: 1,
      );
      
      final action = bot.computeNextAction(state);
      expect(action, isNull);
    });

    test('draws card if no legal plays', () {
      final state = UnoState(
        playerIds: ['bot1', 'p2'],
        hands: {'bot1': [const UnoCard(UnoColor.blue, UnoValue.one)]},
        currentTurnIndex: 0,
        drawPile: [const UnoCard(UnoColor.green, UnoValue.two)],
        discardPile: [const UnoCard(UnoColor.red, UnoValue.zero)],
        activeColor: UnoColor.red,
        version: 1,
      );
      
      final action = bot.computeNextAction(state);
      expect(action, isNotNull);
      expect(action!.type, 'draw_card');
    });

    test('plays legal card if available', () {
      final state = UnoState(
        playerIds: ['bot1', 'p2'],
        hands: {
          'bot1': [
            const UnoCard(UnoColor.blue, UnoValue.one),
            const UnoCard(UnoColor.red, UnoValue.one),
          ]
        },
        currentTurnIndex: 0,
        drawPile: [],
        discardPile: [const UnoCard(UnoColor.red, UnoValue.zero)],
        activeColor: UnoColor.red,
        version: 1,
      );
      
      final action = bot.computeNextAction(state);
      expect(action, isNotNull);
      expect(action!.type, 'play_card');
      expect(action.payload['card']['color'], UnoColor.red.name);
    });
  });
}
