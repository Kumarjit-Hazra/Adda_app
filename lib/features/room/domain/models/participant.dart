class Participant {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isSpeaking;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isMediaUnavailable;
  final bool isHost;
  final int pingMs;

  const Participant({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isVideoEnabled = false,
    this.isMediaUnavailable = false,
    this.isHost = false,
    this.pingMs = 28,
  });

  Participant copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isSpeaking,
    bool? isMuted,
    bool? isVideoEnabled,
    bool? isMediaUnavailable,
    bool? isHost,
    int? pingMs,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isMediaUnavailable: isMediaUnavailable ?? this.isMediaUnavailable,
      isHost: isHost ?? this.isHost,
      pingMs: pingMs ?? this.pingMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isSpeaking': isSpeaking,
      'isMuted': isMuted,
      'isVideoEnabled': isVideoEnabled,
      'isMediaUnavailable': isMediaUnavailable,
      'isHost': isHost,
      'pingMs': pingMs,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      isSpeaking: map['isSpeaking'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
      isVideoEnabled: map['isVideoEnabled'] as bool? ?? false,
      isMediaUnavailable: map['isMediaUnavailable'] as bool? ?? false,
      isHost: map['isHost'] as bool? ?? false,
      pingMs: map['pingMs'] as int? ?? 28,
    );
  }
}
