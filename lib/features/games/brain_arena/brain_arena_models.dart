import 'dart:convert';

enum BrainCategory { speedMath, patternLogic, quickObservation, vocabulary }

class BrainChallenge {
  final String id;
  final BrainCategory category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final int basePoints;

  const BrainChallenge({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.basePoints = 100,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category.name,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'basePoints': basePoints,
  };

  factory BrainChallenge.fromMap(Map<String, dynamic> map) => BrainChallenge(
    id: map['id'] as String,
    category: BrainCategory.values.firstWhere((c) => c.name == map['category']),
    question: map['question'] as String,
    options: (map['options'] as List<dynamic>).cast<String>(),
    correctIndex: map['correctIndex'] as int,
    basePoints: map['basePoints'] as int? ?? 100,
  );
}

class BrainArenaState {
  final int version;
  final List<String> playerIds;
  final List<BrainChallenge> challenges;
  final int currentChallengeIndex;
  final Map<String, int> scores;
  final Map<String, int> answersForCurrent; // playerId -> chosenIndex
  final bool isFinished;

  const BrainArenaState({
    required this.version,
    required this.playerIds,
    required this.challenges,
    required this.currentChallengeIndex,
    required this.scores,
    required this.answersForCurrent,
    this.isFinished = false,
  });

  BrainChallenge? get currentChallenge =>
      currentChallengeIndex < challenges.length
      ? challenges[currentChallengeIndex]
      : null;

  BrainArenaState copyWith({
    int? version,
    List<String>? playerIds,
    List<BrainChallenge>? challenges,
    int? currentChallengeIndex,
    Map<String, int>? scores,
    Map<String, int>? answersForCurrent,
    bool? isFinished,
  }) {
    return BrainArenaState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      challenges: challenges ?? this.challenges,
      currentChallengeIndex:
          currentChallengeIndex ?? this.currentChallengeIndex,
      scores: scores ?? this.scores,
      answersForCurrent: answersForCurrent ?? this.answersForCurrent,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'playerIds': playerIds,
      'challenges': challenges.map((c) => c.toMap()).toList(),
      'currentChallengeIndex': currentChallengeIndex,
      'scores': scores,
      'answersForCurrent': answersForCurrent,
      'isFinished': isFinished,
    };
  }

  factory BrainArenaState.fromMap(Map<String, dynamic> map) {
    return BrainArenaState(
      version: map['version'] as int,
      playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
      challenges: (map['challenges'] as List<dynamic>)
          .map((c) => BrainChallenge.fromMap(c as Map<String, dynamic>))
          .toList(),
      currentChallengeIndex: map['currentChallengeIndex'] as int,
      scores: (map['scores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      answersForCurrent: (map['answersForCurrent'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      isFinished: map['isFinished'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory BrainArenaState.fromJson(String source) =>
      BrainArenaState.fromMap(json.decode(source) as Map<String, dynamic>);
}
