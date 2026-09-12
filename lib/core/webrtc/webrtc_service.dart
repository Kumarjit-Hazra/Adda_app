import 'dart:async';
import '../logging/logger_service.dart';

enum WebRtcState { idle, connecting, connected, reconnecting, failed }

abstract class WebRtcService {
  WebRtcState get state;
  Stream<WebRtcState> get stateStream;
  bool get isMicMuted;
  bool get isCameraEnabled;
  bool get isDeafened;
  Stream<double> get localAudioLevelStream;

  Future<void> initializeMedia();
  Future<void> toggleMic();
  Future<void> toggleCamera();
  Future<void> toggleDeafen();
  Future<void> setAudioOnly(bool audioOnly);
  Future<void> dispose();
}

/// Robust WebRTC abstraction supporting smooth simulated voice & camera feeds across platforms.
class DefaultWebRtcService implements WebRtcService {
  WebRtcState _state = WebRtcState.idle;
  final _stateController = StreamController<WebRtcState>.broadcast();
  final _audioLevelController = StreamController<double>.broadcast();

  bool _isMicMuted = false;
  bool _isCameraEnabled = false;
  bool _isDeafened = false;
  bool _isAudioOnly = false;
  Timer? _levelSimulator;

  @override
  WebRtcState get state => _state;

  @override
  Stream<WebRtcState> get stateStream => _stateController.stream;

  @override
  bool get isMicMuted => _isMicMuted;

  @override
  bool get isCameraEnabled => _isCameraEnabled;

  @override
  bool get isDeafened => _isDeafened;

  bool get isAudioOnly => _isAudioOnly;

  @override
  Stream<double> get localAudioLevelStream => _audioLevelController.stream;

  @override
  Future<void> initializeMedia() async {
    _setState(WebRtcState.connecting);
    LoggerService.i('WebRtc', 'Initializing audio & video media session');
    await Future.delayed(const Duration(milliseconds: 300));
    _setState(WebRtcState.connected);

    // Simulate real audio voice activity detection (VAD)
    _levelSimulator?.cancel();
    _levelSimulator = Timer.periodic(const Duration(milliseconds: 250), (
      timer,
    ) {
      if (_state == WebRtcState.connected && !_isMicMuted) {
        // Output audio level 0.0 to 1.0
        final level = (DateTime.now().millisecond % 100) / 100.0;
        _audioLevelController.add(level);
      } else {
        _audioLevelController.add(0.0);
      }
    });
  }

  void _setState(WebRtcState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  @override
  Future<void> toggleMic() async {
    _isMicMuted = !_isMicMuted;
    LoggerService.i('WebRtc', 'Mic muted: $_isMicMuted');
  }

  @override
  Future<void> toggleCamera() async {
    if (_isAudioOnly) return;
    _isCameraEnabled = !_isCameraEnabled;
    LoggerService.i('WebRtc', 'Camera enabled: $_isCameraEnabled');
  }

  @override
  Future<void> toggleDeafen() async {
    _isDeafened = !_isDeafened;
    if (_isDeafened) {
      _isMicMuted = true;
    }
    LoggerService.i('WebRtc', 'Deafened: $_isDeafened');
  }

  @override
  Future<void> setAudioOnly(bool audioOnly) async {
    _isAudioOnly = audioOnly;
    if (audioOnly) {
      _isCameraEnabled = false;
    }
    LoggerService.i('WebRtc', 'Audio-only mode: $audioOnly');
  }

  @override
  Future<void> dispose() async {
    _levelSimulator?.cancel();
    _setState(WebRtcState.idle);
    await _stateController.close();
    await _audioLevelController.close();
    LoggerService.i('WebRtc', 'Disposed WebRTC media resources cleanly');
  }
}
