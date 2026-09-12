import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/uno/uno_engine.dart';
import 'package:adda/features/games/uno/uno_models.dart';

void main() {
  group('UnoEngine Unit Tests', () {
    late UnoEngine engine;
    final players = ['p0', 'p1', 'p2'];

    setUp(() {
      engine = UnoEngine();
    });

    test('initial state deals 7 cards to each player', () {
      final state = engine.createInitialState(players);
      expect(state.playerIds.length, 3);
      for (final id in players) {
        expect(state.hands[id]!.length, 7);
      }
      expect(state.discardPile.length, 1);
      expect(state.drawPile.isNotEmpty, isTrue);
      expect(state.winnerId, isNull);
    });

    test('validates matching card by color or number or wild', () {
      final state = UnoState(
        version: 1,
        playerIds: players,
        hands: {
          'p0': [
            const UnoCard(UnoColor.red, UnoValue.five),
            const UnoCard(UnoColor.blue, UnoValue.three),
            const UnoCard(UnoColor.wild, UnoValue.wild),
          ],
          'p1': [],
          'p2': [],
        },
        drawPile: [],
        discardPile: [const UnoCard(UnoColor.red, UnoValue.nine)],
        currentTurnIndex: 0,
        activeColor: UnoColor.red,
      );

      // Red 5 matches Red 9 in color
      final matchColor = PlayerAction(
        actionId: 'u1',
        playerId: 'p0',
        activityId: 'uno',
        type: 'play_card',
        payload: {'card': const UnoCard(UnoColor.red, UnoValue.five).toMap()},
        clientSequence: 1,
      );
      expect(engine.validateAction(state, matchColor), isTrue);

      // Blue 3 does NOT match Red 9
      final nonMatch = PlayerAction(
        actionId: 'u2',
        playerId: 'p0',
        activityId: 'uno',
        type: 'play_card',
        payload: {'card': const UnoCard(UnoColor.blue, UnoValue.three).toMap()},
        clientSequence: 1,
      );
      expect(engine.validateAction(state, nonMatch), isFalse);

      // Wild card is always playable
      final wildPlay = PlayerAction(
        actionId: 'u3',
        playerId: 'p0',
        activityId: 'uno',
        type: 'play_card',
        payload: {'card': const UnoCard(UnoColor.wild, UnoValue.wild).toMap()},
        clientSequence: 1,
      );
      expect(engine.validateAction(state, wildPlay), isTrue);
    });

    test('empty hand triggers winner detection', () {
      final state = UnoState(
        version: 1,
        playerIds: players,
        hands: {
          'p0': [const UnoCard(UnoColor.red, UnoValue.five)],
          'p1': [const UnoCard(UnoColor.blue, UnoValue.three)],
          'p2': [const UnoCard(UnoColor.green, UnoValue.one)],
        },
        drawPile: [],
        discardPile: [const UnoCard(UnoColor.red, UnoValue.nine)],
        currentTurnIndex: 0,
        activeColor: UnoColor.red,
      );

      final winningAction = PlayerAction(
        actionId: 'u4',
        playerId: 'p0',
        activityId: 'uno',
        type: 'play_card',
        payload: {'card': const UnoCard(UnoColor.red, UnoValue.five).toMap()},
        clientSequence: 1,
      );

      final nextState = engine.applyAction(state, winningAction);
      expect(nextState.winnerId, 'p0');
      expect(nextState.hands['p0']!.isEmpty, isTrue);
      expect(engine.isFinished(nextState), isTrue);
    });
  });
}
