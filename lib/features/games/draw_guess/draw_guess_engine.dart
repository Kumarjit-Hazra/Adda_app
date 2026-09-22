import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'draw_guess_models.dart';

class DrawGuessEngine implements ActivityEngine<DrawGuessState> {
  static const List<String> wordBank = [
    'Elephant',
    'Chai',
    'Guitar',
    'Pizza',
    'Rocket',
    'Airplane',
    'Rainbow',
    'Bicycle',
    'Sunset',
    'Robot',
    'Tiger',
    'Castle',
    'Headphones',
    'Pineapple',
  ];

  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'draw_guess',
    title: 'Draw & Guess',
    description:
        'Real-time collaborative canvas. One draws secret prompt, others race to guess.',
    category: ActivityCategory.creative,
    minPlayers: 2,
    maxPlayers: 8,
    estimatedDuration: Duration(minutes: 8),
    rules:
        '1. Current drawer sketches the prompt.\n2. Guessers type answers in chat.\n3. First to guess correctly scores 100 pts, drawer gets 50 pts.',
  );

  @override
  DrawGuessState createInitialState(List<String> playerIds) {
    final drawer = playerIds.isNotEmpty ? playerIds.first : 'player_1';
    final initialWord = wordBank.first;

    return DrawGuessState(
      version: 1,
      playerIds: playerIds,
      currentDrawerId: drawer,
      currentWord: initialWord,
      points: [],
      guesses: [],
      scores: {for (final id in playerIds) id: 0},
      currentRound: 1,
      totalRounds: playerIds.length > 2 ? playerIds.length * 2 : 4,
      roundSolved: false,
      isFinished: false,
    );
  }

  @override
  bool validateAction(DrawGuessState state, PlayerAction action) {
    if (state.isFinished) return false;
    if (!state.playerIds.contains(action.playerId)) return false;

    switch (action.type) {
      case 'add_point':
      case 'clear_canvas':
        return action.playerId == state.currentDrawerId;
      case 'submit_guess':
        if (action.playerId == state.currentDrawerId) return false;
        final guess = action.payload['guess'] as String?;
        return guess != null && guess.trim().isNotEmpty;
      case 'next_round':
        return state.roundSolved || state.points.isEmpty;
      default:
        return false;
    }
  }

  @override
  DrawGuessState applyAction(DrawGuessState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    switch (action.type) {
      case 'add_point':
        final point = DrawPoint.fromMap(action.payload);
        return state.copyWith(
          version: state.version + 1,
          points: [...state.points, point],
        );

      case 'clear_canvas':
        return state.copyWith(version: state.version + 1, points: []);

      case 'submit_guess':
        final guessText = (action.payload['guess'] as String).trim();
        final isCorrect =
            guessText.toLowerCase() == state.currentWord.toLowerCase();

        final newAttempt = GuessAttempt(
          playerId: action.playerId,
          text: guessText,
          isCorrect: isCorrect,
          timestamp: DateTime.now(),
        );

        final updatedScores = Map<String, int>.from(state.scores);
        if (isCorrect && !state.roundSolved) {
          updatedScores[action.playerId] =
              (updatedScores[action.playerId] ?? 0) + 100;
          updatedScores[state.currentDrawerId] =
              (updatedScores[state.currentDrawerId] ?? 0) + 50;
        }

        return state.copyWith(
          version: state.version + 1,
          guesses: [...state.guesses, newAttempt],
          scores: updatedScores,
          roundSolved: isCorrect ? true : state.roundSolved,
        );

      case 'next_round':
        final nextRoundNum = state.currentRound + 1;
        if (nextRoundNum > state.totalRounds) {
          return state.copyWith(version: state.version + 1, isFinished: true);
        }

        // Rotate drawer
        final currentIdx = state.playerIds.indexOf(state.currentDrawerId);
        final nextDrawer =
            state.playerIds[(currentIdx + 1) % state.playerIds.length];
        final nextWord = wordBank[(nextRoundNum - 1) % wordBank.length];

        return state.copyWith(
          version: state.version + 1,
          currentRound: nextRoundNum,
          currentDrawerId: nextDrawer,
          currentWord: nextWord,
          points: [],
          roundSolved: false,
        );

      default:
        return state;
    }
  }

  @override
  String? getCurrentTurnPlayerId(DrawGuessState state) => null;

  @override
  bool isFinished(DrawGuessState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(DrawGuessState state) {
    String? winnerId;
    int maxScore = -1;
    state.scores.forEach((id, score) {
      if (score > maxScore) {
        maxScore = score;
        winnerId = id;
      }
    });

    return {
      'winnerId': winnerId,
      'highestScore': maxScore,
      'scores': state.scores,
      'roundsCompleted': state.currentRound,
    };
  }

  @override
  String serialize(DrawGuessState state) => state.toJson();

  @override
  DrawGuessState deserialize(String raw) => DrawGuessState.fromJson(raw);
}
