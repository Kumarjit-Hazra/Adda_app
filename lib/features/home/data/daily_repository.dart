import 'dart:convert';
import '../../../../core/storage/storage_service.dart';
import '../domain/models/daily_state.dart';
import 'package:flutter/foundation.dart';

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
    final hashCode = dateId.hashCode.abs();
    return _prompts[hashCode % _prompts.length];
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
          // Verify if it's the next consecutive day for streak
          // Parse dateId back to DateTime
          final parts = storedState.dateId.split('-');
          if (parts.length == 3) {
            final storedDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            final diff = DateTime.now().difference(storedDate).inDays;

            int newStreak = storedState.streakCount;
            // If they completed both tasks yesterday, maintain streak, else reset
            if (diff == 1 &&
                storedState.isAddaAnswered &&
                storedState.isBrainCompleted) {
              // Streak maintained (will be incremented upon completion today)
            } else if (diff > 1 ||
                (!storedState.isAddaAnswered ||
                    !storedState.isBrainCompleted)) {
              newStreak = 0; // Reset
            }

            final newState = DailyState(
              dateId: currentDateId,
              dailyPrompt: prompt,
              streakCount: newStreak,
            );
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
