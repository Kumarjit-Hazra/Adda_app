import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/draw_guess/draw_guess_engine.dart';

void main() {
  group('DrawGuessEngine Unit Tests', () {
    late DrawGuessEngine engine;
    final players = ['drawer_1', 'guesser_2'];

    setUp(() {
      engine = DrawGuessEngine();
    });

    test('initializes with drawer, word and rounds', () {
      final state = engine.createInitialState(players);
      expect(state.currentDrawerId, 'drawer_1');
      expect(state.currentWord.isNotEmpty, isTrue);
      expect(state.currentRound, 1);
      expect(state.points.isEmpty, isTrue);
    });

    test('drawer can add points and clear canvas', () {
      var state = engine.createInitialState(players);

      final pointAction = PlayerAction(
        actionId: 'dg1',
        playerId: 'drawer_1',
        activityId: 'draw_guess',
        type: 'add_point',
        payload: {
          'x': 0.5,
          'y': 0.5,
          'color': 0xFFFFFFFF,
          'strokeWidth': 4.0,
          'isStart': true,
        },
        clientSequence: 1,
      );

      expect(engine.validateAction(state, pointAction), isTrue);
      state = engine.applyAction(state, pointAction);
      expect(state.points.length, 1);

      final clearAction = PlayerAction(
        actionId: 'dg2',
        playerId: 'drawer_1',
        activityId: 'draw_guess',
        type: 'clear_canvas',
        payload: {},
        clientSequence: 2,
      );

      state = engine.applyAction(state, clearAction);
      expect(state.points.isEmpty, isTrue);
    });

    test('correct guess awards points to guesser and drawer', () {
      var state = engine.createInitialState(players);
      final word = state.currentWord;

      final guessAction = PlayerAction(
        actionId: 'dg3',
        playerId: 'guesser_2',
        activityId: 'draw_guess',
        type: 'submit_guess',
        payload: {'guess': word},
        clientSequence: 1,
      );

      expect(engine.validateAction(state, guessAction), isTrue);
      state = engine.applyAction(state, guessAction);

      expect(state.roundSolved, isTrue);
      expect(state.scores['guesser_2'], 100);
      expect(state.scores['drawer_1'], 50);
    });
  });
}
