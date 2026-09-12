import 'dart:convert';
import 'package:flutter/material.dart';

enum CardSuit {
  hearts,
  diamonds,
  clubs,
  spades;

  String get symbol => switch (this) {
    CardSuit.hearts => '♥',
    CardSuit.diamonds => '♦',
    CardSuit.clubs => '♣',
    CardSuit.spades => '♠',
  };

  Color get color => switch (this) {
    CardSuit.hearts => Colors.redAccent,
    CardSuit.diamonds => Colors.redAccent,
    CardSuit.clubs => Colors.white70,
    CardSuit.spades => Colors.white70,
  };
}

enum CardRank {
  seven,
  eight,
  queen,
  king,
  ten,
  ace,
  nine,
  jack;

  String get label => switch (this) {
    CardRank.seven => '7',
    CardRank.eight => '8',
    CardRank.queen => 'Q',
    CardRank.king => 'K',
    CardRank.ten => '10',
    CardRank.ace => 'A',
    CardRank.nine => '9',
    CardRank.jack => 'J',
  };

  int get points => switch (this) {
    CardRank.jack => 3,
    CardRank.nine => 2,
    CardRank.ace => 1,
    CardRank.ten => 1,
    _ => 0,
  };

  /// Ranking power in 29: J (7) > 9 (6) > A (5) > 10 (4) > K (3) > Q (2) > 8 (1) > 7 (0)
  int get rankPower => switch (this) {
    CardRank.jack => 7,
    CardRank.nine => 6,
    CardRank.ace => 5,
    CardRank.ten => 4,
    CardRank.king => 3,
    CardRank.queen => 2,
    CardRank.eight => 1,
    CardRank.seven => 0,
  };
}

class PlayingCard {
  final CardSuit suit;
  final CardRank rank;

  const PlayingCard(this.suit, this.rank);

  int get points => rank.points;
  int get power => rank.rankPower;

  String get id => '${suit.name}_${rank.name}';

  Map<String, dynamic> toMap() => {'suit': suit.name, 'rank': rank.name};

  factory PlayingCard.fromMap(Map<String, dynamic> map) {
    return PlayingCard(
      CardSuit.values.firstWhere((s) => s.name == map['suit']),
      CardRank.values.firstWhere((r) => r.name == map['rank']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;
}

enum TwentyNinePhase { bidding, playing, finished }

class PlayedTrickCard {
  final String playerId;
  final PlayingCard card;

  const PlayedTrickCard({required this.playerId, required this.card});

  Map<String, dynamic> toMap() => {'playerId': playerId, 'card': card.toMap()};

  factory PlayedTrickCard.fromMap(Map<String, dynamic> map) => PlayedTrickCard(
    playerId: map['playerId'] as String,
    card: PlayingCard.fromMap(map['card'] as Map<String, dynamic>),
  );
}

class TwentyNineState {
  final int version;
  final List<String> playerIds;
  final Map<String, List<PlayingCard>> hands;
  final TwentyNinePhase phase;
  final int currentTurnIndex;
  final int highestBid;
  final String? highestBidderId;
  final CardSuit? trumpSuit;
  final bool isTrumpRevealed;
  final List<PlayedTrickCard> currentTrick;
  final List<List<PlayedTrickCard>> completedTricks;
  final Map<int, int> teamTrickPoints; // Team 0 (p0, p2), Team 1 (p1, p3)
  final int? winnerTeam;

  const TwentyNineState({
    required this.version,
    required this.playerIds,
    required this.hands,
    required this.phase,
    required this.currentTurnIndex,
    required this.highestBid,
    this.highestBidderId,
    this.trumpSuit,
    this.isTrumpRevealed = false,
    required this.currentTrick,
    required this.completedTricks,
    required this.teamTrickPoints,
    this.winnerTeam,
  });

  TwentyNineState copyWith({
    int? version,
    List<String>? playerIds,
    Map<String, List<PlayingCard>>? hands,
    TwentyNinePhase? phase,
    int? currentTurnIndex,
    int? highestBid,
    String? highestBidderId,
    CardSuit? trumpSuit,
    bool? isTrumpRevealed,
    List<PlayedTrickCard>? currentTrick,
    List<List<PlayedTrickCard>>? completedTricks,
    Map<int, int>? teamTrickPoints,
    int? winnerTeam,
  }) {
    return TwentyNineState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      hands: hands ?? this.hands,
      phase: phase ?? this.phase,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      highestBid: highestBid ?? this.highestBid,
      highestBidderId: highestBidderId ?? this.highestBidderId,
      trumpSuit: trumpSuit ?? this.trumpSuit,
      isTrumpRevealed: isTrumpRevealed ?? this.isTrumpRevealed,
      currentTrick: currentTrick ?? this.currentTrick,
      completedTricks: completedTricks ?? this.completedTricks,
      teamTrickPoints: teamTrickPoints ?? this.teamTrickPoints,
      winnerTeam: winnerTeam ?? this.winnerTeam,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'playerIds': playerIds,
      'hands': hands.map(
        (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
      ),
      'phase': phase.name,
      'currentTurnIndex': currentTurnIndex,
      'highestBid': highestBid,
      'highestBidderId': highestBidderId,
      'trumpSuit': trumpSuit?.name,
      'isTrumpRevealed': isTrumpRevealed,
      'currentTrick': currentTrick.map((p) => p.toMap()).toList(),
      'completedTricks': completedTricks
          .map((t) => t.map((p) => p.toMap()).toList())
          .toList(),
      'teamTrickPoints': teamTrickPoints.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'winnerTeam': winnerTeam,
    };
  }

  factory TwentyNineState.fromMap(Map<String, dynamic> map) {
    return TwentyNineState(
      version: map['version'] as int,
      playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
      hands: (map['hands'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>)
              .map((c) => PlayingCard.fromMap(c as Map<String, dynamic>))
              .toList(),
        ),
      ),
      phase: TwentyNinePhase.values.firstWhere((p) => p.name == map['phase']),
      currentTurnIndex: map['currentTurnIndex'] as int,
      highestBid: map['highestBid'] as int,
      highestBidderId: map['highestBidderId'] as String?,
      trumpSuit: map['trumpSuit'] != null
          ? CardSuit.values.firstWhere((s) => s.name == map['trumpSuit'])
          : null,
      isTrumpRevealed: map['isTrumpRevealed'] as bool? ?? false,
      currentTrick: (map['currentTrick'] as List<dynamic>)
          .map((p) => PlayedTrickCard.fromMap(p as Map<String, dynamic>))
          .toList(),
      completedTricks: (map['completedTricks'] as List<dynamic>)
          .map(
            (t) => (t as List<dynamic>)
                .map((p) => PlayedTrickCard.fromMap(p as Map<String, dynamic>))
                .toList(),
          )
          .toList(),
      teamTrickPoints: (map['teamTrickPoints'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      winnerTeam: map['winnerTeam'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TwentyNineState.fromJson(String source) =>
      TwentyNineState.fromMap(json.decode(source) as Map<String, dynamic>);
}
