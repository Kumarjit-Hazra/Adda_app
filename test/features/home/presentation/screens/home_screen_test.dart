import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/home/presentation/screens/home_screen.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart' hide storageServiceProvider;
import 'package:adda/features/room/presentation/providers/room_provider.dart';
import 'package:adda/features/spaces/presentation/providers/space_provider.dart';
import 'package:adda/features/home/application/daily_providers.dart';
import 'package:adda/features/auth/domain/models/user_profile.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/auth/domain/repositories/auth_repository.dart';
import 'package:adda/features/spaces/domain/repositories/space_repository.dart';
import 'package:adda/core/realtime/signaling_service.dart';
import 'package:adda/core/webrtc/webrtc_service.dart';
import 'package:adda/core/permissions/permission_service.dart';

void main() {
  testWidgets('HomeScreen renders new Phase 9 sections gracefully', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier()),
          roomProvider.overrideWith((ref) => MockRoomNotifier()), // No active room
          spacesProvider.overrideWith((ref) => MockSpaceNotifier()),
          storageServiceProvider.overrideWithValue(MockStorage()),
          dailyStateProvider.overrideWith(
            (ref) => MockDailyNotifier(ref.watch(dailyRepositoryProvider)),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Wait for initial render
    await tester.pump();

    // Verify header exists
    expect(find.textContaining('Test User'), findsWidgets);

    // Verify Daily Adda exists
    expect(find.text('TODAY\'S ADDA'), findsOneWidget);

    // Verify Quick Play exists
    expect(find.text('Quick Play 🚀'), findsOneWidget);
  });
}

class MockStorage extends StorageService {
  @override
  String? getString(String key) => null;
  @override
  Future<bool> setString(String key, String value) async => true;
}

class MockDailyNotifier extends DailyStateNotifier {
  MockDailyNotifier(super.repository) {
    state = const AsyncValue.data(
      DailyState(dateId: '2026-09-20', dailyPrompt: 'Test'),
    );
  }
}

class FakeAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSignaling implements SignalingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebRtc implements WebRtcService {
  @override
  Stream<WebRtcState> get stateStream => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePermission implements PermissionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSpaceRepo implements SpaceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier() : super(FakeAuthRepo()) {
    state = AsyncValue.data(UserProfile(id: '1', name: 'Test User', createdAt: DateTime.now()));
  }
}

class MockRoomNotifier extends RoomNotifier {
  MockRoomNotifier() : super(FakeSignaling(), FakeWebRtc(), FakePermission(), FakeRef()) {
    state = null;
  }
}

class MockSpaceNotifier extends SpaceNotifier {
  MockSpaceNotifier() : super(FakeSpaceRepo()) {
    state = const AsyncValue.data([]);
  }
}
