import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/space_model.dart';
import '../../domain/repositories/space_repository.dart';
import '../../data/space_repository_impl.dart';

final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SpaceRepositoryImpl(storage);
});

class SpaceNotifier extends StateNotifier<AsyncValue<List<SpaceModel>>> {
  final SpaceRepository _repository;

  SpaceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSpaces();
  }

  Future<void> loadSpaces() async {
    state = const AsyncValue.loading();
    try {
      final spaces = await _repository.getSpaces();
      state = AsyncValue.data(spaces);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SpaceModel> createSpace({
    required String name,
    required SpaceType type,
    String? description,
    required String ownerId,
  }) async {
    final space = await _repository.createSpace(
      name: name,
      type: type,
      description: description,
      ownerId: ownerId,
    );
    await loadSpaces();
    return space;
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    await loadSpaces();
  }

  Future<void> deleteSpace(String id) async {
    await _repository.deleteSpace(id);
    await loadSpaces();
  }
}

final spacesProvider =
    StateNotifierProvider<SpaceNotifier, AsyncValue<List<SpaceModel>>>((ref) {
      final repo = ref.watch(spaceRepositoryProvider);
      return SpaceNotifier(repo);
    });

final spaceByIdProvider = FutureProvider.family<SpaceModel?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(spaceRepositoryProvider);
  return repo.getSpaceById(id);
});
