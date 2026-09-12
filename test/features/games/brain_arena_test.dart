import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/brain_arena/brain_arena_engine.dart';

void main() {
  group('BrainArenaEngine Unit Tests', () {
    late BrainArenaEngine engine;
    final players = ['player_1', 'player_2'];

    setUp(() {
      engine = BrainArenaEngine();
    });

    test('initializes challenges and zero scores', () {
      final state = engine.createInitialState(players);
      expect(state.challenges.length, 5);
      expect(state.currentChallengeIndex, 0);
      expect(state.scores['player_1'], 0);
      expect(state.isFinished, isFalse);
    });

    test('correct answer adds score and advances challenge', () {
      var state = engine.createInitialState(players);
      final currentChallenge = state.currentChallenge!;
      final correctIdx = currentChallenge.correctIndex;

      final action = PlayerAction(
        actionId: 'ba1',
        playerId: 'player_1',
        activityId: 'brain_arena',
        type: 'submit_answer',
        payload: {'optionIndex': correctIdx},
        clientSequence: 1,
      );

      expect(engine.validateAction(state, action), isTrue);
      state = engine.applyAction(state, action);

      expect(state.scores['player_1'], currentChallenge.basePoints);
      expect(state.currentChallengeIndex, 1);
    });
  });
}
