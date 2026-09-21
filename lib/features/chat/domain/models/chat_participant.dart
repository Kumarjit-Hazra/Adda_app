class ChatParticipant {
  final String id;
  final String name;
  final String avatarUrl;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }
}
