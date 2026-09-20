import 'package:flutter_test/flutter_test.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/auth/data/auth_repository_impl.dart';
import 'package:adda/features/auth/domain/models/user_profile.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late AuthRepositoryImpl repository;

  setUp(() async {
    storage = StorageService();
    await storage.init();
    await storage.clear();
    repository = AuthRepositoryImpl(storage);
  });

  group('Guest Identity Model & Persistence Tests', () {
    test(
      '1. Guest identity is created with valid fields when none exists',
      () async {
        final user = await repository.getCurrentUser();

        expect(user.id.startsWith('usr_'), isTrue);
        expect(user.guestUuid, equals(user.id));
        expect(user.name.isNotEmpty, isTrue);
        expect(user.displayName, equals(user.name));
        expect(user.isGuest, isTrue);
        expect(user.avatarSeed, isNotNull);
        expect(user.preferences.themeMode, equals('dark'));
        expect(user.preferences.soundEnabled, isTrue);
        expect(user.preferences.hapticsEnabled, isTrue);
      },
    );

    test('2. Guest identity persists across reload/reinitialization', () async {
      final firstUser = await repository.getCurrentUser();

      // Create a fresh repository reading from the same storage
      final reloadedRepo = AuthRepositoryImpl(storage);
      final reloadedUser = await reloadedRepo.getCurrentUser();

      expect(reloadedUser.id, equals(firstUser.id));
      expect(reloadedUser.name, equals(firstUser.name));
      expect(reloadedUser.avatarSeed, equals(firstUser.avatarSeed));
      expect(reloadedUser.preferences, equals(firstUser.preferences));
    });

    test('3. Display name can be changed and persists', () async {
      final initial = await repository.getCurrentUser();
      const updatedName = 'NeonSamurai';

      final updated = await repository.updateProfile(name: updatedName);
      expect(updated.name, equals(updatedName));
      expect(updated.displayName, equals(updatedName));
      expect(updated.id, equals(initial.id));

      // Verify persistence in storage
      final reloaded = await AuthRepositoryImpl(storage).getCurrentUser();
      expect(reloaded.name, equals(updatedName));
    });

    test('4. Avatar seed can be changed and persists', () async {
      await repository.getCurrentUser();
      const newSeed = 'seed_tiger';

      final updated = await repository.updateProfile(avatarSeed: newSeed);
      expect(updated.avatarSeed, equals(newSeed));

      // Verify persistence in storage
      final reloaded = await AuthRepositoryImpl(storage).getCurrentUser();
      expect(reloaded.avatarSeed, equals(newSeed));
    });

    test('5. Preferences persist across storage re-reads', () async {
      await repository.getCurrentUser();
      const customPrefs = UserPreferences(
        themeMode: 'light',
        soundEnabled: false,
        hapticsEnabled: false,
        reducedMotion: true,
      );

      final updated = await repository.updateProfile(preferences: customPrefs);
      expect(updated.preferences.themeMode, equals('light'));
      expect(updated.preferences.soundEnabled, isFalse);
      expect(updated.preferences.hapticsEnabled, isFalse);
      expect(updated.preferences.reducedMotion, isTrue);

      // Verify persistence in storage
      final reloaded = await AuthRepositoryImpl(storage).getCurrentUser();
      expect(reloaded.preferences, equals(customPrefs));
    });

    test(
      '6. UserPreferences serialization and deserialization retains integrity',
      () {
        const prefs = UserPreferences(
          themeMode: 'dark',
          soundEnabled: false,
          hapticsEnabled: true,
          reducedMotion: false,
        );

        final map = prefs.toMap();
        final fromMap = UserPreferences.fromMap(map);

        expect(fromMap, equals(prefs));
        expect(fromMap.hashCode, equals(prefs.hashCode));
      },
    );
  });

  group('AuthNotifier Reactive Updates Tests', () {
    test('Identity provider updates reactively on profile changes', () async {
      final notifier = AuthNotifier(repository);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.hasValue, isTrue);
      final initialName = notifier.state.value!.name;

      // Update name
      await notifier.updateProfile(name: 'CosmicCaptain');
      expect(notifier.state.value!.name, equals('CosmicCaptain'));
      expect(notifier.state.value!.name, isNot(equals(initialName)));

      // Update avatar seed
      await notifier.updateAvatarSeed('seed_phoenix');
      expect(notifier.state.value!.avatarSeed, equals('seed_phoenix'));

      // Update preferences
      const newPrefs = UserPreferences(
        themeMode: 'light',
        soundEnabled: false,
        hapticsEnabled: true,
      );
      await notifier.updatePreferences(newPrefs);
      expect(notifier.state.value!.preferences.themeMode, equals('light'));
      expect(notifier.state.value!.preferences.soundEnabled, isFalse);
    });

    test(
      'Regenerate guest produces new credentials and updates state',
      () async {
        final notifier = AuthNotifier(repository);
        await Future.delayed(const Duration(milliseconds: 50));
        final initialId = notifier.state.value!.id;

        await notifier.regenerateGuest();
        expect(notifier.state.value!.id, isNot(equals(initialId)));
        expect(notifier.state.value!.id.startsWith('usr_'), isTrue);
      },
    );
  });
}
