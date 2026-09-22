import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/core/storage/storage_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _InMemoryStorage extends StorageService {
  final Map<String, String> _data = {};
  bool throwOnRead = false;
  bool throwOnWrite = false;

  @override
  String? getString(String key) {
    if (throwOnRead) throw Exception('read failure');
    return _data[key];
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (throwOnWrite) throw Exception('write failure');
    _data[key] = value;
    return true;
  }

  void seed(String key, String value) => _data[key] = value;
}

String _todayId() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // DailyStreakCalculator
  // -------------------------------------------------------------------------
  group('DailyStreakCalculator', () {
    test('same day — returns currentState unchanged', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Q',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-20',
        currentPrompt: 'Q',
      );
      expect(result.streakCount, 5);
      expect(result.dateId, '2026-09-20');
    });

    test('next day + both completed yesterday — maintains streak', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Q',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-21',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 5);
      expect(result.dateId, '2026-09-21');
    });

    test('next day + only Adda completed — streak resets', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Q',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: false,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-21',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 0);
    });

    test('next day + nothing completed — streak resets', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Q',
        streakCount: 7,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-21',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 0);
    });

    test('multi-day gap — streak resets regardless of completion', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Q',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-22',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 0);
      expect(result.dateId, '2026-09-22');
    });

    test('future stored date (diff < 0) — resets to fresh state', () {
      final state = DailyState(
        dateId: '2026-09-25',
        dailyPrompt: 'Q',
        streakCount: 99,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-22',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 0);
      expect(result.dateId, '2026-09-22');
      expect(result.isAddaAnswered, false);
      expect(result.isBrainCompleted, false);
    });

    test('malformed stored dateId — resets to fresh state', () {
      final state = DailyState(
        dateId: 'not-a-date',
        dailyPrompt: 'Q',
        streakCount: 5,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-21',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 0);
      expect(result.dateId, '2026-09-21');
    });

    test('malformed currentDateId — resets to fresh state', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Q',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final result = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: 'bad-id',
        currentPrompt: 'Q2',
      );
      expect(result.streakCount, 0);
      expect(result.dateId, 'bad-id');
    });
  });

  // -------------------------------------------------------------------------
  // DailyState.fromJson
  // -------------------------------------------------------------------------
  group('DailyState.fromJson', () {
    test('valid JSON round-trips correctly', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'What is your favourite food?',
        isAddaAnswered: true,
        isBrainCompleted: false,
        streakCount: 3,
      );
      final decoded = DailyState.fromJson(state.toJson());
      expect(decoded.dateId, state.dateId);
      expect(decoded.dailyPrompt, state.dailyPrompt);
      expect(decoded.isAddaAnswered, true);
      expect(decoded.isBrainCompleted, false);
      expect(decoded.streakCount, 3);
    });

    test('missing dateId throws FormatException', () {
      expect(
        () => DailyState.fromJson({'dailyPrompt': 'Q'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('null dateId throws FormatException', () {
      expect(
        () => DailyState.fromJson({'dateId': null, 'dailyPrompt': 'Q'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('empty dateId throws FormatException', () {
      expect(
        () => DailyState.fromJson({'dateId': '', 'dailyPrompt': 'Q'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing dailyPrompt throws FormatException', () {
      expect(
        () => DailyState.fromJson({'dateId': '2026-09-20'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('wrong type for isAddaAnswered falls back to false', () {
      final state = DailyState.fromJson({
        'dateId': '2026-09-20',
        'dailyPrompt': 'Q',
        'isAddaAnswered': 'yes',
      });
      expect(state.isAddaAnswered, false);
    });

    test('wrong type for streakCount falls back to 0', () {
      final state = DailyState.fromJson({
        'dateId': '2026-09-20',
        'dailyPrompt': 'Q',
        'streakCount': '5',
      });
      expect(state.streakCount, 0);
    });
  });

  // -------------------------------------------------------------------------
  // DailyRepository
  // -------------------------------------------------------------------------
  group('DailyRepository', () {
    late _InMemoryStorage storage;
    late DailyRepository repo;

    setUp(() {
      storage = _InMemoryStorage();
      repo = DailyRepository(storage);
    });

    test('fresh state — returns DailyState for today', () async {
      final state = await repo.getDailyState();
      expect(state.dateId, _todayId());
      expect(state.isAddaAnswered, false);
      expect(state.isBrainCompleted, false);
      expect(state.streakCount, 0);
      expect(state.dailyPrompt, isNotEmpty);
    });

    test('same-day reload — returns stored state, not a reset', () async {
      final today = _todayId();
      final seeded = DailyState(
        dateId: today,
        dailyPrompt: 'A seeded prompt',
        isAddaAnswered: true,
        isBrainCompleted: false,
        streakCount: 4,
      );
      storage.seed('daily_state_v1', jsonEncode(seeded.toJson()));

      final loaded = await repo.getDailyState();
      expect(loaded.dateId, today);
      expect(loaded.isAddaAnswered, true);
      expect(loaded.streakCount, 4);
    });

    test('read failure — recovers to fresh state without crashing', () async {
      storage.throwOnRead = true;
      final state = await repo.getDailyState();
      expect(state.dateId, _todayId());
      expect(state.streakCount, 0);
    });

    test('write failure on fresh init — does not crash', () async {
      storage.throwOnWrite = true;
      final state = await repo.getDailyState();
      expect(state.dateId, _todayId());
    });

    test('malformed JSON in storage — recovers to fresh state', () async {
      storage.seed('daily_state_v1', 'NOT_VALID_JSON{{{{');
      final state = await repo.getDailyState();
      expect(state.dateId, _todayId());
      expect(state.streakCount, 0);
    });

    test(
      'stored JSON missing required fields — recovers to fresh state',
      () async {
        storage.seed(
          'daily_state_v1',
          jsonEncode({'dailyPrompt': 'Q', 'streakCount': 5}),
        );
        final state = await repo.getDailyState();
        expect(state.dateId, _todayId());
        expect(state.streakCount, 0);
      },
    );

    test('saveDailyState write failure — graceful, does not throw', () async {
      final state = await repo.getDailyState();
      storage.throwOnWrite = true;
      await expectLater(repo.saveDailyState(state), completes);
    });
  });
}
