import 'dart:convert';
import '../../../../core/storage/storage_service.dart';
import '../domain/models/daily_state.dart';
import 'package:flutter/foundation.dart';

/// NOTE: User answers to the Daily Adda are intentionally kept ephemeral
/// for privacy. The repository only tracks completion status, not the answer text.
class DailyRepository {
  final StorageService _storage;
  static const String _storageKey = 'daily_state_v1';

  DailyRepository(this._storage);

  static final List<String> _prompts = [
    "What is a movie you secretly love that everyone hates?",
    "If you could only eat one food for the rest of your life, what would it be?",
    "What is your most controversial food opinion?",
    "What's a hobby you've always wanted to pick up?",
    "If you could teleport anywhere right now, where would you go?",
    "What's the best piece of advice you've ever received?",
    "What's a weird habit you have that you think nobody else does?",
  ];

  String _getDateId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getPromptForDate(String dateId) {
    // Generate a deterministic prompt based on the date string
    int hash = 0;
    for (int i = 0; i < dateId.length; i++) {
      hash = (31 * hash + dateId.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return _prompts[hash % _prompts.length];
  }

  Future<DailyState> getDailyState() async {
    final currentDateId = _getDateId();
    final prompt = _getPromptForDate(currentDateId);

    try {
      final jsonStr = _storage.getString(_storageKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final storedState = DailyState.fromJson(json);

        // Date rollover check
        if (storedState.dateId != currentDateId) {
          final newState = DailyStreakCalculator.calculateNextState(
            currentState: storedState,
            currentDateId: currentDateId,
            currentPrompt: prompt,
          );
          if (newState != storedState) {
            await saveDailyState(newState);
            return newState;
          }
        }
        return storedState;
      }
    } catch (e) {
      debugPrint('Error reading daily state: $e');
    }

    // Default if no storage or parse error
    final newState = DailyState(dateId: currentDateId, dailyPrompt: prompt);
    await saveDailyState(newState);
    return newState;
  }

  Future<void> saveDailyState(DailyState state) async {
    try {
      final jsonStr = jsonEncode(state.toJson());
      await _storage.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error writing daily state: $e');
    }
  }
}

class DailyStreakCalculator {
  static DailyState calculateNextState({
    required DailyState currentState,
    required String currentDateId,
    required String currentPrompt,
  }) {
    if (currentState.dateId == currentDateId) {
      return currentState;
    }

    final currentParts = currentDateId.split('-');
    final storedParts = currentState.dateId.split('-');

    if (currentParts.length != 3 || storedParts.length != 3) {
      return DailyState(dateId: currentDateId, dailyPrompt: currentPrompt);
    }

    final currentDate = DateTime(
      int.parse(currentParts[0]),
      int.parse(currentParts[1]),
      int.parse(currentParts[2]),
    );

    final storedDate = DateTime(
      int.parse(storedParts[0]),
      int.parse(storedParts[1]),
      int.parse(storedParts[2]),
    );

    // Difference in whole days
    final diff = currentDate.difference(storedDate).inDays;

    int newStreak = currentState.streakCount;

    // If diff is 1 (yesterday) and BOTH were completed, maintain streak.
    // Otherwise, the streak is lost.
    // The streak only INCREMENTS when both are completed today.
    if (diff == 1 &&
        currentState.isAddaAnswered &&
        currentState.isBrainCompleted) {
      // Streak is maintained
    } else {
      // Gap > 1 day or didn't finish both yesterday -> Reset
      newStreak = 0;
    }

    return DailyState(
      dateId: currentDateId,
      dailyPrompt: currentPrompt,
      streakCount: newStreak,
    );
  }
}
