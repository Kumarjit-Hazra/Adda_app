import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'brain_arena_models.dart';

class BrainArenaEngine implements ActivityEngine<BrainArenaState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'brain_arena',
    title: 'Brain Arena',
    description:
        'Rapid-fire mental agility clashes: speed math, pattern logic, and quick observations.',
    category: ActivityCategory.brain,
    minPlayers: 1,
    maxPlayers: 8,
    estimatedDuration: Duration(minutes: 5),
    rules: '''
1. Answer each round as quickly as possible.
2. Correct answers earn base points + speed bonus.
3. Compete in math, logic, patterns, and vocabulary.
4. Highest total score at the end wins the Arena!
''',
  );

  List<BrainChallenge> _getChallengePool() {
    return const [
      BrainChallenge(
        id: 'c1',
        category: BrainCategory.speedMath,
        question: '74 + 68 = ?',
        options: ['132', '142', '144', '152'],
        correctIndex: 1,
      ),
      BrainChallenge(
        id: 'c2',
        category: BrainCategory.patternLogic,
        question: 'Complete the sequence: 3, 6, 12, 24, ?',
        options: ['36', '42', '48', '52'],
        correctIndex: 2,
      ),
      BrainChallenge(
        id: 'c3',
        category: BrainCategory.speedMath,
        question: '15 x 6 - 25 = ?',
        options: ['55', '65', '75', '85'],
        correctIndex: 1,
      ),
      BrainChallenge(
        id: 'c4',
        category: BrainCategory.quickObservation,
        question:
            'If all Blomps are Glomps, and no Glomps are Zorps, are any Blomps Zorps?',
        options: ['Yes, always', 'Never', 'Only sometimes', 'Cannot determine'],
        correctIndex: 1,
      ),
      BrainChallenge(
        id: 'c5',
        category: BrainCategory.vocabulary,
        question: 'Which word is the closest synonym for "Ephemeral"?',
        options: ['Eternal', 'Fleeting', 'Subtle', 'Radiant'],
        correctIndex: 1,
      ),
    ];
  }

  @override
  BrainArenaState createInitialState(List<String> playerIds) {
    final actual = List<String>.from(playerIds);
    if (actual.isEmpty) actual.add('player_1');

    final scores = {for (var p in actual) p: 0};

    return BrainArenaState(
      version: 1,
      playerIds: actual,
      challenges: _getChallengePool(),
      currentChallengeIndex: 0,
      scores: scores,
      answersForCurrent: {},
      isFinished: false,
    );
  }

  @override
  bool validateAction(BrainArenaState state, PlayerAction action) {
    if (state.isFinished) return false;
    if (action.type != 'submit_answer') return false;
    if (!state.playerIds.contains(action.playerId)) return false;
    final chosen = action.payload['optionIndex'] as int?;
    return chosen != null && chosen >= 0 && chosen <= 3;
  }

  @override
  BrainArenaState applyAction(BrainArenaState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    final chosen = action.payload['optionIndex'] as int;
    final currentChallenge = state.currentChallenge;
    if (currentChallenge == null) return state;

    final isCorrect = chosen == currentChallenge.correctIndex;
    final points = isCorrect ? currentChallenge.basePoints : 0;

    final newScores = Map<String, int>.from(state.scores);
    newScores[action.playerId] = (newScores[action.playerId] ?? 0) + points;

    final newAnswers = Map<String, int>.from(state.answersForCurrent);
    newAnswers[action.playerId] = chosen;

    // Advance to next challenge when all players have answered or after this answer
    final nextIndex = state.currentChallengeIndex + 1;
    final isDone = nextIndex >= state.challenges.length;

    return state.copyWith(
      version: state.version + 1,
      scores: newScores,
      answersForCurrent: {},
      currentChallengeIndex: nextIndex,
      isFinished: isDone,
    );
  }

  @override
  String? getCurrentTurnPlayerId(BrainArenaState state) => null;

  @override
  bool isFinished(BrainArenaState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(BrainArenaState state) => {
    'scores': state.scores,
  };

  @override
  String serialize(BrainArenaState state) => state.toJson();

  @override
  BrainArenaState deserialize(String raw) => BrainArenaState.fromJson(raw);
}
