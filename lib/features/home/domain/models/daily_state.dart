/// Represents the user's daily progress on Home.
///
/// NOTE: The user's actual text answer for the Daily Adda is explicitly NOT stored
/// for privacy reasons. This model only tracks the boolean completion status.
class DailyState {
  final String dateId; // e.g., '2026-09-21'
  final String dailyPrompt;
  final bool isAddaAnswered;
  final bool isBrainCompleted;
  final int streakCount;

  const DailyState({
    required this.dateId,
    required this.dailyPrompt,
    this.isAddaAnswered = false,
    this.isBrainCompleted = false,
    this.streakCount = 0,
  });

  DailyState copyWith({
    String? dateId,
    String? dailyPrompt,
    bool? isAddaAnswered,
    bool? isBrainCompleted,
    int? streakCount,
  }) {
    return DailyState(
      dateId: dateId ?? this.dateId,
      dailyPrompt: dailyPrompt ?? this.dailyPrompt,
      isAddaAnswered: isAddaAnswered ?? this.isAddaAnswered,
      isBrainCompleted: isBrainCompleted ?? this.isBrainCompleted,
      streakCount: streakCount ?? this.streakCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateId': dateId,
      'dailyPrompt': dailyPrompt,
      'isAddaAnswered': isAddaAnswered,
      'isBrainCompleted': isBrainCompleted,
      'streakCount': streakCount,
    };
  }

  factory DailyState.fromJson(Map<String, dynamic> json) {
    final rawDateId = json['dateId'];
    final rawPrompt = json['dailyPrompt'];

    // Validate required string fields explicitly so corrupt storage throws a
    // typed FormatException, which the repository catch block can handle safely.
    if (rawDateId is! String || rawDateId.isEmpty) {
      throw const FormatException('DailyState: missing or invalid dateId');
    }
    if (rawPrompt is! String || rawPrompt.isEmpty) {
      throw const FormatException('DailyState: missing or invalid dailyPrompt');
    }

    return DailyState(
      dateId: rawDateId,
      dailyPrompt: rawPrompt,
      isAddaAnswered: json['isAddaAnswered'] is bool
          ? json['isAddaAnswered'] as bool
          : false,
      isBrainCompleted: json['isBrainCompleted'] is bool
          ? json['isBrainCompleted'] as bool
          : false,
      streakCount: json['streakCount'] is int ? json['streakCount'] as int : 0,
    );
  }
}
