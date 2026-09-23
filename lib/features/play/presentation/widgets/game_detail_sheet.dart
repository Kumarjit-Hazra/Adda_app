import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../features/games/domain/game_registry.dart';

class GameDetailSheet extends StatelessWidget {
  final GameDefinition game;
  final bool isDark;

  const GameDetailSheet({super.key, required this.game, required this.isDark});

  static void show(BuildContext context, GameDefinition game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GameDetailSheet(game: game, isDark: isDark);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool soloAvailable = game.playableSolo;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddaRadius.xl),
        ),
      ),
      padding: const EdgeInsets.only(
        left: AddaSpacing.xl,
        right: AddaSpacing.xl,
        top: AddaSpacing.md,
        bottom: AddaSpacing.xxl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AddaSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: AddaRadius.radiusFull,
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AddaColors.textPrimaryDark
                              : AddaColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.category.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AddaColors.coral,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (game.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AddaColors.coral.withAlpha(30),
                      borderRadius: AddaRadius.radiusSm,
                    ),
                    child: Text(
                      game.badge!.toUpperCase(),
                      style: const TextStyle(
                        color: AddaColors.coral,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AddaSpacing.lg),

            // Description
            Text(
              game.description ?? 'A fun and engaging game.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AddaColors.textSecondaryDark
                    : AddaColors.textSecondaryLight,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AddaSpacing.xl),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  Icons.group_rounded,
                  game.playerRange,
                  'Players',
                ),
                _buildStatColumn(
                  Icons.timer_rounded,
                  game.durationLabel,
                  'Duration',
                ),
                if (soloAvailable)
                  _buildStatColumn(Icons.person_rounded, 'Yes', 'Solo Mode'),
              ],
            ),

            const SizedBox(height: AddaSpacing.xxl),

            // Actions
            if (soloAvailable)
              AppButton(
                text: 'Play Solo Now',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/play/solo/${game.id}');
                },
              )
            else
              AppButton(
                text: 'Coming Soon',
                onPressed: null, // Disabled
              ),

            const SizedBox(height: AddaSpacing.md),

            if (soloAvailable)
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/hangout');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: isDark
                        ? AddaColors.borderDark
                        : AddaColors.borderLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AddaRadius.radiusLg,
                  ),
                ),
                child: Text(
                  'Find Space to Play',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AddaColors.textPrimaryDark
                        : AddaColors.textPrimaryLight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: isDark ? AddaColors.textMutedDark : AddaColors.textMutedLight,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AddaColors.textPrimaryDark
                : AddaColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AddaColors.textMutedDark
                : AddaColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
