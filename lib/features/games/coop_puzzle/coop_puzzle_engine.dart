import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'coop_puzzle_models.dart';

class CoopPuzzleEngine implements ActivityEngine<CoopPuzzleState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'coop_puzzle',
    title: 'The Vault: Asymmetric Mystery',
    description:
        'Cooperative asymmetric deduction. Each player has secret clues — communicate over voice to deduce the code.',
    category: ActivityCategory.mystery,
    minPlayers: 2,
    maxPlayers: 4,
    estimatedDuration: Duration(minutes: 8),
    rules: '''
1. The squad has 3 minutes to crack the 4-digit safe code.
2. Every player sees distinct secret clues on their screen.
3. Talk over voice to combine clues and find the only matching code.
4. Input digits into the keypad to unlock the vault!
''',
  );

  @override
  CoopPuzzleState createInitialState(List<String> playerIds) {
    final actual = List<String>.from(playerIds);
    while (actual.length < 2) {
      actual.add('friend_companion');
    }

    // Code: "6 3 7 5"
    // P1 clues: Digits: D1 = 2 * D2. D4 is an odd number.
    // P2 clues: D2 > 2. D3 is 7.
    // P3 clues: Sum of all 4 digits is 21. No digits repeat.
    // P4 clues: D4 > 3. All digits are between 1 and 9.
    final clues = <String, List<String>>{};
    clues[actual[0]] = [
      '🔍 CLUE 1: The 1st digit is exactly TWICE the 2nd digit.',
      '🔍 CLUE 2: The 4th (last) digit is an ODD number.',
    ];
    clues[actual[1]] = [
      '🔍 CLUE 1: The 2nd digit is greater than 2.',
      '🔍 CLUE 2: The 3rd digit is 7.',
    ];
    if (actual.length > 2) {
      clues[actual[2]] = [
        '🔍 CLUE 1: The sum of all four digits is exactly 21.',
        '🔍 CLUE 2: No digit repeats in the code.',
      ];
    }
    if (actual.length > 3) {
      clues[actual[3]] = [
        '🔍 CLUE 1: The 4th digit is greater than 3.',
        '🔍 CLUE 2: The 1st digit is an even number.',
      ];
    }

    return CoopPuzzleState(
      version: 1,
      playerIds: actual,
      correctCode: '6375',
      privateClues: clues,
      enteredCode: '',
      timeRemainingSeconds: 180,
      isSolved: false,
      isFailed: false,
      unlockedHints: [],
    );
  }

  @override
  bool validateAction(CoopPuzzleState state, PlayerAction action) {
    if (state.isSolved || state.isFailed) return false;

    switch (action.type) {
      case 'press_key':
        final key = action.payload['key'] as String?;
        return key != null &&
            (key.length == 1 || key == 'CLEAR' || key == 'ENTER');
      case 'unlock_hint':
        return state.unlockedHints.length < 2;
      default:
        return false;
    }
  }

  @override
  CoopPuzzleState applyAction(CoopPuzzleState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    switch (action.type) {
      case 'press_key':
        final key = action.payload['key'] as String;
        if (key == 'CLEAR') {
          return state.copyWith(version: state.version + 1, enteredCode: '');
        } else if (key == 'ENTER') {
          final isCorrect = state.enteredCode == state.correctCode;
          return state.copyWith(
            version: state.version + 1,
            isSolved: isCorrect,
            isFailed: !isCorrect && state.enteredCode.length == 4,
          );
        } else {
          if (state.enteredCode.length < 4) {
            final next = state.enteredCode + key;
            return state.copyWith(
              version: state.version + 1,
              enteredCode: next,
            );
          }
          return state;
        }

      case 'unlock_hint':
        final hints = List<String>.from(state.unlockedHints)
          ..add(
            'HINT: If D2 > 2 and D1 = 2 * D2, then D2 must be 3 (since D1 must be single digit)!',
          );
        return state.copyWith(version: state.version + 1, unlockedHints: hints);

      default:
        return state;
    }
  }

  @override
  bool isFinished(CoopPuzzleState state) => state.isSolved || state.isFailed;

  @override
  Map<String, dynamic> getResult(CoopPuzzleState state) => {
    'isSolved': state.isSolved,
  };

  @override
  String serialize(CoopPuzzleState state) => state.toJson();

  @override
  CoopPuzzleState deserialize(String raw) => CoopPuzzleState.fromJson(raw);
}
