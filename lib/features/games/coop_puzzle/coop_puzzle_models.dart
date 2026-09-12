import 'dart:convert';

class CoopPuzzleState {
  final int version;
  final List<String> playerIds;
  final String correctCode; // e.g. "6375"
  final Map<String, List<String>> privateClues;
  final String enteredCode;
  final int timeRemainingSeconds;
  final bool isSolved;
  final bool isFailed;
  final List<String> unlockedHints;

  const CoopPuzzleState({
    required this.version,
    required this.playerIds,
    required this.correctCode,
    required this.privateClues,
    required this.enteredCode,
    required this.timeRemainingSeconds,
    this.isSolved = false,
    this.isFailed = false,
    required this.unlockedHints,
  });

  CoopPuzzleState copyWith({
    int? version,
    List<String>? playerIds,
    String? correctCode,
    Map<String, List<String>>? privateClues,
    String? enteredCode,
    int? timeRemainingSeconds,
    bool? isSolved,
    bool? isFailed,
    List<String>? unlockedHints,
  }) {
    return CoopPuzzleState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      correctCode: correctCode ?? this.correctCode,
      privateClues: privateClues ?? this.privateClues,
      enteredCode: enteredCode ?? this.enteredCode,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      isSolved: isSolved ?? this.isSolved,
      isFailed: isFailed ?? this.isFailed,
      unlockedHints: unlockedHints ?? this.unlockedHints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'playerIds': playerIds,
      'correctCode': correctCode,
      'privateClues': privateClues,
      'enteredCode': enteredCode,
      'timeRemainingSeconds': timeRemainingSeconds,
      'isSolved': isSolved,
      'isFailed': isFailed,
      'unlockedHints': unlockedHints,
    };
  }

  factory CoopPuzzleState.fromMap(Map<String, dynamic> map) {
    return CoopPuzzleState(
      version: map['version'] as int,
      playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
      correctCode: map['correctCode'] as String,
      privateClues: (map['privateClues'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
      ),
      enteredCode: map['enteredCode'] as String,
      timeRemainingSeconds: map['timeRemainingSeconds'] as int,
      isSolved: map['isSolved'] as bool? ?? false,
      isFailed: map['isFailed'] as bool? ?? false,
      unlockedHints: (map['unlockedHints'] as List<dynamic>).cast<String>(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CoopPuzzleState.fromJson(String source) =>
      CoopPuzzleState.fromMap(json.decode(source) as Map<String, dynamic>);
}
