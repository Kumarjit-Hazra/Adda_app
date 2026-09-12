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
  }) async {
    final user = _ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final roomId = 'room_$spaceId';

    // Seed room with local user + room companions
    final localParticipant = Participant(
      id: user.id,
      name: user.name,
      avatarUrl: user.avatarUrl,
      isSpeaking: false,
      isMuted: false,
      isVideoEnabled: false,
      isHost: true,
    );

    // Initial companion peers for vibrant hangout vibe
    final companionPeers = [
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
          content:
              'Welcome to $spaceName! Voice is live. Tap Play to start an activity.',
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      ],
      isConnected: true,
    );

    await _signaling.connect(roomId, user.id);
    await _webrtc.initializeMedia();

    // Listen to realtime signaling events
    _signalingSub?.cancel();
    _signalingSub = _signaling.eventStream.listen(_handleSignalingEvent);

    // Monitor local audio level for speaking indicator
    _audioLevelSub?.cancel();
    _audioLevelSub = _webrtc.localAudioLevelStream.listen((level) {
      if (state == null) return;
      final isSpeaking = level > 0.45 && !_webrtc.isMicMuted;
      _updateParticipantSpeaking(user.id, isSpeaking);
    });
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
    state = state!.copyWith(activeActivityId: activityId);
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
