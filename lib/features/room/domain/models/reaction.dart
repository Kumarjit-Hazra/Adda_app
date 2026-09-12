class RoomReaction {
  final String id;
  final String senderId;
  final String senderName;
  final String emoji;
  final DateTime timestamp;

  const RoomReaction({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.emoji,
    required this.timestamp,
  });
}
