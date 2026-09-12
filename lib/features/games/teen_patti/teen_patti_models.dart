import 'dart:convert';

enum CardSuit { spades, hearts, diamonds, clubs }

class TeenPattiCard {
  final CardSuit suit;
  final int rank; // 2..14 (14 = Ace)

  const TeenPattiCard({required this.suit, required this.rank});

  String get rankString {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      case 10:
        return '10';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case CardSuit.spades:
        return '♠';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
    }
  }

  bool get isRed => suit == CardSuit.hearts || suit == CardSuit.diamonds;

  Map<String, dynamic> toMap() => {'suit': suit.name, 'rank': rank};

  factory TeenPattiCard.fromMap(Map<String, dynamic> map) => TeenPattiCard(
    suit: CardSuit.values.firstWhere((s) => s.name == map['suit']),
    rank: map['rank'] as int,
  );
}

enum HandRankType { highCard, pair, color, sequence, pureSequence, trail }

class HandEvaluation {
  final HandRankType type;
  final int score;
  final String description;

  const HandEvaluation({
    required this.type,
    required this.score,
    required this.description,
  });
}

class HandEvaluator {
  static HandEvaluation evaluate(List<TeenPattiCard> cards) {
    if (cards.length < 3) {
      return const HandEvaluation(
        type: HandRankType.highCard,
        score: 0,
        description: 'Incomplete',
      );
    }

    final sorted = List<TeenPattiCard>.from(cards)
      ..sort((a, b) => b.rank.compareTo(a.rank));

    final r1 = sorted[0].rank;
    final r2 = sorted[1].rank;
    final r3 = sorted[2].rank;
    final isSameSuit =
        sorted[0].suit == sorted[1].suit && sorted[1].suit == sorted[2].suit;

    // 1. Trail / Trio (Three of a kind)
    if (r1 == r2 && r2 == r3) {
      return HandEvaluation(
        type: HandRankType.trail,
        score: 60000 + r1,
        description: 'Trail of ${sorted[0].rankString}s',
      );
    }

    // Check sequence (A-2-3 is also valid sequence where A is 14 or low)
    bool isSeq = false;
    int seqHigh = r1;
    if (r1 == r2 + 1 && r2 == r3 + 1) {
      isSeq = true;
      seqHigh = r1;
    } else if (r1 == 14 && r2 == 3 && r3 == 2) {
      // A-3-2 run
      isSeq = true;
      seqHigh = 3;
    }

    // 2. Pure Sequence (Straight Flush)
    if (isSameSuit && isSeq) {
      return HandEvaluation(
        type: HandRankType.pureSequence,
        score: 50000 + seqHigh,
        description: 'Pure Sequence high $seqHigh',
      );
    }

    // 3. Normal Sequence (Straight)
    if (isSeq) {
      return HandEvaluation(
        type: HandRankType.sequence,
        score: 40000 + seqHigh,
        description: 'Sequence high $seqHigh',
      );
    }

    // 4. Color (Flush)
    if (isSameSuit) {
      return HandEvaluation(
        type: HandRankType.color,
        score: 30000 + (r1 * 100) + (r2 * 10) + r3,
        description: 'Color Flush ${sorted[0].suitSymbol}',
      );
    }

    // 5. Pair
    if (r1 == r2 || r2 == r3 || r1 == r3) {
      final pairRank = (r1 == r2) ? r1 : (r2 == r3 ? r2 : r1);
      final kicker = (r1 == r2) ? r3 : (r2 == r3 ? r1 : r2);
      return HandEvaluation(
        type: HandRankType.pair,
        score: 20000 + (pairRank * 100) + kicker,
        description: 'Pair of ${sorted[0].rankString}s',
      );
    }

    // 6. High Card
    return HandEvaluation(
      type: HandRankType.highCard,
      score: 10000 + (r1 * 100) + (r2 * 10) + r3,
      description: 'High Card ${sorted[0].rankString}',
    );
  }
}

class TeenPattiPlayer {
  final String id;
  final int chips;
  final int currentBet;
  final List<TeenPattiCard> cards;
  final bool isFolded;
  final bool hasSeenCards;

