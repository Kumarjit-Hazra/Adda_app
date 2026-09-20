import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/haptics/haptics_service.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final StorageService _storage;
  static const String _userKey = 'adda_current_user_profile';

  AuthRepositoryImpl(this._storage);

  static const List<String> _coolNicknames = [
    'PixelNomad',
    'MidnightRider',
    'CosmicChai',
    'AddaCaptain',
    'StarlightJoker',
    'SonicSurfer',
    'VelvetDreamer',
    'ThunderRaven',
    'NeonWhisper',
    'GoldenPhoenix',
  ];

  static const List<String> defaultAvatarSeeds = [
    'seed_chai',
    'seed_tiger',
    'seed_phoenix',
    'seed_bluff',
    'seed_cosmic',
    'seed_neon',
    'seed_wizard',
    'seed_joker',
  ];

  @override
  Future<UserProfile> getCurrentUser() async {
    final raw = _storage.getString(_userKey);
    if (raw != null) {
      try {
        final user = UserProfile.fromJson(raw);
        // Ensure avatarSeed and preferences are initialized for legacy profiles
        if (user.avatarSeed == null) {
          final upgraded = user.copyWith(
            avatarSeed: 'seed_${user.id.replaceAll('usr_', '')}',
          );
          await _storage.setString(_userKey, upgraded.toJson());
          _syncServicesWithPreferences(upgraded.preferences);
          return upgraded;
        }
        _syncServicesWithPreferences(user.preferences);
        return user;
      } catch (_) {}
    }
    // Automatically provision guest identity if first time
    return createGuestUser();
  }

  @override
  Future<UserProfile> createGuestUser({
    String? name,
    String? avatarSeed,
  }) async {
    final randomName =
        name ?? _coolNicknames[Random().nextInt(_coolNicknames.length)];
    final initialSeed =
        avatarSeed ??
        defaultAvatarSeeds[Random().nextInt(defaultAvatarSeeds.length)];
    const initialPrefs = UserPreferences(
      themeMode: 'dark',
      soundEnabled: true,
      hapticsEnabled: true,
      reducedMotion: false,
    );

    final user = UserProfile(
      id: 'usr_${const Uuid().v4().substring(0, 8)}',
      name: randomName,
      isGuest: true,
      avatarSeed: initialSeed,
      statusMessage: 'Chilling at Adda ☕️',
      preferences: initialPrefs,
      createdAt: DateTime.now(),
    );
    await _storage.setString(_userKey, user.toJson());
    _syncServicesWithPreferences(initialPrefs);
    return user;
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarSeed,
    String? statusMessage,
    UserPreferences? preferences,
  }) async {
    final current = await getCurrentUser();
    final updated = current.copyWith(
      name: name ?? current.name,
      avatarUrl: avatarUrl ?? current.avatarUrl,
      avatarSeed: avatarSeed ?? current.avatarSeed,
      statusMessage: statusMessage ?? current.statusMessage,
      preferences: preferences ?? current.preferences,
    );
    await _storage.setString(_userKey, updated.toJson());
    if (preferences != null) {
      _syncServicesWithPreferences(updated.preferences);
    }
    return updated;
  }

  void _syncServicesWithPreferences(UserPreferences prefs) {
    AudioService.sfxEnabled = prefs.soundEnabled;
    HapticsService.enabled = prefs.hapticsEnabled;
  }

  @override
  Future<void> logout() async {
    await _storage.remove(_userKey);
  }
}
