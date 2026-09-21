import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';

/// Small pill badge showing what activity is currently running in a space.
/// Displays an icon and activity name like "🃏 Twenty-Nine".
class ActivityBadge extends StatelessWidget {
  final String activityName;

  const ActivityBadge({super.key, required this.activityName});

  String get _icon {
    final lower = activityName.toLowerCase();
    if (lower.contains('twenty') || lower.contains('29')) return '🃏';
    if (lower.contains('uno')) return '🌈';
    if (lower.contains('bluff')) return '🎭';
    if (lower.contains('rummy')) return '♠️';
    if (lower.contains('teen') || lower.contains('patti')) return '♦️';
    if (lower.contains('mafia')) return '🕵️';
    if (lower.contains('brain')) return '⚡️';
    if (lower.contains('quiz')) return '❓';
    if (lower.contains('draw')) return '🎨';
    if (lower.contains('puzzle') || lower.contains('coop')) return '🧩';
    if (lower.contains('couple')) return '💕';
    if (lower.contains('watch')) return '📺';
    return '🎮';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AddaColors.violet.withAlpha(30),
        borderRadius: AddaRadius.radiusFull,
        border: Border.all(color: AddaColors.violet.withAlpha(60), width: 0.8),
      ),
      child: Text(
        '$_icon $activityName',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AddaColors.violet,
        ),
      ),
    );
  }
}
