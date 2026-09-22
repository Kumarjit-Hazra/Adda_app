import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/home/application/daily_providers.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/core/storage/storage_service.dart';

class MockStorage extends StorageService {
  final Map<String, String> _data = {};
  @override
  String? getString(String key) => _data[key];
  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
}

void main() {
  group('DailyStateNotifier', () {
    late ProviderContainer container;
    late MockStorage storage;

    setUp(() {
      storage = MockStorage();
      container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
    });

    test('increments streak ONLY when BOTH are completed', () async {
      final notifier = container.read(dailyStateProvider.notifier);
      // wait for load
      await Future.delayed(Duration.zero);

      var state = container.read(dailyStateProvider).value!;
      expect(state.streakCount, 0);
      expect(state.isAddaAnswered, false);
      expect(state.isBrainCompleted, false);

      // Completing one does NOT increment streak
      await notifier.markAddaAnswered();
      state = container.read(dailyStateProvider).value!;
      expect(state.isAddaAnswered, true);
      expect(state.streakCount, 0);

      // Completing second one DOES increment streak exactly once
      await notifier.markBrainCompleted();
      state = container.read(dailyStateProvider).value!;
      expect(state.isBrainCompleted, true);
      expect(state.streakCount, 1);

      // Duplicate calls do nothing
      await notifier.markAddaAnswered();
      await notifier.markBrainCompleted();
      state = container.read(dailyStateProvider).value!;
      expect(state.streakCount, 1);
    });
  });
}
