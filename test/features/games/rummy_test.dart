import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/rummy/rummy_engine.dart';
import 'package:adda/features/games/rummy/rummy_models.dart';

void main() {
  group('RummyEngine Unit Tests', () {
    late RummyEngine engine;
    final players = ['player_1', 'player_2'];

    setUp(() {
      engine = RummyEngine();
    });

    test('initializes with 13 cards each, open deck, and wild joker', () {
      final state = engine.createInitialState(players);
      expect(state.players['player_1']!.hand.length, 13);
      expect(state.openDeck.length, 1);
      expect(state.closedDeck.isNotEmpty, isTrue);
      expect(state.turnStage, RummyTurnStage.draw);
    });

    test(
      'draw from closed deck increases hand to 14, then discard returns to 13',
      () {
        var state = engine.createInitialState(players);
        final turnPlayer = state.currentTurnPlayerId;

        final drawAction = PlayerAction(
          actionId: 'rm1',
          playerId: turnPlayer,
          activityId: 'rummy',
          type: 'draw_card',
          payload: {'source': 'closed'},
          clientSequence: 1,
        );

        expect(engine.validateAction(state, drawAction), isTrue);
        state = engine.applyAction(state, drawAction);

        expect(state.players[turnPlayer]!.hand.length, 14);
        expect(state.turnStage, RummyTurnStage.discard);

        final discardAction = PlayerAction(
          actionId: 'rm2',
          playerId: turnPlayer,
          activityId: 'rummy',
          type: 'discard_card',
          payload: {'index': 0},
          clientSequence: 2,
        );

        expect(engine.validateAction(state, discardAction), isTrue);
        state = engine.applyAction(state, discardAction);

        expect(state.players[turnPlayer]!.hand.length, 13);
        expect(state.turnStage, RummyTurnStage.draw);
        expect(state.currentTurnPlayerId, isNot(turnPlayer));
      },
    );

    test('validates pure sequence correctly', () {
      final pureSeq = [
        const RummyCard(suit: RummySuit.spades, rank: 3),
        const RummyCard(suit: RummySuit.spades, rank: 4),
        const RummyCard(suit: RummySuit.spades, rank: 5),
      ];
      expect(RummyValidator.isPureSequence(pureSeq), isTrue);

      final invalidSeq = [
        const RummyCard(suit: RummySuit.spades, rank: 3),
        const RummyCard(suit: RummySuit.hearts, rank: 4),
        const RummyCard(suit: RummySuit.spades, rank: 5),
      ];
      expect(RummyValidator.isPureSequence(invalidSeq), isFalse);
    });
  });
}
