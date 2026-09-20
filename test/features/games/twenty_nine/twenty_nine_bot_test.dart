import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/games/twenty_nine/twenty_nine_bot.dart';
import 'package:adda/features/games/twenty_nine/twenty_nine_models.dart';
import 'package:adda/features/activities/engine/bot_player.dart';

void main() {
  group('TwentyNineBotPlayer Tests', () {
    final random = Random(42);
    final bot = TwentyNineBotPlayer(
      playerId: 'bot1',
      difficulty: BotDifficulty.medium,
      random: random,
    );

    test('returns null if finished', () {
      final state = TwentyNineState(
        playerIds: ['bot1', 'p2', 'p3', 'p4'],
        hands: {},
        currentTurnIndex: 0,
        phase: TwentyNinePhase.finished,
        currentTrick: [],
        version: 1,
        highestBid: 16,
        completedTricks: [],
        teamTrickPoints: {0: 0, 1: 0},
      );

      final action = bot.computeNextAction(state);
      expect(action, isNull);
    });

    test('returns bid pass during bidding phase', () {
      final state = TwentyNineState(
        playerIds: ['bot1', 'p2', 'p3', 'p4'],
        hands: {'bot1': []},
        currentTurnIndex: 0,
        phase: TwentyNinePhase.bidding,
        currentTrick: [],
        version: 1,
        highestBid: 16,
        completedTricks: [],
        teamTrickPoints: {0: 0, 1: 0},
      );

      final action = bot.computeNextAction(state);
      expect(action, isNotNull);
      expect(action!.type, 'bid');
      expect(action.payload['pass'], isTrue);
    });

    test('plays card matching lead suit', () {
      final state = TwentyNineState(
        playerIds: ['p2', 'bot1', 'p3', 'p4'], // bot1 is next
        hands: {
          'bot1': [
            const PlayingCard(CardSuit.spades, CardRank.jack),
            const PlayingCard(CardSuit.hearts, CardRank.nine),
          ],
        },
        currentTurnIndex: 1,
        phase: TwentyNinePhase.playing,
        currentTrick: [
          const PlayedTrickCard(
            playerId: 'p2',
            card: PlayingCard(CardSuit.hearts, CardRank.jack),
          ),
        ],
        version: 1,
        highestBid: 16,
        completedTricks: [],
        teamTrickPoints: {0: 0, 1: 0},
      );

      final action = bot.computeNextAction(state);
      expect(action, isNotNull);
      expect(action!.type, 'play_card');
      expect(action.payload['card']['suit'], CardSuit.hearts.name);
    });
  });
}
