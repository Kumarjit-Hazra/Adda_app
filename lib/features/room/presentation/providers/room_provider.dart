import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/signaling_service.dart';
import '../../../../core/webrtc/webrtc_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/reaction.dart';
import '../../domain/models/room_session.dart';

final signalingServiceProvider = Provider<SignalingService>((ref) {
  return SimulatedSignalingService();
});

final webrtcServiceProvider = Provider<WebRtcService>((ref) {
  return DefaultWebRtcService();
});

class RoomNotifier extends StateNotifier<RoomSession?> {
  final SignalingService _signaling;
  final WebRtcService _webrtc;
  final Ref _ref;
  StreamSubscription? _signalingSub;
  StreamSubscription? _audioLevelSub;
  int _sequence = 0;

  final List<RoomReaction> _recentReactions = [];
  List<RoomReaction> get recentReactions => List.unmodifiable(_recentReactions);

  RoomNotifier(this._signaling, this._webrtc, this._ref) : super(null);

  Future<void> joinRoom({
    required String spaceId,
    required String spaceName,
    bool isSoloMode = false,
    bool autoJoinVoice = false,
  }) async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final roomId = isSoloMode
        ? 'solo_${spaceId}_${const Uuid().v4().substring(0, 6)}'
        : 'room_$spaceId';

    // Seed room with local user + room companions (or bots in solo mode)
    final localParticipant = Participant(
      id: user.id,
      name: user.name,
      avatarUrl: user.avatarUrl,
      isSpeaking: false,
      isMuted: false,
      isVideoEnabled: false,
      isHost: true,
    );

    final companionPeers = isSoloMode
        ? [
            const Participant(
              id: 'bot_1',
              name: 'Kabir Bot 🤖',
              isSpeaking: false,
              isMuted: true,
              isVideoEnabled: false,
              pingMs: 5,
            ),
            const Participant(
              id: 'bot_2',
              name: 'Diya Bot 🤖',
              isSpeaking: false,
              isMuted: true,
              isVideoEnabled: false,
              pingMs: 5,
            ),
          ]
        : [
            const Participant(
              id: 'usr_sim_1',
              name: 'Aarav Sharma',
              isSpeaking: false,
              isMuted: false,
              isVideoEnabled: false,
              pingMs: 24,
            ),
            const Participant(
              id: 'usr_sim_2',
              name: 'Diya Sen',
              isSpeaking: false,
              isMuted: false,
              isVideoEnabled: false,
              pingMs: 32,
            ),
            const Participant(
              id: 'usr_sim_3',
              name: 'Kabir Roy',
              isSpeaking: false,
              isMuted: true,
              isVideoEnabled: false,
              pingMs: 19,
            ),
          ];

    final welcomeContent = isSoloMode
        ? 'Solo practice with smart bots. No voice chat or waiting required!'
        : (autoJoinVoice
              ? 'Welcome to $spaceName! Voice is live.'
              : 'Welcome to $spaceName! Voice is off. Tap [Join Voice] anytime to talk.');

    state = RoomSession(
      roomId: roomId,
      spaceId: spaceId,
      spaceName: spaceName,
      hostId: user.id,
      participants: [localParticipant, ...companionPeers],
      chatMessages: [
        ChatMessage(
          id: const Uuid().v4(),
          senderId: 'system',
          senderName: 'ADDA System',
          content: welcomeContent,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      ],
      isConnected: true,
      isVoiceJoined: autoJoinVoice,
      isSoloMode: isSoloMode,
    );

    if (!isSoloMode) {
      await _signaling.connect(roomId, user.id);
      _signalingSub?.cancel();
      _signalingSub = _signaling.eventStream.listen(_handleSignalingEvent);
    }

    if (autoJoinVoice) {
      await joinVoiceChat();
    }
  }

