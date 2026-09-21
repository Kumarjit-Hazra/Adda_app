import 'dart:async';
import '../logging/logger_service.dart';
import '../permissions/permission_service.dart';

enum WebRtcState {
  idle,
  connecting,
  connected,
  reconnecting,
  failed,
  disconnected,
}

abstract class WebRtcService {
  WebRtcState get state;
  Stream<WebRtcState> get stateStream;
  bool get isMicMuted;
  bool get isCameraEnabled;
  bool get isDeafened;
  Stream<double> get localAudioLevelStream;

  Future<void> initializeMedia(PermissionService permissionService);
  Future<void> stopMedia();
  Future<void> toggleMic(PermissionService permissionService);
  Future<void> toggleCamera(PermissionService permissionService);
  Future<void> toggleDeafen();
  Future<void> setAudioOnly(bool audioOnly);
  Future<void> dispose();
}

/// Robust WebRTC abstraction supporting smooth simulated voice & camera feeds across platforms.
class DefaultWebRtcService implements WebRtcService {
  WebRtcState _state = WebRtcState.idle;
  StreamController<WebRtcState> _stateController =
      StreamController<WebRtcState>.broadcast();
  StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();

  void _ensureControllers() {
    if (_stateController.isClosed) {
      _stateController = StreamController<WebRtcState>.broadcast();
    }
    if (_audioLevelController.isClosed) {
      _audioLevelController = StreamController<double>.broadcast();
    }
  }

  bool _isMicMuted = true;
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
  Future<void> initializeMedia(PermissionService permissionService) async {
    if (_state == WebRtcState.connecting || _state == WebRtcState.connected) {
      return; // Already connecting or connected
    }
    _ensureControllers();
    _setState(WebRtcState.connecting);
    LoggerService.i('WebRtc', 'Initializing audio & video media session');

    try {
      final micPermission = await permissionService
          .requestMicrophonePermission();
      if (micPermission == MediaPermissionState.granted) {
        _isMicMuted = false;
      } else {
        _isMicMuted = true; // Fallback gracefully if microphone is denied
        LoggerService.w(
          'WebRtc',
          'Microphone permission denied, joining muted',
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));
      _setState(WebRtcState.connected);

      // Simulate real audio voice activity detection (VAD)
      _levelSimulator?.cancel();
      _levelSimulator = Timer.periodic(const Duration(milliseconds: 250), (
        timer,
      ) {
        if (_audioLevelController.isClosed) return;
        if (_state == WebRtcState.connected && !_isMicMuted && !_isDeafened) {
          // Output audio level 0.0 to 1.0
          final level = (DateTime.now().millisecond % 100) / 100.0;
          _audioLevelController.add(level);
        } else {
          _audioLevelController.add(0.0);
        }
      });
    } catch (e) {
      _setState(WebRtcState.failed);
      LoggerService.e('WebRtc', 'Failed to initialize media', e);
      throw Exception('Media initialization failed: $e');
    }
  }

  void _setState(WebRtcState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(_state);
      }
    }
  }

  @override
  Future<void> toggleMic(PermissionService permissionService) async {
    if (_isMicMuted) {
      // If we are trying to unmute, we must ensure we have permission
      final micPermission = await permissionService
          .requestMicrophonePermission();
      if (micPermission != MediaPermissionState.granted) {
        LoggerService.w(
          'WebRtc',
          'Cannot unmute: Microphone permission denied',
        );
        throw Exception('Microphone permission denied');
      }
      _isMicMuted = false;
    } else {
      _isMicMuted = true;
    }
    LoggerService.i('WebRtc', 'Mic muted: $_isMicMuted');
  }

  @override
  Future<void> toggleCamera(PermissionService permissionService) async {
    if (_isAudioOnly) return;

    if (!_isCameraEnabled) {
      // If we are trying to enable camera, we must ensure we have permission
      final cameraPermission = await permissionService
          .requestCameraPermission();
      if (cameraPermission != MediaPermissionState.granted) {
        LoggerService.w(
          'WebRtc',
          'Cannot enable camera: Camera permission denied',
        );
        throw Exception('Camera permission denied');
      }
      _isCameraEnabled = true;
    } else {
      _isCameraEnabled = false;
    }
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
  Future<void> stopMedia() async {
    _levelSimulator?.cancel();
    _setState(WebRtcState.disconnected);
    _isCameraEnabled = false;
    _isMicMuted = true;
    LoggerService.i('WebRtc', 'Stopped WebRTC media session');
  }

  @override
  Future<void> dispose() async {
    await stopMedia();
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_audioLevelController.isClosed) {
      await _audioLevelController.close();
    }
    LoggerService.i('WebRtc', 'Disposed WebRTC media resources cleanly');
  }
}
