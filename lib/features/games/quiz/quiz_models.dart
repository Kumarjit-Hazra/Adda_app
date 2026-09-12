import 'dart:convert';

enum QuizTopic { bollywood, cricket, worldPop, scienceTech }

class QuizQuestion {
  final String id;
  final QuizTopic topic;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'topic': topic.name,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
  };

  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
    id: map['id'] as String,
    topic: QuizTopic.values.firstWhere(
      (t) => t.name == map['topic'],
      orElse: () => QuizTopic.worldPop,
    ),
    question: map['question'] as String,
    options: (map['options'] as List<dynamic>).cast<String>(),
    correctIndex: map['correctIndex'] as int,
    explanation: map['explanation'] as String? ?? '',
  );
}

class QuizAnswerRecord {
  final String playerId;
  final int chosenIndex;
  final int timeTakenMs;
  final int pointsEarned;

  const QuizAnswerRecord({
    required this.playerId,
    required this.chosenIndex,
    required this.timeTakenMs,
    required this.pointsEarned,
  });

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'chosenIndex': chosenIndex,
    'timeTakenMs': timeTakenMs,
    'pointsEarned': pointsEarned,
  };

  factory QuizAnswerRecord.fromMap(Map<String, dynamic> map) =>
      QuizAnswerRecord(
        playerId: map['playerId'] as String,
        chosenIndex: map['chosenIndex'] as int,
        timeTakenMs: map['timeTakenMs'] as int,
        pointsEarned: map['pointsEarned'] as int,
      );
}

enum QuizRoundPhase { answering, reveal, finished }

class QuizState {
  final int version;
  final List<String> playerIds;
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final Map<String, QuizAnswerRecord> answersForCurrent;
  final Map<String, int> scores;
  final QuizRoundPhase phase;
  final bool isFinished;

  const QuizState({
    required this.version,
    required this.playerIds,
    required this.questions,
    required this.currentQuestionIndex,
    required this.answersForCurrent,
    required this.scores,
    required this.phase,
    this.isFinished = false,
  });

  QuizQuestion? get currentQuestion => currentQuestionIndex < questions.length
      ? questions[currentQuestionIndex]
      : null;

  QuizState copyWith({
    int? version,
    List<String>? playerIds,
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    Map<String, QuizAnswerRecord>? answersForCurrent,
    Map<String, int>? scores,
    QuizRoundPhase? phase,
    bool? isFinished,
  }) {
    return QuizState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answersForCurrent: answersForCurrent ?? this.answersForCurrent,
      scores: scores ?? this.scores,
      phase: phase ?? this.phase,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'questions': questions.map((q) => q.toMap()).toList(),
    'currentQuestionIndex': currentQuestionIndex,
    'answersForCurrent': answersForCurrent.map(
      (k, v) => MapEntry(k, v.toMap()),
    ),
    'scores': scores,
    'phase': phase.name,
    'isFinished': isFinished,
  };

  factory QuizState.fromMap(Map<String, dynamic> map) => QuizState(
    version: map['version'] as int,
    playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
    questions: (map['questions'] as List<dynamic>)
        .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
        .toList(),
    currentQuestionIndex: map['currentQuestionIndex'] as int,
    answersForCurrent: (map['answersForCurrent'] as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, QuizAnswerRecord.fromMap(v as Map<String, dynamic>)),
    ),
    scores: (map['scores'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    phase: QuizRoundPhase.values.firstWhere(
      (p) => p.name == map['phase'],
      orElse: () => QuizRoundPhase.answering,
    ),
    isFinished: map['isFinished'] as bool? ?? false,
  );

  String toJson() => json.encode(toMap());

  factory QuizState.fromJson(String source) =>
      QuizState.fromMap(json.decode(source) as Map<String, dynamic>);
}
