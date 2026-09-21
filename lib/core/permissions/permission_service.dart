import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionState {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
  requestInProgress,
}

abstract class PermissionService {
  Future<MediaPermissionState> checkMicrophonePermission();
  Future<MediaPermissionState> requestMicrophonePermission();
  Future<MediaPermissionState> checkCameraPermission();
  Future<MediaPermissionState> requestCameraPermission();
}

class DefaultPermissionService implements PermissionService {
  @override
  Future<MediaPermissionState> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return _mapStatus(status);
  }

  @override
  Future<MediaPermissionState> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return _mapStatus(status);
  }

  @override
  Future<MediaPermissionState> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return _mapStatus(status);
  }

  @override
  Future<MediaPermissionState> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return _mapStatus(status);
  }

  MediaPermissionState _mapStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return MediaPermissionState.granted;
      case PermissionStatus.denied:
        return MediaPermissionState.denied;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return MediaPermissionState.permanentlyDenied;
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return MediaPermissionState.granted;
    }
  }
}
