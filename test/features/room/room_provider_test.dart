import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/auth/domain/models/user_profile.dart';
import 'package:adda/features/auth/domain/repositories/auth_repository.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';
import 'package:adda/features/room/presentation/providers/room_provider.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile> getCurrentUser() async => UserProfile(
    id: 'test_user_1',
    name: 'Test Gamer',
    createdAt: DateTime.now(),
  );

  @override
  Future<UserProfile> createGuestUser({
    String? name,
    String? avatarSeed,
  }) async => UserProfile(
    id: 'test_user_1',
    name: name ?? 'Test Gamer',
    avatarSeed: avatarSeed ?? 'seed_chai',
    createdAt: DateTime.now(),
  );

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarSeed,
    String? statusMessage,
    UserPreferences? preferences,
  }) async {
    return UserProfile(
      id: 'test_user_1',
      name: name ?? 'Test Gamer',
      avatarUrl: avatarUrl,
      avatarSeed: avatarSeed ?? 'seed_chai',
      statusMessage: statusMessage,
      preferences: preferences ?? const UserPreferences(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoomNotifier & Voice Decoupling Tests', () {
    late ProviderContainer container;
    late RoomNotifier notifier;

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      await container.read(authProvider.notifier).loadUser();
      notifier = container.read(roomProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'entering room in solo mode sets isSoloMode and voice is NOT joined',
      () async {
        await notifier.joinRoom(
          spaceId: 'space_uno_1',
          spaceName: 'Chai Adda',
          isSoloMode: true,
          autoJoinVoice: false,
        );

        final state = notifier.state!;
        expect(state.isSoloMode, isTrue);
        expect(state.isVoiceJoined, isFalse);
        expect(state.participants.any((p) => p.name.contains('Bot')), isTrue);
        expect(state.chatMessages.first.content, contains('Solo practice'));
      },
    );

    test('voice chat can be joined and left on-demand', () async {
      await notifier.joinRoom(
        spaceId: 'space_friends_2',
        spaceName: 'Gaming Adda',
        isSoloMode: false,
        autoJoinVoice: false,
      );

      expect(notifier.state!.isVoiceJoined, isFalse);

      await notifier.joinVoiceChat();
      expect(notifier.state!.isVoiceJoined, isTrue);

      await notifier.leaveVoiceChat();
      expect(notifier.state!.isVoiceJoined, isFalse);

      await notifier.toggleVoiceChat();
      expect(notifier.state!.isVoiceJoined, isTrue);
    });

    test('setting active activity updates state cleanly', () async {
      await notifier.joinRoom(spaceId: 'space_3', spaceName: 'Card Lounge');

      notifier.setActiveActivity('twenty_nine');
      expect(notifier.state!.activeActivityId, 'twenty_nine');

      notifier.setActiveActivity(null);
      expect(notifier.state!.activeActivityId, isNull);
    });
  });
}
