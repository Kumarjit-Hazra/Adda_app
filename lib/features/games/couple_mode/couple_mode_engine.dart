import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'couple_mode_models.dart';

class CoupleModeEngine implements ActivityEngine<CoupleModeState> {
  static const List<CoupleQuestion> curatedQuestions = [
    CoupleQuestion(
      id: 'cm_1',
      category: CoupleCategory.fun,
      prompt: 'Who takes longer to get ready before going out?',
      options: [
        'Me definitely',
        'My partner for sure',
        'Equally long',
        'Depends on the event',
      ],
      deepPrompt: 'What is the funniest reason they were ever late?',
    ),
    CoupleQuestion(
      id: 'cm_2',
      category: CoupleCategory.memory,
      prompt: 'What was the exact moment you realized you really liked them?',
      options: [
        'First conversation',
        'When they laughed at my joke',
        'During a late-night call',
        'First time meeting up',
      ],
      deepPrompt: 'Recall that exact atmosphere and tell them.',
    ),
    CoupleQuestion(
      id: 'cm_3',
      category: CoupleCategory.fun,
      prompt:
          'If we could teleport to dinner right now, what cuisine are we having?',
      options: [
        'Street food & Chaat',
        'Italian Pasta & Pizza',
        'Sushi & Asian Bowls',
        'Cozy homemade comfort food',
      ],
      deepPrompt: 'Who orders first and who steals fries from the plate?',
    ),
    CoupleQuestion(
      id: 'cm_4',
      category: CoupleCategory.intimacy,
      prompt:
          'What is their love language when they are having a stressful day?',
      options: [
        'Quiet warm hug',
        'Acts of service & tea',
        'Words of reassurance',
        'Giving them calm space',
      ],
      deepPrompt:
          'Notice how well you tune in to each other\'s subtle signals.',
    ),
    CoupleQuestion(
      id: 'cm_5',
      category: CoupleCategory.future,
      prompt: 'What is our dream getaway destination for our next milestone?',
      options: [
        'Mountains & Bonfire cabin',
        'Tropical beach villa',
        'Bustling historic European city',
        'Road trip with no map',
      ],
      deepPrompt: 'Pack one secret thing to surprise them on the trip.',
    ),
    CoupleQuestion(
      id: 'cm_6',
      category: CoupleCategory.intimacy,
      prompt: 'What habit of mine do you secretly find endearing?',
      options: [
        'My sleepy morning voice',
        'How passionate I get talking about my hobbies',
        'My silly laugh',
        'My nervous habits',
      ],
      deepPrompt: 'Appreciation expressed out loud strengthens trust.',
    ),
  ];

  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'couple_mode',
    title: 'Couple Sanctuary',
    description:
        'Intimate questions, memory sync, and compatibility meter for two.',
    category: ActivityCategory.couple,
    minPlayers: 2,
    maxPlayers: 2,
    estimatedDuration: Duration(minutes: 10),
    rules:
        '1. Both partners answer simultaneously.\n2. Answers reveal only when both submit.\n3. Matches and honest conversations increase the Intimacy Meter.',
  );

  @override
  CoupleModeState createInitialState(List<String> playerIds) {
    return CoupleModeState(
      version: 1,
      playerIds: playerIds,
      questions: curatedQuestions,
      currentQuestionIndex: 0,
      currentAnswers: {},
      answersRevealed: false,
      scores: {for (final id in playerIds) id: 0},
      intimacyMeter: 50,
      isFinished: false,
    );
  }

  @override
  bool validateAction(CoupleModeState state, PlayerAction action) {
    if (state.isFinished) return false;
    if (!state.playerIds.contains(action.playerId)) return false;

    switch (action.type) {
      case 'submit_answer':
        final answer = action.payload['answer'] as String?;
        return answer != null && answer.isNotEmpty;
      case 'reveal_answers':
        return state.currentAnswers.length >= state.playerIds.length;
      case 'next_question':
        return state.answersRevealed;
      default:
        return false;
    }
  }

  @override
  CoupleModeState applyAction(CoupleModeState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    switch (action.type) {
      case 'submit_answer':
        final answer = action.payload['answer'] as String;
        final updatedAnswers = Map<String, String>.from(state.currentAnswers);
        updatedAnswers[action.playerId] = answer;

        final allAnswered = updatedAnswers.length >= state.playerIds.length;

        return state.copyWith(
          version: state.version + 1,
          currentAnswers: updatedAnswers,
          answersRevealed: allAnswered ? true : state.answersRevealed,
          intimacyMeter: allAnswered
              ? (state.intimacyMeter + 5).clamp(0, 100)
              : state.intimacyMeter,
        );

      case 'reveal_answers':
        final answers = state.currentAnswers.values.toList();
        final isMatch = answers.length >= 2 && answers[0] == answers[1];
        final bonus = isMatch ? 10 : 5;

        final updatedScores = Map<String, int>.from(state.scores);
        for (final pid in state.playerIds) {
          updatedScores[pid] = (updatedScores[pid] ?? 0) + (isMatch ? 50 : 25);
        }

        return state.copyWith(
          version: state.version + 1,
          answersRevealed: true,
          scores: updatedScores,
          intimacyMeter: (state.intimacyMeter + bonus).clamp(0, 100),
        );

      case 'next_question':
        final nextIndex = state.currentQuestionIndex + 1;
        final finished = nextIndex >= state.questions.length;

        return state.copyWith(
          version: state.version + 1,
          currentQuestionIndex: nextIndex,
          currentAnswers: {},
          answersRevealed: false,
          isFinished: finished,
        );

      default:
        return state;
    }
  }

  @override
  String? getCurrentTurnPlayerId(CoupleModeState state) => null;

  @override
  bool isFinished(CoupleModeState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(CoupleModeState state) {
    return {
      'intimacyMeter': state.intimacyMeter,
      'scores': state.scores,
      'questionsCompleted': state.currentQuestionIndex,
      'verdict': state.intimacyMeter >= 80
          ? 'Deep Soulmates ✨'
          : state.intimacyMeter >= 60
          ? 'Warm & In Sync 💖'
          : 'Growing Closer Everyday 🌱',
    };
  }

  @override
  String serialize(CoupleModeState state) => state.toJson();

  @override
  CoupleModeState deserialize(String raw) => CoupleModeState.fromJson(raw);
}
