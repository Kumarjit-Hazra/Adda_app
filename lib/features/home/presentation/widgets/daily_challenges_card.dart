import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../application/daily_providers.dart';

class DailyChallengesCard extends ConsumerWidget {
  const DailyChallengesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyStateAsync = ref.watch(dailyStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dailyStateAsync.when(
      data: (dailyState) {
        final completedCount =
            (dailyState.isAddaAnswered ? 1 : 0) +
            (dailyState.isBrainCompleted ? 1 : 0);
        final totalCount = 2;

        return SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏆 DAILY CHALLENGES ($completedCount/$totalCount Done)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AddaColors.amber,
                    ),
                  ),
                  if (dailyState.streakCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AddaColors.coral.withValues(alpha: 40),
                        borderRadius: AddaRadius.radiusXs,
                      ),
                      child: Text(
                        '🔥 ${dailyState.streakCount} Days',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AddaColors.coral,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildChallengeRow(
                context,
                title: 'Answer the Daily Adda',
                isCompleted: dailyState.isAddaAnswered,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildChallengeRow(
                context,
                title: 'Play Daily Brain',
                isCompleted: dailyState.isBrainCompleted,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Daily challenges unavailable right now.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(dailyStateProvider),
              child: const Text(
                'Retry',
                style: TextStyle(color: AddaColors.amber),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeRow(
    BuildContext context, {
    required String title,
    required bool isCompleted,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          isCompleted
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          color: isCompleted
              ? AddaColors.emerald
              : (isDark ? Colors.white30 : Colors.black38),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isCompleted
                  ? (isDark ? Colors.white70 : Colors.black54)
                  : (isDark ? Colors.white : Colors.black),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          isCompleted ? 'Completed' : 'Pending',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isCompleted
                ? AddaColors.emerald
                : (isDark ? Colors.white30 : Colors.black38),
          ),
        ),
      ],
    );
  }
}
