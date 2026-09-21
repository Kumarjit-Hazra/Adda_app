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
  final bool isVoiceJoined;
  final bool isMicEnabled;
  final bool isCameraEnabled;
  final String? mediaErrorState;
  final bool isSoloMode;

  const RoomSession({
    required this.roomId,
    required this.spaceId,
    required this.spaceName,
    required this.hostId,
    required this.participants,
    required this.chatMessages,
    this.activeActivityId,
    this.isConnected = true,
    this.isVoiceJoined = false,
    this.isMicEnabled = false,
    this.isCameraEnabled = false,
    this.mediaErrorState,
    this.isSoloMode = false,
  });

  RoomSession copyWith({
    String? roomId,
    String? spaceId,
    String? spaceName,
    String? hostId,
    List<Participant>? participants,
    List<ChatMessage>? chatMessages,
    String? activeActivityId,
    bool clearActiveActivity = false,
    bool? isConnected,
    bool? isVoiceJoined,
    bool? isMicEnabled,
    bool? isCameraEnabled,
    String? mediaErrorState,
    bool clearMediaErrorState = false,
    bool? isSoloMode,
  }) {
    return RoomSession(
      roomId: roomId ?? this.roomId,
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      hostId: hostId ?? this.hostId,
      participants: participants ?? this.participants,
      chatMessages: chatMessages ?? this.chatMessages,
      activeActivityId: clearActiveActivity
          ? null
          : (activeActivityId ?? this.activeActivityId),
      isConnected: isConnected ?? this.isConnected,
      isVoiceJoined: isVoiceJoined ?? this.isVoiceJoined,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      mediaErrorState: clearMediaErrorState
          ? null
          : (mediaErrorState ?? this.mediaErrorState),
      isSoloMode: isSoloMode ?? this.isSoloMode,
    );
  }
}
