import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_service.dart';
import '../domain/models/daily_state.dart';
import '../data/daily_repository.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.watch(storageServiceProvider));
});

class DailyStateNotifier extends StateNotifier<AsyncValue<DailyState>> {
  final DailyRepository _repository;

  DailyStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadState();
  }

  Future<void> _loadState() async {
    state = const AsyncValue.loading();
    try {
      final dailyState = await _repository.getDailyState();
      state = AsyncValue.data(dailyState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAddaAnswered() async {
    if (state.value == null) return;

    final currentState = state.value!;
    if (currentState.isAddaAnswered) return;

    final newState = currentState.copyWith(isAddaAnswered: true);

    // Check if both are now completed to bump streak
    DailyState finalState = newState;
    if (newState.isAddaAnswered && newState.isBrainCompleted) {
      finalState = newState.copyWith(streakCount: newState.streakCount + 1);
    }

    state = AsyncValue.data(finalState);
    await _repository.saveDailyState(finalState);
  }

  Future<void> markBrainCompleted() async {
    if (state.value == null) return;

    final currentState = state.value!;
    if (currentState.isBrainCompleted) return;

    final newState = currentState.copyWith(isBrainCompleted: true);

    // Check if both are now completed to bump streak
    DailyState finalState = newState;
    if (newState.isAddaAnswered && newState.isBrainCompleted) {
      finalState = newState.copyWith(streakCount: newState.streakCount + 1);
    }

    state = AsyncValue.data(finalState);
    await _repository.saveDailyState(finalState);
  }
}

final dailyStateProvider =
    StateNotifierProvider<DailyStateNotifier, AsyncValue<DailyState>>((ref) {
      return DailyStateNotifier(ref.watch(dailyRepositoryProvider));
    });
