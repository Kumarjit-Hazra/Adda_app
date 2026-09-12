import 'dart:convert';
import 'package:flutter/material.dart';

enum UnoColor {
  red,
  blue,
  green,
  yellow,
  wild;

  Color get displayColor => switch (this) {
    UnoColor.red => const Color(0xFFFF3366),
    UnoColor.blue => const Color(0xFF0099FF),
    UnoColor.green => const Color(0xFF00CC66),
    UnoColor.yellow => const Color(0xFFFFCC00),
    UnoColor.wild => const Color(0xFF9933FF),
  };
}

enum UnoValue {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  skip,
  reverse,
  drawTwo,
  wild,
  wildDrawFour;

  String get label => switch (this) {
    UnoValue.zero => '0',
    UnoValue.one => '1',
    UnoValue.two => '2',
    UnoValue.three => '3',
    UnoValue.four => '4',
    UnoValue.five => '5',
    UnoValue.six => '6',
    UnoValue.seven => '7',
    UnoValue.eight => '8',
    UnoValue.nine => '9',
    UnoValue.skip => '⊘',
    UnoValue.reverse => '⇄',
    UnoValue.drawTwo => '+2',
    UnoValue.wild => '★',
    UnoValue.wildDrawFour => '+4',
  };
}

class UnoCard {
  final UnoColor color;
  final UnoValue value;

  const UnoCard(this.color, this.value);

  bool get isWild =>
      color == UnoColor.wild ||
      value == UnoValue.wild ||
      value == UnoValue.wildDrawFour;

  String get id => '${color.name}_${value.name}';

  Map<String, dynamic> toMap() => {'color': color.name, 'value': value.name};

  factory UnoCard.fromMap(Map<String, dynamic> map) {
    return UnoCard(
      UnoColor.values.firstWhere((c) => c.name == map['color']),
      UnoValue.values.firstWhere((v) => v.name == map['value']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnoCard && other.color == color && other.value == value;

  @override
  int get hashCode => color.hashCode ^ value.hashCode;
}

class UnoState {
  final int version;
  final List<String> playerIds;
  final Map<String, List<UnoCard>> hands;
  final List<UnoCard> drawPile;
  final List<UnoCard> discardPile;
  final int currentTurnIndex;
  final bool isClockwise;
  final UnoColor activeColor;
  final String? winnerId;
  final bool hasShoutedUno;

  const UnoState({
    required this.version,
    required this.playerIds,
    required this.hands,
    required this.drawPile,
    required this.discardPile,
    required this.currentTurnIndex,
    this.isClockwise = true,
    required this.activeColor,
    this.winnerId,
    this.hasShoutedUno = false,
  });

  UnoCard get topDiscard => discardPile.last;

  UnoState copyWith({
    int? version,
    List<String>? playerIds,
    Map<String, List<UnoCard>>? hands,
    List<UnoCard>? drawPile,
    List<UnoCard>? discardPile,
    int? currentTurnIndex,
    bool? isClockwise,
    UnoColor? activeColor,
    String? winnerId,
    bool? hasShoutedUno,
  }) {
    return UnoState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      hands: hands ?? this.hands,
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      isClockwise: isClockwise ?? this.isClockwise,
      activeColor: activeColor ?? this.activeColor,
      winnerId: winnerId ?? this.winnerId,
      hasShoutedUno: hasShoutedUno ?? this.hasShoutedUno,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'playerIds': playerIds,
      'hands': hands.map(
        (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
      ),
      'drawPile': drawPile.map((c) => c.toMap()).toList(),
      'discardPile': discardPile.map((c) => c.toMap()).toList(),
      'currentTurnIndex': currentTurnIndex,
      'isClockwise': isClockwise,
      'activeColor': activeColor.name,
      'winnerId': winnerId,
      'hasShoutedUno': hasShoutedUno,
    };
  }

  factory UnoState.fromMap(Map<String, dynamic> map) {
    return UnoState(
      version: map['version'] as int,
      playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
      hands: (map['hands'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>)
              .map((c) => UnoCard.fromMap(c as Map<String, dynamic>))
              .toList(),
        ),
      ),
      drawPile: (map['drawPile'] as List<dynamic>)
          .map((c) => UnoCard.fromMap(c as Map<String, dynamic>))
          .toList(),
      discardPile: (map['discardPile'] as List<dynamic>)
          .map((c) => UnoCard.fromMap(c as Map<String, dynamic>))
          .toList(),
      currentTurnIndex: map['currentTurnIndex'] as int,
      isClockwise: map['isClockwise'] as bool? ?? true,
      activeColor: UnoColor.values.firstWhere(
        (c) => c.name == map['activeColor'],
      ),
      winnerId: map['winnerId'] as String?,
      hasShoutedUno: map['hasShoutedUno'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UnoState.fromJson(String source) =>
      UnoState.fromMap(json.decode(source) as Map<String, dynamic>);
}
