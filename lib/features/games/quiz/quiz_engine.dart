import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'quiz_models.dart';

class QuizEngine implements ActivityEngine<QuizState> {
  static const List<QuizQuestion> curatedQuestions = [
    QuizQuestion(
      id: 'qz_1',
      topic: QuizTopic.bollywood,
      question: 'Which legendary actor portrayed "Gabbar Singh" in Sholay?',
      options: ['Amrish Puri', 'Amjad Khan', 'Danny Denzongpa', 'Prem Chopra'],
      correctIndex: 1,
      explanation:
          'Amjad Khan iconically played the menacing bandit Gabbar Singh in 1975.',
    ),
    QuizQuestion(
      id: 'qz_2',
      topic: QuizTopic.cricket,
      question:
          'Who scored the first double century in Men\'s ODI Cricket history?',
      options: [
        'Rohit Sharma',
        'Virender Sehwag',
        'Sachin Tendulkar',
        'Chris Gayle',
      ],
      correctIndex: 2,
      explanation:
          'Sachin Tendulkar scored 200* against South Africa in Gwalior on 24 Feb 2010.',
    ),
    QuizQuestion(
      id: 'qz_3',
      topic: QuizTopic.scienceTech,
      question: 'What was the first computer virus created for MS-DOS called?',
      options: ['Brain', 'Creeper', 'Melissa', 'ILOVEYOU'],
      correctIndex: 0,
      explanation:
          'The Brain virus was written in 1986 by two brothers in Lahore, Pakistan.',
    ),
    QuizQuestion(
      id: 'qz_4',
      topic: QuizTopic.worldPop,
      question: 'Which artist has won the most Grammy Awards of all time?',
      options: [
        'Michael Jackson',
        'Beyoncé',
        'Stevie Wonder',
        'Paul McCartney',
      ],
      correctIndex: 1,
      explanation: 'Beyoncé holds the record with over 32 Grammy Awards.',
    ),
    QuizQuestion(
      id: 'qz_5',
      topic: QuizTopic.cricket,
      question:
          'In which year did India win its first ICC Men\'s T20 World Cup?',
      options: ['2003', '2007', '2011', '2014'],
      correctIndex: 1,
      explanation:
          'India won the inaugural 2007 ICC World Twenty20 in Johannesburg led by MS Dhoni.',
    ),
  ];

  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'quiz_clash',
    title: 'Quiz Clash',
    description:
        'Fast-paced trivia showdown with speed bonuses, instant reveals, and leaderboards.',
    category: ActivityCategory.brain,
    minPlayers: 1,
    maxPlayers: 8,
    estimatedDuration: Duration(minutes: 6),
    rules:
        '1. 15 seconds per question.\n2. Faster correct answers get higher speed multipliers.\n3. Highest cumulative score wins.',
  );

  @override
  QuizState createInitialState(List<String> playerIds) {
    return QuizState(
      version: 1,
      playerIds: playerIds,
      questions: curatedQuestions,
      currentQuestionIndex: 0,
      answersForCurrent: {},
      scores: {for (final id in playerIds) id: 0},
      phase: QuizRoundPhase.answering,
      isFinished: false,
    );
  }

  @override
  bool validateAction(QuizState state, PlayerAction action) {
    if (state.isFinished) return false;
    if (!state.playerIds.contains(action.playerId)) return false;

    switch (action.type) {
      case 'answer_question':
        if (state.phase != QuizRoundPhase.answering) return false;
        final optionIndex = action.payload['optionIndex'] as int?;
        return optionIndex != null && optionIndex >= 0 && optionIndex < 4;
      case 'reveal_round':
        return state.phase == QuizRoundPhase.answering;
      case 'next_question':
        return state.phase == QuizRoundPhase.reveal;
      default:
        return false;
    }
  }

  @override
  QuizState applyAction(QuizState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    switch (action.type) {
      case 'answer_question':
        final optionIndex = action.payload['optionIndex'] as int;
        final timeTaken =
            (action.payload['timeTakenMs'] as num?)?.toInt() ?? 5000;
        final currentQ = state.currentQuestion;
        if (currentQ == null) return state;

        final isCorrect = optionIndex == currentQ.correctIndex;
        int points = 0;
        if (isCorrect) {
          final speedFactor = ((15000 - timeTaken).clamp(0, 15000) / 15000);
          final speedBonus = (speedFactor * 50).round();
          points = 100 + speedBonus;
        }

        final record = QuizAnswerRecord(
          playerId: action.playerId,
          chosenIndex: optionIndex,
          timeTakenMs: timeTaken,
          pointsEarned: points,
        );

        final updatedAnswers = Map<String, QuizAnswerRecord>.from(
          state.answersForCurrent,
        );
        updatedAnswers[action.playerId] = record;

        final updatedScores = Map<String, int>.from(state.scores);
        updatedScores[action.playerId] =
            (updatedScores[action.playerId] ?? 0) + points;

        final allAnswered = updatedAnswers.length >= state.playerIds.length;

        return state.copyWith(
          version: state.version + 1,
          answersForCurrent: updatedAnswers,
          scores: updatedScores,
          phase: allAnswered ? QuizRoundPhase.reveal : state.phase,
        );

      case 'reveal_round':
        return state.copyWith(
          version: state.version + 1,
          phase: QuizRoundPhase.reveal,
        );

      case 'next_question':
        final nextIndex = state.currentQuestionIndex + 1;
        if (nextIndex >= state.questions.length) {
          return state.copyWith(
            version: state.version + 1,
            phase: QuizRoundPhase.finished,
            isFinished: true,
          );
        }

        return state.copyWith(
          version: state.version + 1,
          currentQuestionIndex: nextIndex,
          answersForCurrent: {},
          phase: QuizRoundPhase.answering,
        );

      default:
        return state;
    }
  }

  @override
  String? getCurrentTurnPlayerId(QuizState state) => null;

  @override
  bool isFinished(QuizState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(QuizState state) {
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
      'winningScore': maxScore,
      'scores': state.scores,
      'totalQuestions': state.questions.length,
    };
  }

  @override
  String serialize(QuizState state) => state.toJson();

  @override
  QuizState deserialize(String raw) => QuizState.fromJson(raw);
}
