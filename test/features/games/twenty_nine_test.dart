import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/twenty_nine/twenty_nine_engine.dart';
import 'package:adda/features/games/twenty_nine/twenty_nine_models.dart';

void main() {
  group('TwentyNineEngine Unit Tests', () {
    late TwentyNineEngine engine;
    final players = ['p0', 'p1', 'p2', 'p3'];

    setUp(() {
      engine = TwentyNineEngine();
    });

    test('initial state deals 8 cards each from 32-card deck', () {
      final state = engine.createInitialState(players);
      expect(state.playerIds.length, 4);
      expect(state.hands.length, 4);
      for (final id in players) {
        expect(state.hands[id]!.length, 8);
      }
      expect(state.phase, TwentyNinePhase.bidding);
      expect(state.highestBid, 16);
    });

    test('card point values are strictly according to 29 rules', () {
      const jack = PlayingCard(CardSuit.hearts, CardRank.jack);
      const nine = PlayingCard(CardSuit.hearts, CardRank.nine);
      const ace = PlayingCard(CardSuit.hearts, CardRank.ace);
      const ten = PlayingCard(CardSuit.hearts, CardRank.ten);
      const king = PlayingCard(CardSuit.hearts, CardRank.king);
      const seven = PlayingCard(CardSuit.hearts, CardRank.seven);

      expect(jack.points, 3);
      expect(nine.points, 2);
      expect(ace.points, 1);
      expect(ten.points, 1);
      expect(king.points, 0);
      expect(seven.points, 0);
    });

    test('bidding action updates highest bid and bidder', () {
      var state = engine.createInitialState(players);
      final bidAction = PlayerAction(
        actionId: 'a1',
        playerId: 'p0',
        activityId: 'twenty_nine',
        type: 'bid',
        payload: {'bid': 17},
        clientSequence: 1,
      );

      expect(engine.validateAction(state, bidAction), isTrue);
      state = engine.applyAction(state, bidAction);

      expect(state.highestBid, 17);
      expect(state.highestBidderId, 'p0');
      expect(state.currentTurnIndex, 1);
    });

    test('playing card must follow lead suit when player has lead suit', () {
      final state = TwentyNineState(
        version: 1,
        playerIds: players,
        hands: {
          'p0': [const PlayingCard(CardSuit.spades, CardRank.jack)],
          'p1': [
            const PlayingCard(CardSuit.spades, CardRank.seven),
            const PlayingCard(CardSuit.hearts, CardRank.ace),
          ],
          'p2': [],
          'p3': [],
        },
        phase: TwentyNinePhase.playing,
        currentTurnIndex: 1,
        highestBid: 16,
        currentTrick: [
          const PlayedTrickCard(
            playerId: 'p0',
            card: PlayingCard(CardSuit.spades, CardRank.jack),
          ),
        ],
        completedTricks: [],
        teamTrickPoints: {0: 0, 1: 0},
      );

      // p1 playing hearts while holding spades is illegal
      final illegalPlay = PlayerAction(
        actionId: 'a2',
        playerId: 'p1',
        activityId: 'twenty_nine',
        type: 'play_card',
        payload: {
          'card': const PlayingCard(CardSuit.hearts, CardRank.ace).toMap(),
        },
        clientSequence: 1,
      );
      expect(engine.validateAction(state, illegalPlay), isFalse);

      // p1 playing spades is legal
      final legalPlay = PlayerAction(
        actionId: 'a3',
        playerId: 'p1',
        activityId: 'twenty_nine',
        type: 'play_card',
        payload: {
          'card': const PlayingCard(CardSuit.spades, CardRank.seven).toMap(),
        },
        clientSequence: 1,
      );
      expect(engine.validateAction(state, legalPlay), isTrue);
    });
  });
}
