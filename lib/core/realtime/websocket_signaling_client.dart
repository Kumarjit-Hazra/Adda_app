import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../logging/logger_service.dart';
import 'realtime_event.dart';
import 'signaling_service.dart';

/// Production-ready WebSocket signaling client for remote ADDA servers.
/// Supports auto-reconnect, ping/pong heartbeat, and standard RealtimeEvent serialization.
class WebSocketSignalingClient implements SignalingService {
  final Uri serverUri;
  final _eventController = StreamController<RealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _connected = false;
  bool _intentionalDisconnect = false;
  String? _roomId;
  String? _userId;

  WebSocketSignalingClient({required this.serverUri});

  @override
  Stream<RealtimeEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(String roomId, String userId) async {
    _roomId = roomId;
    _userId = userId;
    _intentionalDisconnect = false;
    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_roomId == null || _userId == null) return;
    try {
      final queryParams = {'roomId': _roomId!, 'userId': _userId!};
      final uri = serverUri.replace(queryParameters: queryParams);

      _channel = WebSocketChannel.connect(uri);
      await _channel?.ready;

      _connected = true;
      LoggerService.i('WebSocketSignaling', 'Connected to $uri');

      _channelSubscription = _channel?.stream.listen(
        (message) {
          _onMessageReceived(message);
        },
        onError: (error) {
          LoggerService.e('WebSocketSignaling', 'Stream error: $error');
          _handleDisconnection();
        },
        onDone: () {
          LoggerService.w('WebSocketSignaling', 'Connection closed');
          _handleDisconnection();
        },
      );

      _startHeartbeat();
    } catch (e) {
      LoggerService.e('WebSocketSignaling', 'Connection failed: $e');
      _handleDisconnection();
    }
  }

  void _onMessageReceived(dynamic message) {
    if (message is String) {
      try {
        if (message == 'pong') return;
        final event = RealtimeEvent.fromJson(message);
        _eventController.add(event);
      } catch (e) {
        LoggerService.w('WebSocketSignaling', 'Failed to parse message: $e');
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_connected && _channel != null) {
        try {
          _channel?.sink.add('ping');
        } catch (_) {}
      }
    });
  }

  void _handleDisconnection() {
    _connected = false;
    _heartbeatTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;

    if (!_intentionalDisconnect && _roomId != null && _userId != null) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (!_intentionalDisconnect) {
          LoggerService.i('WebSocketSignaling', 'Attempting auto-reconnect...');
          _establishConnection();
        }
      });
    }
  }

  @override
  Future<void> sendEvent(RealtimeEvent event) async {
    if (!_connected || _channel == null) {
      LoggerService.w('WebSocketSignaling', 'Cannot send event: disconnected');
      return;
    }
    try {
      _channel?.sink.add(event.toJson());
      LoggerService.d('WebSocketSignaling', 'Sent ${event.type}');
    } catch (e) {
      LoggerService.e('WebSocketSignaling', 'Error sending event: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _connected = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _channelSubscription = null;
    LoggerService.i('WebSocketSignaling', 'Disconnected intentionally');
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
