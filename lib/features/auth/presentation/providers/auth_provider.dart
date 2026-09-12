import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/auth_repository_impl.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthRepositoryImpl(storage);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUser();
  }

  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? statusMessage,
  }) async {
    try {
      final updated = await _repository.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
        statusMessage: statusMessage,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> regenerateGuest() async {
    try {
      final user = await _repository.createGuestUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile>>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return AuthNotifier(repo);
    });
