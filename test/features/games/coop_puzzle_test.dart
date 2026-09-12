import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/coop_puzzle/coop_puzzle_engine.dart';

void main() {
  group('CoopPuzzleEngine Unit Tests', () {
    late CoopPuzzleEngine engine;
    final players = ['detective_1', 'detective_2'];

    setUp(() {
      engine = CoopPuzzleEngine();
    });

    test('initializes asymmetric clues per player', () {
      final state = engine.createInitialState(players);
      expect(state.correctCode, '6375');
      expect(state.privateClues['detective_1']!.isNotEmpty, isTrue);
      expect(state.privateClues['detective_2']!.isNotEmpty, isTrue);
      // Clues are asymmetric
      expect(
        state.privateClues['detective_1'],
        isNot(equals(state.privateClues['detective_2'])),
      );
    });

    test('entering correct code unlocks vault and triggers victory', () {
      var state = engine.createInitialState(players);

      for (final digit in ['6', '3', '7', '5']) {
        state = engine.applyAction(
          state,
          PlayerAction(
            actionId: 'k_$digit',
            playerId: 'detective_1',
            activityId: 'coop_puzzle',
            type: 'press_key',
            payload: {'key': digit},
            clientSequence: state.version,
          ),
        );
      }

      expect(state.enteredCode, '6375');

      // Press ENTER
      final enterAction = PlayerAction(
        actionId: 'k_enter',
        playerId: 'detective_1',
        activityId: 'coop_puzzle',
        type: 'press_key',
        payload: {'key': 'ENTER'},
        clientSequence: state.version,
      );
      state = engine.applyAction(state, enterAction);

      expect(state.isSolved, isTrue);
      expect(engine.isFinished(state), isTrue);
    });
  });
}