  const TeenPattiPlayer({
    required this.id,
    required this.chips,
    required this.currentBet,
    required this.cards,
    required this.isFolded,
    required this.hasSeenCards,
  });

  TeenPattiPlayer copyWith({
    String? id,
    int? chips,
    int? currentBet,
    List<TeenPattiCard>? cards,
    bool? isFolded,
    bool? hasSeenCards,
  }) {
    return TeenPattiPlayer(
      id: id ?? this.id,
      chips: chips ?? this.chips,
      currentBet: currentBet ?? this.currentBet,
      cards: cards ?? this.cards,
      isFolded: isFolded ?? this.isFolded,
      hasSeenCards: hasSeenCards ?? this.hasSeenCards,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'chips': chips,
    'currentBet': currentBet,
    'cards': cards.map((c) => c.toMap()).toList(),
    'isFolded': isFolded,
    'hasSeenCards': hasSeenCards,
  };

  factory TeenPattiPlayer.fromMap(Map<String, dynamic> map) => TeenPattiPlayer(
    id: map['id'] as String,
    chips: map['chips'] as int,
    currentBet: map['currentBet'] as int,
    cards: (map['cards'] as List<dynamic>)
        .map((c) => TeenPattiCard.fromMap(c as Map<String, dynamic>))
        .toList(),
    isFolded: map['isFolded'] as bool? ?? false,
    hasSeenCards: map['hasSeenCards'] as bool? ?? false,
  );
}

class TeenPattiState {
  final int version;
  final List<String> playerIds;
  final Map<String, TeenPattiPlayer> players;
  final int pot;
  final int currentMinChaal;
  final int currentTurnIndex;
  final bool roundOver;
  final String? winnerId;
  final String? winningHandDescription;
  final bool isFinished;

  const TeenPattiState({
    required this.version,
    required this.playerIds,
    required this.players,
    required this.pot,
    required this.currentMinChaal,
    required this.currentTurnIndex,
    required this.roundOver,
    this.winnerId,
    this.winningHandDescription,
    this.isFinished = false,
  });

  String get currentTurnPlayerId => playerIds[currentTurnIndex];

  List<TeenPattiPlayer> get activePlayers =>
      players.values.where((p) => !p.isFolded).toList();

  TeenPattiState copyWith({
    int? version,
    List<String>? playerIds,
    Map<String, TeenPattiPlayer>? players,
    int? pot,
    int? currentMinChaal,
    int? currentTurnIndex,
    bool? roundOver,
    String? winnerId,
    String? winningHandDescription,
    bool? isFinished,
  }) {
    return TeenPattiState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      players: players ?? this.players,
      pot: pot ?? this.pot,
      currentMinChaal: currentMinChaal ?? this.currentMinChaal,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      roundOver: roundOver ?? this.roundOver,
      winnerId: winnerId ?? this.winnerId,
      winningHandDescription:
          winningHandDescription ?? this.winningHandDescription,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'players': players.map((k, v) => MapEntry(k, v.toMap())),
    'pot': pot,
    'currentMinChaal': currentMinChaal,
    'currentTurnIndex': currentTurnIndex,
    'roundOver': roundOver,
    'winnerId': winnerId,
    'winningHandDescription': winningHandDescription,
    'isFinished': isFinished,
  };

  factory TeenPattiState.fromMap(Map<String, dynamic> map) => TeenPattiState(
    version: map['version'] as int,
    playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
    players: (map['players'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, TeenPattiPlayer.fromMap(v as Map<String, dynamic>)),
    ),
    pot: map['pot'] as int,
    currentMinChaal: map['currentMinChaal'] as int,
    currentTurnIndex: map['currentTurnIndex'] as int,
    roundOver: map['roundOver'] as bool? ?? false,
    winnerId: map['winnerId'] as String?,
    winningHandDescription: map['winningHandDescription'] as String?,
    isFinished: map['isFinished'] as bool? ?? false,
  );

  String toJson() => json.encode(toMap());

  factory TeenPattiState.fromJson(String source) =>
      TeenPattiState.fromMap(json.decode(source) as Map<String, dynamic>);
}
