import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/teen_patti/teen_patti_engine.dart';
import 'package:adda/features/games/teen_patti/teen_patti_models.dart';

void main() {
  group('TeenPattiEngine Unit Tests', () {
    late TeenPattiEngine engine;
    final players = ['player_1', 'player_2'];

    setUp(() {
      engine = TeenPattiEngine();
    });

    test('initializes with 3 cards each and boot collected in pot', () {
      final state = engine.createInitialState(players);
      expect(state.pot, 20); // 10 boot each
      expect(state.players['player_1']!.cards.length, 3);
      expect(state.players['player_2']!.cards.length, 3);
      expect(state.players['player_1']!.hasSeenCards, isFalse);
    });

    test('evaluates hand rankings correctly', () {
      // Trail
      final trail = [
        const TeenPattiCard(suit: CardSuit.spades, rank: 14),
        const TeenPattiCard(suit: CardSuit.hearts, rank: 14),
        const TeenPattiCard(suit: CardSuit.clubs, rank: 14),
      ];
      expect(HandEvaluator.evaluate(trail).type, HandRankType.trail);

      // Pure Sequence
      final pureSeq = [
        const TeenPattiCard(suit: CardSuit.hearts, rank: 14),
        const TeenPattiCard(suit: CardSuit.hearts, rank: 13),
        const TeenPattiCard(suit: CardSuit.hearts, rank: 12),
      ];
      expect(HandEvaluator.evaluate(pureSeq).type, HandRankType.pureSequence);
    });

    test('folding hands victory to the other player', () {
      var state = engine.createInitialState(players);

      final foldAction = PlayerAction(
        actionId: 'tp1',
        playerId: state.currentTurnPlayerId,
        activityId: 'teen_patti',
        type: 'fold',
        payload: {},
        clientSequence: 1,
      );

      expect(engine.validateAction(state, foldAction), isTrue);
      state = engine.applyAction(state, foldAction);

      expect(state.roundOver, isTrue);
      expect(state.winnerId, isNotNull);
      expect(state.isFinished, isTrue);
    });
  });
}
