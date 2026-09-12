import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/couple_mode/couple_mode_engine.dart';

void main() {
  group('CoupleModeEngine Unit Tests', () {
    late CoupleModeEngine engine;
    final players = ['partner_a', 'partner_b'];

    setUp(() {
      engine = engine = CoupleModeEngine();
    });

    test('initializes with intimacy meter and questions', () {
      final state = engine.createInitialState(players);
      expect(state.questions.isNotEmpty, isTrue);
      expect(state.currentQuestionIndex, 0);
      expect(state.intimacyMeter, 50);
      expect(state.isFinished, isFalse);
    });

    test('submitting answers advances intimacy meter on reveal', () {
      var state = engine.createInitialState(players);

      final actionA = PlayerAction(
        actionId: 'c1',
        playerId: 'partner_a',
        activityId: 'couple_mode',
        type: 'submit_answer',
        payload: {'answer': 'Me definitely'},
        clientSequence: 1,
      );

      final actionB = PlayerAction(
        actionId: 'c2',
        playerId: 'partner_b',
        activityId: 'couple_mode',
        type: 'submit_answer',
        payload: {'answer': 'Me definitely'},
        clientSequence: 2,
      );

      state = engine.applyAction(state, actionA);
      expect(state.currentAnswers['partner_a'], 'Me definitely');

      state = engine.applyAction(state, actionB);
      expect(state.currentAnswers['partner_b'], 'Me definitely');
      expect(state.answersRevealed, isTrue);

      final nextAction = PlayerAction(
        actionId: 'c3',
        playerId: 'partner_a',
        activityId: 'couple_mode',
        type: 'next_question',
        payload: {},
        clientSequence: 3,
      );

      state = engine.applyAction(state, nextAction);
      expect(state.currentQuestionIndex, 1);
      expect(state.currentAnswers.isEmpty, isTrue);
    });
  });
}
