import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../logging/logger_service.dart';
import 'realtime_event.dart';

abstract class SignalingService {
  Stream<RealtimeEvent> get eventStream;
  Future<void> connect(String roomId, String userId);
  Future<void> sendEvent(RealtimeEvent event);
  Future<void> disconnect();
  bool get isConnected;
}

/// Simulated signaling service for local development, rapid multi-player simulation, and tests.
class SimulatedSignalingService implements SignalingService {
  final _eventController = StreamController<RealtimeEvent>.broadcast();
  bool _connected = false;
  String? _roomId;
  String? _userId;
  Timer? _speakingTimer;
  int _sequence = 0;

  @override
  Stream<RealtimeEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _connected;

  String? get currentUserId => _userId;

  @override
  Future<void> connect(String roomId, String userId) async {
    _roomId = roomId;
    _userId = userId;
    _connected = true;
    LoggerService.i(
      'Signaling',
      'Connected to simulated room: $roomId for user: $userId',
    );

    // Simulate occasional speaking wave hints from peers
    _startSimulatedPeerAudio();
  }

  void _startSimulatedPeerAudio() {
    _speakingTimer?.cancel();
    _speakingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_connected || _roomId == null) return;
      final randomPeerId = 'usr_sim_${Random().nextInt(3) + 1}';
      final isSpeaking = Random().nextBool();

      _eventController.add(
        RealtimeEvent(
          eventId: const Uuid().v4(),
          type: 'presence.speaking',
          roomId: _roomId!,
          senderId: randomPeerId,
          sequence: ++_sequence,
          payload: {'isSpeaking': isSpeaking},
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Future<void> sendEvent(RealtimeEvent event) async {
    if (!_connected) return;
    LoggerService.d(
      'Signaling',
      'Sent event [${event.type}] seq=${event.sequence}',
    );
    // Broadcast back to local listeners
    _eventController.add(event);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _speakingTimer?.cancel();
    LoggerService.i('Signaling', 'Disconnected from simulated room: $_roomId');
  }
}
