import 'dart:math';
import 'package:uuid/uuid.dart';
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

  @override
  Future<UserProfile> getCurrentUser() async {
    final raw = _storage.getString(_userKey);
    if (raw != null) {
      try {
        return UserProfile.fromJson(raw);
      } catch (_) {}
    }
    // Automatically provision guest identity if first time
    return createGuestUser();
  }

  @override
  Future<UserProfile> createGuestUser({String? name}) async {
    final randomName =
        name ?? _coolNicknames[Random().nextInt(_coolNicknames.length)];
    final user = UserProfile(
      id: 'usr_${const Uuid().v4().substring(0, 8)}',
      name: randomName,
      isGuest: true,
      statusMessage: 'Chilling at Adda ☕️',
      createdAt: DateTime.now(),
    );
    await _storage.setString(_userKey, user.toJson());
    return user;
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? statusMessage,
  }) async {
    final current = await getCurrentUser();
    final updated = current.copyWith(
      name: name ?? current.name,
      avatarUrl: avatarUrl ?? current.avatarUrl,
      statusMessage: statusMessage ?? current.statusMessage,
    );
    await _storage.setString(_userKey, updated.toJson());
    return updated;
  }

  @override
  Future<void> logout() async {
    await _storage.remove(_userKey);
  }
}
