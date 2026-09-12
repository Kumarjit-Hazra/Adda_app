import 'dart:convert';

enum RummySuit { spades, hearts, diamonds, clubs }

class RummyCard {
  final RummySuit suit;
  final int rank; // 1 = Ace, 2..10, 11 = Jack, 12 = Queen, 13 = King

  const RummyCard({required this.suit, required this.rank});

  String get rankString {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case RummySuit.spades:
        return '♠';
      case RummySuit.hearts:
        return '♥';
      case RummySuit.diamonds:
        return '♦';
      case RummySuit.clubs:
        return '♣';
    }
  }

  bool get isRed => suit == RummySuit.hearts || suit == RummySuit.diamonds;

  Map<String, dynamic> toMap() => {'suit': suit.name, 'rank': rank};

  factory RummyCard.fromMap(Map<String, dynamic> map) => RummyCard(
    suit: RummySuit.values.firstWhere((s) => s.name == map['suit']),
    rank: map['rank'] as int,
  );
}

class RummyValidator {
  static bool isPureSequence(List<RummyCard> cards) {
    if (cards.length < 3) return false;
    final suit = cards[0].suit;
    if (!cards.every((c) => c.suit == suit)) return false;

    final ranks = cards.map((c) => c.rank).toList()..sort();
    // Check sequential
    for (int i = 0; i < ranks.length - 1; i++) {
      if (ranks[i + 1] != ranks[i] + 1) {
        // Special case: A-K-Q run (where A is 1 or 14)
        if (i == ranks.length - 2 && ranks.first == 1 && ranks[i + 1] == 13) {
          continue;
        }
        return false;
      }
    }
    return true;
  }

  static bool isValidSet(List<RummyCard> cards) {
    if (cards.length < 3 || cards.length > 4) return false;
    final rank = cards[0].rank;
    if (!cards.every((c) => c.rank == rank)) return false;

    final suits = cards.map((c) => c.suit).toSet();
    return suits.length == cards.length;
  }

  static bool isValidDeclaration(List<List<RummyCard>> groups) {
    int totalCards = 0;
    int pureSequenceCount = 0;
    int sequenceCount = 0;

    for (final group in groups) {
      totalCards += group.length;
      if (isPureSequence(group)) {
        pureSequenceCount++;
        sequenceCount++;
      } else if (isValidSet(group)) {
        // Set
      } else {
        // Could be impure sequence or invalid
        sequenceCount++;
      }
    }

    return totalCards >= 13 && pureSequenceCount >= 1 && sequenceCount >= 2;
  }
}

class RummyPlayer {
  final String id;
  final List<RummyCard> hand;
  final int score;
  final bool hasDeclared;

  const RummyPlayer({
    required this.id,
    required this.hand,
    required this.score,
    required this.hasDeclared,
  });

  RummyPlayer copyWith({
    String? id,
    List<RummyCard>? hand,
    int? score,
    bool? hasDeclared,
  }) {
    return RummyPlayer(
      id: id ?? this.id,
      hand: hand ?? this.hand,
      score: score ?? this.score,
      hasDeclared: hasDeclared ?? this.hasDeclared,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'hand': hand.map((c) => c.toMap()).toList(),
    'score': score,
    'hasDeclared': hasDeclared,
  };

  factory RummyPlayer.fromMap(Map<String, dynamic> map) => RummyPlayer(
    id: map['id'] as String,
    hand: (map['hand'] as List<dynamic>)
        .map((c) => RummyCard.fromMap(c as Map<String, dynamic>))
        .toList(),
    score: map['score'] as int? ?? 0,
    hasDeclared: map['hasDeclared'] as bool? ?? false,
  );
}

enum RummyTurnStage { draw, discard }

class RummyState {
  final int version;
  final List<String> playerIds;
  final Map<String, RummyPlayer> players;
  final List<RummyCard> openDeck; // Discard pile
  final List<RummyCard> closedDeck; // Draw pile
  final RummyCard wildJoker;
  final int currentTurnIndex;
  final RummyTurnStage turnStage;
  final bool isDeclared;
  final String? winnerId;
  final bool isFinished;

  const RummyState({
    required this.version,
    required this.playerIds,
    required this.players,
    required this.openDeck,
    required this.closedDeck,
    required this.wildJoker,
    required this.currentTurnIndex,
    required this.turnStage,
    required this.isDeclared,
    this.winnerId,
    this.isFinished = false,
  });

  String get currentTurnPlayerId => playerIds[currentTurnIndex];

  RummyState copyWith({
    int? version,
    List<String>? playerIds,
    Map<String, RummyPlayer>? players,
    List<RummyCard>? openDeck,
    List<RummyCard>? closedDeck,
    RummyCard? wildJoker,
    int? currentTurnIndex,
    RummyTurnStage? turnStage,
    bool? isDeclared,
    String? winnerId,
    bool? isFinished,
  }) {
    return RummyState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      players: players ?? this.players,
      openDeck: openDeck ?? this.openDeck,
      closedDeck: closedDeck ?? this.closedDeck,
      wildJoker: wildJoker ?? this.wildJoker,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      turnStage: turnStage ?? this.turnStage,
      isDeclared: isDeclared ?? this.isDeclared,
      winnerId: winnerId ?? this.winnerId,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'players': players.map((k, v) => MapEntry(k, v.toMap())),
    'openDeck': openDeck.map((c) => c.toMap()).toList(),
    'closedDeck': closedDeck.map((c) => c.toMap()).toList(),
    'wildJoker': wildJoker.toMap(),
    'currentTurnIndex': currentTurnIndex,
    'turnStage': turnStage.name,
    'isDeclared': isDeclared,
    'winnerId': winnerId,
    'isFinished': isFinished,
  };

  factory RummyState.fromMap(Map<String, dynamic> map) => RummyState(
    version: map['version'] as int,
    playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
    players: (map['players'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, RummyPlayer.fromMap(v as Map<String, dynamic>)),
    ),
    openDeck: (map['openDeck'] as List<dynamic>)
        .map((c) => RummyCard.fromMap(c as Map<String, dynamic>))
        .toList(),
    closedDeck: (map['closedDeck'] as List<dynamic>)
        .map((c) => RummyCard.fromMap(c as Map<String, dynamic>))
        .toList(),
    wildJoker: RummyCard.fromMap(map['wildJoker'] as Map<String, dynamic>),
    currentTurnIndex: map['currentTurnIndex'] as int,
    turnStage: RummyTurnStage.values.firstWhere(
      (s) => s.name == map['turnStage'],
      orElse: () => RummyTurnStage.draw,
    ),
    isDeclared: map['isDeclared'] as bool? ?? false,
    winnerId: map['winnerId'] as String?,
    isFinished: map['isFinished'] as bool? ?? false,
  );

  String toJson() => json.encode(toMap());

  factory RummyState.fromJson(String source) =>
      RummyState.fromMap(json.decode(source) as Map<String, dynamic>);
}
