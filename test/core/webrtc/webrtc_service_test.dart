import 'package:flutter_test/flutter_test.dart';
import 'package:adda/core/webrtc/webrtc_service.dart';
import 'package:adda/core/permissions/permission_service.dart';

class MockPermissionService implements PermissionService {
  MediaPermissionState micState = MediaPermissionState.granted;
  MediaPermissionState cameraState = MediaPermissionState.granted;

  @override
  Future<MediaPermissionState> checkMicrophonePermission() async => micState;
  @override
  Future<MediaPermissionState> requestMicrophonePermission() async => micState;
  @override
  Future<MediaPermissionState> checkCameraPermission() async => cameraState;
  @override
  Future<MediaPermissionState> requestCameraPermission() async => cameraState;
}

void main() {
  group('WebRtcService Tests', () {
    late DefaultWebRtcService webrtc;
    late MockPermissionService permissions;

    setUp(() {
      webrtc = DefaultWebRtcService();
      permissions = MockPermissionService();
    });

    test('initial state is idle', () {
      expect(webrtc.state, WebRtcState.idle);
      expect(webrtc.isMicMuted, true);
      expect(webrtc.isCameraEnabled, false);
    });

    test('initializeMedia sets connected and handles permissions', () async {
      await webrtc.initializeMedia(permissions);
      expect(webrtc.state, WebRtcState.connected);
      expect(webrtc.isMicMuted, false); // Mic granted
    });

    test('initializeMedia handles denied permissions gracefully', () async {
      permissions.micState = MediaPermissionState.denied;
      await webrtc.initializeMedia(permissions);
      expect(webrtc.state, WebRtcState.connected);
      expect(webrtc.isMicMuted, true); // Mic denied
    });

    test('stopMedia resets to disconnected', () async {
      await webrtc.initializeMedia(permissions);
      await webrtc.stopMedia();
      expect(webrtc.state, WebRtcState.disconnected);
      expect(webrtc.isMicMuted, true);
      expect(webrtc.isCameraEnabled, false);
    });

    test('toggleCamera respects permission', () async {
      await webrtc.initializeMedia(permissions);
      await webrtc.toggleCamera(permissions);
      expect(webrtc.isCameraEnabled, true);

      // Now pretend permission is revoked, wait, we can't do that easily during the same toggle without a new mock state,
      // but if we toggle again it just disables it.
      await webrtc.toggleCamera(permissions);
      expect(webrtc.isCameraEnabled, false);
    });

    test('toggleCamera throws if permission denied', () async {
      permissions.cameraState = MediaPermissionState.denied;
      await webrtc.initializeMedia(permissions);
      expect(
        () async => await webrtc.toggleCamera(permissions),
        throwsException,
      );
    });
  });
}
