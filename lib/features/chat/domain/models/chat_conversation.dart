import 'chat_participant.dart';
import 'chat_message.dart';

class ChatConversation {
  final String id;
  final String title;
  final bool isGroup;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final String? associatedSpaceId;
  final String? gameInviteId;

  const ChatConversation({
    required this.id,
    required this.title,
    this.isGroup = false,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.associatedSpaceId,
    this.gameInviteId,
  });

  ChatConversation copyWith({
    String? id,
    String? title,
    bool? isGroup,
    List<ChatParticipant>? participants,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    String? associatedSpaceId,
    String? gameInviteId,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      isGroup: isGroup ?? this.isGroup,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      associatedSpaceId: associatedSpaceId ?? this.associatedSpaceId,
      gameInviteId: gameInviteId ?? this.gameInviteId,
    );
  }
}
