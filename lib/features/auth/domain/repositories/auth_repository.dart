import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> getCurrentUser();
  Future<UserProfile> createGuestUser({String? name, String? avatarSeed});
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarSeed,
    String? statusMessage,
    UserPreferences? preferences,
  });
  Future<void> logout();
}
