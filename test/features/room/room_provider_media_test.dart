import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/room/presentation/providers/room_provider.dart';
import 'package:adda/core/webrtc/webrtc_service.dart';
import 'package:adda/core/permissions/permission_service.dart';
import 'package:adda/core/realtime/signaling_service.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';
import 'package:adda/features/auth/domain/models/user_profile.dart';
import 'package:adda/features/auth/domain/repositories/auth_repository.dart';

class MockSignaling extends SimulatedSignalingService {}

class MockWebRtc extends DefaultWebRtcService {}

class MockPermissions implements PermissionService {
  @override
  Future<MediaPermissionState> checkMicrophonePermission() async =>
      MediaPermissionState.granted;
  @override
  Future<MediaPermissionState> requestMicrophonePermission() async =>
      MediaPermissionState.granted;
  @override
  Future<MediaPermissionState> checkCameraPermission() async =>
      MediaPermissionState.granted;
  @override
  Future<MediaPermissionState> requestCameraPermission() async =>
      MediaPermissionState.granted;
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserProfile> createGuestUser({
    String? name,
    String? avatarSeed,
  }) async {
    return UserProfile(
      id: 'test_user',
      name: 'Test',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    return UserProfile(
      id: 'test_user',
      name: 'Test',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarSeed,
    String? statusMessage,
    UserPreferences? preferences,
  }) async {
    return UserProfile(
      id: 'test_user',
      name: 'Test',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  group('RoomNotifier Media Tests', () {
    late ProviderContainer container;

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          signalingServiceProvider.overrideWithValue(MockSignaling()),
          webrtcServiceProvider.overrideWithValue(MockWebRtc()),
          permissionServiceProvider.overrideWithValue(MockPermissions()),
        ],
      );
      // Wait for auth provider to load
      await container.read(authProvider.notifier).loadUser();
    });

    test(
      'joinRoom does not automatically start media unless autoJoinVoice is true',
      () async {
        final notifier = container.read(roomProvider.notifier);
        await notifier.joinRoom(
          spaceId: 'space1',
          spaceName: 'Test Space',
          autoJoinVoice: false,
        );

        final state = container.read(roomProvider);
        expect(state, isNotNull);
        expect(state!.isVoiceJoined, false);
        expect(state.isMicEnabled, false);

        // The WebRTC service should be idle
        final rtc = container.read(webrtcServiceProvider);
        expect(rtc.state, WebRtcState.idle);
      },
    );

    test('joinRoom starts media when autoJoinVoice is true', () async {
      final notifier = container.read(roomProvider.notifier);
      await notifier.joinRoom(
        spaceId: 'space1',
        spaceName: 'Test Space',
        autoJoinVoice: true,
      );

      final state = container.read(roomProvider);
      expect(state, isNotNull);
      expect(state!.isVoiceJoined, true);
      expect(state.isMicEnabled, true);

      // The WebRTC service should be connected
      final rtc = container.read(webrtcServiceProvider);
      expect(rtc.state, WebRtcState.connected);
    });

    test('Solo mode never joins voice', () async {
      final notifier = container.read(roomProvider.notifier);
      await notifier.joinRoom(
        spaceId: 'space1',
        spaceName: 'Test Space',
        autoJoinVoice: true,
        isSoloMode: true,
      );

      final state = container.read(roomProvider);
      expect(state, isNotNull);
      expect(state!.isVoiceJoined, false); // Blocked by isSoloMode in provider
    });
  });
}
