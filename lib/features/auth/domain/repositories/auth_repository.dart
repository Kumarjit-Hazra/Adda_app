import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> getCurrentUser();
  Future<UserProfile> createGuestUser({String? name});
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? statusMessage,
  });
  Future<void> logout();
}
