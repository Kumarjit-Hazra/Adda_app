import 'dart:convert';

enum CoupleCategory { fun, memory, intimacy, future }

class CoupleQuestion {
  final String id;
  final CoupleCategory category;
  final String prompt;
  final List<String>
  options; // Options if choice-based, or empty for open thought
  final String deepPrompt;

  const CoupleQuestion({
    required this.id,
    required this.category,
    required this.prompt,
    required this.options,
    required this.deepPrompt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category.name,
    'prompt': prompt,
    'options': options,
    'deepPrompt': deepPrompt,
  };

  factory CoupleQuestion.fromMap(Map<String, dynamic> map) => CoupleQuestion(
    id: map['id'] as String,
    category: CoupleCategory.values.firstWhere(
      (c) => c.name == map['category'],
      orElse: () => CoupleCategory.fun,
    ),
    prompt: map['prompt'] as String,
    options: (map['options'] as List<dynamic>).cast<String>(),
    deepPrompt: map['deepPrompt'] as String? ?? '',
  );
}

class CoupleModeState {
  final int version;
  final List<String> playerIds;
  final List<CoupleQuestion> questions;
  final int currentQuestionIndex;
  final Map<String, String> currentAnswers; // playerId -> answer
  final bool answersRevealed;
  final Map<String, int> scores;
  final int intimacyMeter; // 0 - 100%
  final bool isFinished;

  const CoupleModeState({
    required this.version,
    required this.playerIds,
    required this.questions,
    required this.currentQuestionIndex,
    required this.currentAnswers,
    required this.answersRevealed,
    required this.scores,
    required this.intimacyMeter,
    this.isFinished = false,
  });

  CoupleQuestion? get currentQuestion => currentQuestionIndex < questions.length
      ? questions[currentQuestionIndex]
      : null;

  CoupleModeState copyWith({
    int? version,
    List<String>? playerIds,
    List<CoupleQuestion>? questions,
    int? currentQuestionIndex,
    Map<String, String>? currentAnswers,
    bool? answersRevealed,
    Map<String, int>? scores,
    int? intimacyMeter,
    bool? isFinished,
  }) {
    return CoupleModeState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      answersRevealed: answersRevealed ?? this.answersRevealed,
      scores: scores ?? this.scores,
      intimacyMeter: intimacyMeter ?? this.intimacyMeter,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'questions': questions.map((q) => q.toMap()).toList(),
    'currentQuestionIndex': currentQuestionIndex,
    'currentAnswers': currentAnswers,
    'answersRevealed': answersRevealed,
    'scores': scores,
    'intimacyMeter': intimacyMeter,
    'isFinished': isFinished,
  };

  factory CoupleModeState.fromMap(Map<String, dynamic> map) => CoupleModeState(
    version: map['version'] as int,
    playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
    questions: (map['questions'] as List<dynamic>)
        .map((q) => CoupleQuestion.fromMap(q as Map<String, dynamic>))
        .toList(),
    currentQuestionIndex: map['currentQuestionIndex'] as int,
    currentAnswers: (map['currentAnswers'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    ),
    answersRevealed: map['answersRevealed'] as bool? ?? false,
    scores: (map['scores'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    intimacyMeter: (map['intimacyMeter'] as num?)?.toInt() ?? 50,
    isFinished: map['isFinished'] as bool? ?? false,
  );

  String toJson() => json.encode(toMap());

  factory CoupleModeState.fromJson(String source) =>
      CoupleModeState.fromMap(json.decode(source) as Map<String, dynamic>);
}
