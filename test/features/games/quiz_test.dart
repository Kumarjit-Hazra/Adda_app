import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/quiz/quiz_engine.dart';
import 'package:adda/features/games/quiz/quiz_models.dart';

void main() {
  group('QuizEngine Unit Tests', () {
    late QuizEngine engine;
    final players = ['player_1', 'player_2'];

    setUp(() {
      engine = QuizEngine();
    });

    test('initializes with questions and answering phase', () {
      final state = engine.createInitialState(players);
      expect(state.questions.length, greaterThan(0));
      expect(state.phase, QuizRoundPhase.answering);
      expect(state.currentQuestionIndex, 0);
    });

    test('correct answer adds base and speed bonus points', () {
      var state = engine.createInitialState(players);
      final currentQ = state.currentQuestion!;

      final action = PlayerAction(
        actionId: 'qz1',
        playerId: 'player_1',
        activityId: 'quiz_clash',
        type: 'answer_question',
        payload: {'optionIndex': currentQ.correctIndex, 'timeTakenMs': 3000},
        clientSequence: 1,
      );

      expect(engine.validateAction(state, action), isTrue);
      state = engine.applyAction(state, action);

      expect(state.scores['player_1']!, greaterThanOrEqualTo(100));
      expect(state.answersForCurrent.containsKey('player_1'), isTrue);
    });
  });
}