  void _setupAudioLevelListener() {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null) return;
    _audioLevelSub?.cancel();
    _audioLevelSub = _webrtc.localAudioLevelStream.listen((level) {
      if (state == null || !state!.isVoiceJoined) return;
      final isSpeaking = level > 0.45 && !_webrtc.isMicMuted;
      _updateParticipantSpeaking(user.id, isSpeaking);
    });
  }

  Future<void> joinVoiceChat() async {
    if (state == null || state!.isVoiceJoined) return;
    try {
      await _webrtc.initializeMedia();
      _setupAudioLevelListener();
      state = state!.copyWith(isVoiceJoined: true);
      HapticsService.success();
    } catch (_) {}
  }

  Future<void> leaveVoiceChat() async {
    if (state == null || !state!.isVoiceJoined) return;
    _audioLevelSub?.cancel();
    await _webrtc.stopMedia();
    final user = _ref.read(authProvider).valueOrNull;
    if (user != null) {
      _updateParticipantSpeaking(user.id, false);
    }
    state = state!.copyWith(isVoiceJoined: false);
    HapticsService.lightTap();
  }

  Future<void> toggleVoiceChat() async {
    if (state?.isVoiceJoined == true) {
      await leaveVoiceChat();
    } else {
      await joinVoiceChat();
    }
  }

  void _handleSignalingEvent(RealtimeEvent event) {
    if (state == null) return;

    if (event.type == 'presence.speaking') {
      final peerId = event.senderId;
      final isSpeaking = event.payload['isSpeaking'] as bool? ?? false;
      _updateParticipantSpeaking(peerId, isSpeaking);
    } else if (event.type == 'chat.message') {
      final msg = ChatMessage.fromMap(event.payload);
      state = state!.copyWith(chatMessages: [...state!.chatMessages, msg]);
      AudioService.playUiTap();
    } else if (event.type == 'reaction.sent') {
      final reaction = RoomReaction(
        id: event.eventId,
        senderId: event.senderId,
        senderName: event.payload['senderName'] as String? ?? 'Friend',
        emoji: event.payload['emoji'] as String? ?? '❤️',
        timestamp: DateTime.now(),
      );
      _recentReactions.add(reaction);
      AudioService.playReaction();
      HapticsService.lightTap();
      // Notify state update
      state = state!.copyWith();
    }
  }

  void _updateParticipantSpeaking(String participantId, bool isSpeaking) {
    if (state == null) return;
    final updated = state!.participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(isSpeaking: isSpeaking);
      }
      return p;
    }).toList();
    state = state!.copyWith(participants: updated);
  }

  Future<void> sendChatMessage(String content) async {
    if (state == null || content.trim().isEmpty) return;
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final msg = ChatMessage(
      id: const Uuid().v4(),
      senderId: user.id,
      senderName: user.name,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    final event = RealtimeEvent(
      eventId: msg.id,
      type: 'chat.message',
      roomId: state!.roomId,
      senderId: user.id,
      sequence: ++_sequence,
      payload: msg.toMap(),
      timestamp: DateTime.now(),
    );

    await _signaling.sendEvent(event);
  }

  Future<void> sendReaction(String emoji) async {
    if (state == null) return;
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final event = RealtimeEvent(
      eventId: const Uuid().v4(),
      type: 'reaction.sent',
      roomId: state!.roomId,
      senderId: user.id,
      sequence: ++_sequence,
      payload: {'emoji': emoji, 'senderName': user.name},
      timestamp: DateTime.now(),
    );

    await _signaling.sendEvent(event);
  }

  Future<void> toggleMic() async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null || state == null) return;

    await _webrtc.toggleMic();
    HapticsService.selectionClick();

    final updated = state!.participants.map((p) {
      if (p.id == user.id) {
        return p.copyWith(isMuted: _webrtc.isMicMuted);
      }
      return p;
    }).toList();
    state = state!.copyWith(participants: updated);
  }

  Future<void> toggleCamera() async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null || state == null) return;

    await _webrtc.toggleCamera();
    HapticsService.selectionClick();

    final updated = state!.participants.map((p) {
      if (p.id == user.id) {
        return p.copyWith(isVideoEnabled: _webrtc.isCameraEnabled);
      }
      return p;
    }).toList();
    state = state!.copyWith(participants: updated);
  }

  void setActiveActivity(String? activityId) {
    if (state == null) return;
    if (activityId == null) {
      state = state!.copyWith(clearActiveActivity: true);
    } else {
      state = state!.copyWith(activeActivityId: activityId);
    }
    HapticsService.success();
  }

  Future<void> leaveRoom() async {
    _signalingSub?.cancel();
    _audioLevelSub?.cancel();
    await _signaling.disconnect();
    await _webrtc.dispose();
    state = null;
    HapticsService.lightTap();
  }

  @override
  void dispose() {
    _signalingSub?.cancel();
    _audioLevelSub?.cancel();
    super.dispose();
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomSession?>((ref) {
  final signaling = ref.watch(signalingServiceProvider);
  final webrtc = ref.watch(webrtcServiceProvider);
  return RoomNotifier(signaling, webrtc, ref);
});
