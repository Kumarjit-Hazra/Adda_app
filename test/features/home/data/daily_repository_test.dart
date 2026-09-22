import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';

void main() {
  group('DailyStreakCalculator', () {
    test('maintains streak on same day', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Test',
        streakCount: 5,
      );
      final next = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-20',
        currentPrompt: 'Test',
      );
      expect(next.streakCount, 5);
      expect(next.dateId, '2026-09-20');
    });

    test('maintains streak if next day and BOTH were completed yesterday', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Test',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final next = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-21',
        currentPrompt: 'Test2',
      );
      expect(next.streakCount, 5);
      expect(next.dateId, '2026-09-21');
    });

    test('resets streak if next day but NOT both completed yesterday', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Test',
        streakCount: 5,
        isAddaAnswered: true, // Only one completed
        isBrainCompleted: false,
      );
      final next = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-21',
        currentPrompt: 'Test2',
      );
      expect(next.streakCount, 0);
    });

    test('resets streak if more than 1 day passed', () {
      final state = DailyState(
        dateId: '2026-09-20',
        dailyPrompt: 'Test',
        streakCount: 5,
        isAddaAnswered: true,
        isBrainCompleted: true,
      );
      final next = DailyStreakCalculator.calculateNextState(
        currentState: state,
        currentDateId: '2026-09-22',
        currentPrompt: 'Test2',
      );
      expect(next.streakCount, 0);
    });
  });
}
