import 'dart:convert';

class DrawPoint {
  final double x; // Normalized 0.0 to 1.0
  final double y; // Normalized 0.0 to 1.0
  final int color;
  final double strokeWidth;
  final bool isStart;

  const DrawPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.strokeWidth,
    required this.isStart,
  });

  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
    'color': color,
    'strokeWidth': strokeWidth,
    'isStart': isStart,
  };

  factory DrawPoint.fromMap(Map<String, dynamic> map) => DrawPoint(
    x: (map['x'] as num).toDouble(),
    y: (map['y'] as num).toDouble(),
    color: map['color'] as int,
    strokeWidth: (map['strokeWidth'] as num).toDouble(),
    isStart: map['isStart'] as bool? ?? false,
  );
}

class GuessAttempt {
  final String playerId;
  final String text;
  final bool isCorrect;
  final DateTime timestamp;

  const GuessAttempt({
    required this.playerId,
    required this.text,
    required this.isCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'text': text,
    'isCorrect': isCorrect,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GuessAttempt.fromMap(Map<String, dynamic> map) => GuessAttempt(
    playerId: map['playerId'] as String,
    text: map['text'] as String,
    isCorrect: map['isCorrect'] as bool? ?? false,
    timestamp:
        DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

class DrawGuessState {
  final int version;
  final List<String> playerIds;
  final String currentDrawerId;
  final String currentWord;
  final List<DrawPoint> points;
  final List<GuessAttempt> guesses;
  final Map<String, int> scores;
  final int currentRound;
  final int totalRounds;
  final bool roundSolved;
  final bool isFinished;

  const DrawGuessState({
    required this.version,
    required this.playerIds,
    required this.currentDrawerId,
    required this.currentWord,
    required this.points,
    required this.guesses,
    required this.scores,
    required this.currentRound,
    required this.totalRounds,
    required this.roundSolved,
    this.isFinished = false,
  });

  String get maskedWord {
    return currentWord
        .split('')
        .map((char) => char == ' ' ? ' ' : '_')
        .join(' ');
  }

  DrawGuessState copyWith({
    int? version,
    List<String>? playerIds,
    String? currentDrawerId,
    String? currentWord,
    List<DrawPoint>? points,
    List<GuessAttempt>? guesses,
    Map<String, int>? scores,
    int? currentRound,
    int? totalRounds,
    bool? roundSolved,
    bool? isFinished,
  }) {
    return DrawGuessState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      currentDrawerId: currentDrawerId ?? this.currentDrawerId,
      currentWord: currentWord ?? this.currentWord,
      points: points ?? this.points,
      guesses: guesses ?? this.guesses,
      scores: scores ?? this.scores,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      roundSolved: roundSolved ?? this.roundSolved,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'currentDrawerId': currentDrawerId,
    'currentWord': currentWord,
    'points': points.map((p) => p.toMap()).toList(),
    'guesses': guesses.map((g) => g.toMap()).toList(),
    'scores': scores,
    'currentRound': currentRound,
    'totalRounds': totalRounds,
    'roundSolved': roundSolved,
    'isFinished': isFinished,
  };

  factory DrawGuessState.fromMap(Map<String, dynamic> map) => DrawGuessState(
    version: map['version'] as int,
    playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
    currentDrawerId: map['currentDrawerId'] as String,
    currentWord: map['currentWord'] as String,
    points: (map['points'] as List<dynamic>)
        .map((p) => DrawPoint.fromMap(p as Map<String, dynamic>))
        .toList(),
    guesses: (map['guesses'] as List<dynamic>)
        .map((g) => GuessAttempt.fromMap(g as Map<String, dynamic>))
        .toList(),
    scores: (map['scores'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    currentRound: map['currentRound'] as int,
    totalRounds: map['totalRounds'] as int,
    roundSolved: map['roundSolved'] as bool? ?? false,
    isFinished: map['isFinished'] as bool? ?? false,
  );

  String toJson() => json.encode(toMap());

  factory DrawGuessState.fromJson(String source) =>
      DrawGuessState.fromMap(json.decode(source) as Map<String, dynamic>);
}
