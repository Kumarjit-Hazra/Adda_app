import 'dart:convert';

/// Standard Realtime Event conforming to the ADDA Realtime Protocol.
class RealtimeEvent {
  final String eventId;
  final String type;
  final String roomId;
  final String senderId;
  final int sequence;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int protocolVersion;

  const RealtimeEvent({
    required this.eventId,
    required this.type,
    required this.roomId,
    required this.senderId,
    required this.sequence,
    required this.payload,
    required this.timestamp,
    this.protocolVersion = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'type': type,
      'roomId': roomId,
      'senderId': senderId,
      'sequence': sequence,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'protocolVersion': protocolVersion,
    };
  }

  factory RealtimeEvent.fromMap(Map<String, dynamic> map) {
    return RealtimeEvent(
      eventId: map['eventId'] as String,
      type: map['type'] as String,
      roomId: map['roomId'] as String,
      senderId: map['senderId'] as String,
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      payload: (map['payload'] as Map<String, dynamic>?) ?? {},
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      protocolVersion: (map['protocolVersion'] as num?)?.toInt() ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory RealtimeEvent.fromJson(String source) =>
      RealtimeEvent.fromMap(json.decode(source) as Map<String, dynamic>);
}
