import 'participant.dart';
import 'chat_message.dart';

class RoomSession {
  final String roomId;
  final String spaceId;
  final String spaceName;
  final String hostId;
  final List<Participant> participants;
  final List<ChatMessage> chatMessages;
  final String? activeActivityId;
  final bool isConnected;

  const RoomSession({
    required this.roomId,
    required this.spaceId,
    required this.spaceName,
    required this.hostId,
    required this.participants,
    required this.chatMessages,
    this.activeActivityId,
    this.isConnected = true,
  });

  RoomSession copyWith({
    String? roomId,
    String? spaceId,
    String? spaceName,
    String? hostId,
    List<Participant>? participants,
    List<ChatMessage>? chatMessages,
    String? activeActivityId,
    bool? isConnected,
  }) {
    return RoomSession(
      roomId: roomId ?? this.roomId,
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      hostId: hostId ?? this.hostId,
      participants: participants ?? this.participants,
      chatMessages: chatMessages ?? this.chatMessages,
      activeActivityId: activeActivityId ?? this.activeActivityId,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
