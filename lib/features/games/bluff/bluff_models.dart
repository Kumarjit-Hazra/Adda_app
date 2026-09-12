import 'dart:convert';

enum BluffRank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king;

  String get label => switch (this) {
    BluffRank.ace => 'A',
    BluffRank.two => '2',
    BluffRank.three => '3',
    BluffRank.four => '4',
    BluffRank.five => '5',
    BluffRank.six => '6',
    BluffRank.seven => '7',
    BluffRank.eight => '8',
    BluffRank.nine => '9',
    BluffRank.ten => '10',
    BluffRank.jack => 'J',
    BluffRank.queen => 'Q',
    BluffRank.king => 'K',
  };
}

class BluffCard {
  final BluffRank rank;
  final int suitIndex; // 0..3

  const BluffCard(this.rank, this.suitIndex);

  String get id => '${rank.name}_$suitIndex';

  Map<String, dynamic> toMap() => {'rank': rank.name, 'suitIndex': suitIndex};

  factory BluffCard.fromMap(Map<String, dynamic> map) => BluffCard(
    BluffRank.values.firstWhere((r) => r.name == map['rank']),
    map['suitIndex'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluffCard && other.rank == rank && other.suitIndex == suitIndex;

  @override
  int get hashCode => rank.hashCode ^ suitIndex.hashCode;
}

class BluffClaim {
  final String claimantId;
  final BluffRank declaredRank;
  final List<BluffCard> actualCards;

  const BluffClaim({
    required this.claimantId,
    required this.declaredRank,
    required this.actualCards,
  });

  bool get wasTruth => actualCards.every((c) => c.rank == declaredRank);

  Map<String, dynamic> toMap() => {
    'claimantId': claimantId,
    'declaredRank': declaredRank.name,
    'actualCards': actualCards.map((c) => c.toMap()).toList(),
  };

  factory BluffClaim.fromMap(Map<String, dynamic> map) => BluffClaim(
    claimantId: map['claimantId'] as String,
    declaredRank: BluffRank.values.firstWhere(
      (r) => r.name == map['declaredRank'],
    ),
    actualCards: (map['actualCards'] as List<dynamic>)
        .map((c) => BluffCard.fromMap(c as Map<String, dynamic>))
        .toList(),
  );
}

class BluffState {
  final int version;
  final List<String> playerIds;
  final Map<String, List<BluffCard>> hands;
  final List<BluffCard> centerPile;
  final BluffClaim? lastClaim;
  final int currentTurnIndex;
  final BluffRank currentRankRequirement;
  final String? challengeResultBanner;
  final String? winnerId;

  const BluffState({
    required this.version,
    required this.playerIds,
    required this.hands,
    required this.centerPile,
    this.lastClaim,
    required this.currentTurnIndex,
    required this.currentRankRequirement,
    this.challengeResultBanner,
    this.winnerId,
  });

  BluffState copyWith({
    int? version,
    List<String>? playerIds,
    Map<String, List<BluffCard>>? hands,
    List<BluffCard>? centerPile,
    BluffClaim? lastClaim,
    int? currentTurnIndex,
    BluffRank? currentRankRequirement,
    String? challengeResultBanner,
    String? winnerId,
  }) {
    return BluffState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      hands: hands ?? this.hands,
      centerPile: centerPile ?? this.centerPile,
      lastClaim: lastClaim ?? this.lastClaim,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      currentRankRequirement:
          currentRankRequirement ?? this.currentRankRequirement,
      challengeResultBanner:
          challengeResultBanner ?? this.challengeResultBanner,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'playerIds': playerIds,
      'hands': hands.map(
        (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
      ),
      'centerPile': centerPile.map((c) => c.toMap()).toList(),
      'lastClaim': lastClaim?.toMap(),
      'currentTurnIndex': currentTurnIndex,
      'currentRankRequirement': currentRankRequirement.name,
      'challengeResultBanner': challengeResultBanner,
      'winnerId': winnerId,
    };
  }

  factory BluffState.fromMap(Map<String, dynamic> map) {
    return BluffState(
      version: map['version'] as int,
      playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
      hands: (map['hands'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>)
              .map((c) => BluffCard.fromMap(c as Map<String, dynamic>))
              .toList(),
        ),
      ),
      centerPile: (map['centerPile'] as List<dynamic>)
          .map((c) => BluffCard.fromMap(c as Map<String, dynamic>))
          .toList(),
      lastClaim: map['lastClaim'] != null
          ? BluffClaim.fromMap(map['lastClaim'] as Map<String, dynamic>)
          : null,
      currentTurnIndex: map['currentTurnIndex'] as int,
      currentRankRequirement: BluffRank.values.firstWhere(
        (r) => r.name == map['currentRankRequirement'],
      ),
      challengeResultBanner: map['challengeResultBanner'] as String?,
      winnerId: map['winnerId'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory BluffState.fromJson(String source) =>
      BluffState.fromMap(json.decode(source) as Map<String, dynamic>);
}
