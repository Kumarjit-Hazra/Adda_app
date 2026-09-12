import 'dart:convert';

/// Generic player action dispatched by a participant in an activity session.
class PlayerAction {
  final String actionId;
  final String playerId;
  final String activityId;
  final String type;
  final Map<String, dynamic> payload;
  final int clientSequence;

  const PlayerAction({
    required this.actionId,
    required this.playerId,
    required this.activityId,
    required this.type,
    required this.payload,
    required this.clientSequence,
  });

  Map<String, dynamic> toMap() {
    return {
      'actionId': actionId,
      'playerId': playerId,
      'activityId': activityId,
      'type': type,
      'payload': payload,
      'clientSequence': clientSequence,
    };
  }

  factory PlayerAction.fromMap(Map<String, dynamic> map) {
    return PlayerAction(
      actionId: map['actionId'] as String,
      playerId: map['playerId'] as String,
      activityId: map['activityId'] as String,
      type: map['type'] as String,
      payload: (map['payload'] as Map<String, dynamic>?) ?? {},
      clientSequence: (map['clientSequence'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlayerAction.fromJson(String source) =>
      PlayerAction.fromMap(json.decode(source) as Map<String, dynamic>);
}
