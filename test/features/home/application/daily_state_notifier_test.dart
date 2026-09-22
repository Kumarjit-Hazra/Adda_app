import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/home/application/daily_providers.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/core/storage/storage_service.dart';

// ---------------------------------------------------------------------------
// Fake storage
// ---------------------------------------------------------------------------

class MockStorage extends StorageService {
  final Map<String, String> _data = {};
  bool throwOnRead = false;
  bool throwOnWrite = false;

  @override
  String? getString(String key) {
    if (throwOnRead) throw Exception('simulated read failure');
    return _data[key];
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (throwOnWrite) throw Exception('simulated write failure');
    _data[key] = value;
    return true;
  }

  String? stored(String key) => _data[key];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(MockStorage storage) {
  return ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
  );
}

Future<DailyState> _loadedState(ProviderContainer container) async {
  // Yield multiple microtasks to allow the async load (and any subsequent
  // saves) to complete before we read state.
  for (var i = 0; i < 10; i++) {
    await Future.delayed(Duration.zero);
    final async = container.read(dailyStateProvider);
    if (async is AsyncData<DailyState>) return async.value;
  }
  throw StateError('dailyStateProvider did not resolve to data in time');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DailyStateNotifier', () {
    late ProviderContainer container;
    late MockStorage storage;

    setUp(() {
      storage = MockStorage();
      container = _makeContainer(storage);
    });

    tearDown(() => container.dispose());

    // -----------------------------------------------------------------------
    // Loading
    // -----------------------------------------------------------------------

    test(
      'initial state is loading then resolves to fresh DailyState',
      () async {
        expect(container.read(dailyStateProvider), isA<AsyncLoading>());
        final state = await _loadedState(container);
        expect(state.isAddaAnswered, false);
        expect(state.isBrainCompleted, false);
        expect(state.streakCount, 0);
      },
    );

    test('repository read failure — DailyRepository catches internally, '
        'notifier resolves to AsyncData with fresh state', () async {
      storage.throwOnRead = true;
      // DailyRepository catches read errors internally and returns a fresh
      // DailyState. The write also fails silently. The notifier therefore
      // resolves to AsyncData, not AsyncError.
      final state = await _loadedState(container);
      expect(state.streakCount, 0);
      expect(state.isAddaAnswered, false);
    });

    // -----------------------------------------------------------------------
    // Adda completion
    // -----------------------------------------------------------------------

    test(
      'markAddaAnswered — sets isAddaAnswered true, streak stays 0',
      () async {
        final notifier = container.read(dailyStateProvider.notifier);
        await _loadedState(container);

        await notifier.markAddaAnswered();

        final state = container.read(dailyStateProvider).value!;
        expect(state.isAddaAnswered, true);
        expect(state.isBrainCompleted, false);
        expect(state.streakCount, 0); // Only one activity done
      },
    );

    test('markAddaAnswered duplicate — is a no-op', () async {
      final notifier = container.read(dailyStateProvider.notifier);
      await _loadedState(container);

      await notifier.markAddaAnswered();
      await notifier.markAddaAnswered(); // Second call

      final state = container.read(dailyStateProvider).value!;
      expect(state.isAddaAnswered, true);
      expect(state.streakCount, 0); // Brain not done yet — streak stays 0
    });

    // -----------------------------------------------------------------------
    // Brain completion
    // -----------------------------------------------------------------------

    test(
      'markBrainCompleted — sets isBrainCompleted true, streak stays 0',
      () async {
        final notifier = container.read(dailyStateProvider.notifier);
        await _loadedState(container);

        await notifier.markBrainCompleted();

        final state = container.read(dailyStateProvider).value!;
        expect(state.isBrainCompleted, true);
        expect(state.isAddaAnswered, false);
        expect(state.streakCount, 0);
      },
    );

    test('markBrainCompleted duplicate — is a no-op', () async {
      final notifier = container.read(dailyStateProvider.notifier);
      await _loadedState(container);

      await notifier.markBrainCompleted();
      await notifier.markBrainCompleted();

      final state = container.read(dailyStateProvider).value!;
      expect(state.isBrainCompleted, true);
      expect(state.streakCount, 0);
    });

    // -----------------------------------------------------------------------
    // Streak increment
    // -----------------------------------------------------------------------

    test('both completed — streak increments to 1', () async {
      final notifier = container.read(dailyStateProvider.notifier);
      await _loadedState(container);

      await notifier.markAddaAnswered();
      await notifier.markBrainCompleted();

      final state = container.read(dailyStateProvider).value!;
      expect(state.isAddaAnswered, true);
      expect(state.isBrainCompleted, true);
      expect(state.streakCount, 1);
    });

    test('both completed in reverse order — streak increments to 1', () async {
      final notifier = container.read(dailyStateProvider.notifier);
      await _loadedState(container);

      await notifier.markBrainCompleted();
      await notifier.markAddaAnswered();

      final state = container.read(dailyStateProvider).value!;
      expect(state.streakCount, 1);
    });

    test(
      'streak increments exactly once — duplicates have no effect',
      () async {
        final notifier = container.read(dailyStateProvider.notifier);
        await _loadedState(container);

        await notifier.markAddaAnswered();
        await notifier.markBrainCompleted();
        // Duplicate calls
        await notifier.markAddaAnswered();
        await notifier.markBrainCompleted();

        final state = container.read(dailyStateProvider).value!;
        expect(state.streakCount, 1);
      },
    );

    test('opening app / loading does NOT increment streak', () async {
      // Just loading the provider with no explicit completion should never
      // change streakCount from 0.
      final state = await _loadedState(container);
      expect(state.streakCount, 0);
    });

    // -----------------------------------------------------------------------
    // Persistence
    // -----------------------------------------------------------------------

    test(
      'after both completed — persistence called with correct final state',
      () async {
        final notifier = container.read(dailyStateProvider.notifier);
        await _loadedState(container);

        await notifier.markAddaAnswered();
        await notifier.markBrainCompleted();

        // Verify stored JSON reflects the final state.
        final stored = storage.stored('daily_state_v1');
        expect(stored, isNotNull);
        final decoded = DailyState.fromJson(
          Map<String, dynamic>.from(jsonDecode(stored!) as Map),
        );
        expect(decoded.isAddaAnswered, true);
        expect(decoded.isBrainCompleted, true);
        expect(decoded.streakCount, 1);
      },
    );

    test(
      'write failure during completion — state in memory is still updated',
      () async {
        final notifier = container.read(dailyStateProvider.notifier);
        await _loadedState(container);

        storage.throwOnWrite = true; // Future writes fail

        // Should not throw.
        await notifier.markAddaAnswered();
        await notifier.markBrainCompleted();

        // In-memory state is still correct even if persistence failed.
        final state = container.read(dailyStateProvider).value!;
        expect(state.isAddaAnswered, true);
        expect(state.isBrainCompleted, true);
        expect(state.streakCount, 1);
      },
    );
  });
}
