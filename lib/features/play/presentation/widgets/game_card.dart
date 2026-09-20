import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../features/activities/engine/activity_definition.dart';
import '../../../../features/games/domain/game_registry.dart';

class GameCard extends StatelessWidget {
  final GameDefinition game;
  final VoidCallback onTap;
  final bool isDark;

  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    required this.isDark,
  });

  Color _getColorForCategory(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.cards:
        return AddaColors.coral;
      case ActivityCategory.party:
        return AddaColors.rose;
      case ActivityCategory.brain:
        return AddaColors.amber;
      case ActivityCategory.mystery:
        return const Color(0xFF3B82F6);
      case ActivityCategory.creative:
        return AddaColors.violet;
      case ActivityCategory.couple:
        return AddaColors.emerald;
      case ActivityCategory.study:
        return AddaColors.cyan;
    }
  }

  IconData _getIconForGame(String gameId) {
    switch (gameId) {
      case 'twenty_nine':
        return Icons.style_rounded;
      case 'uno':
        return Icons.filter_none_rounded;
      case 'bluff':
        return Icons.psychology_alt_rounded;
      case 'rummy':
        return Icons.dashboard_customize_rounded;
      case 'teen_patti':
        return Icons.monetization_on_rounded;
      case 'mafia':
        return Icons.nights_stay_rounded;
      case 'brain_arena':
        return Icons.bolt_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'coop_puzzle':
        return Icons.extension_rounded;
      case 'draw_guess':
        return Icons.draw_rounded;
      case 'couple_mode':
        return Icons.favorite_rounded;
      case 'watch_together':
        return Icons.tv_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForCategory(game.category);
    // Determine if we should show a solo badge
    final bool soloAvailable = game.id == 'twenty_nine';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AddaColors.surfaceVariantDark
              : AddaColors.surfaceVariantLight,
          borderRadius: AddaRadius.radiusLg,
          border: Border.all(
            color: color.withAlpha(isDark ? 40 : 80),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Artwork/Character Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withAlpha(40), color.withAlpha(10)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getIconForGame(game.id),
                        size: 64,
                        color: color.withAlpha(200),
                      ),
                    ),
                    if (game.badge != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: AddaRadius.radiusSm,
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(100),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            game.badge!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    if (soloAvailable)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AddaColors.emerald.withAlpha(150),
                            borderRadius: AddaRadius.radiusSm,
                            border: Border.all(
                              color: AddaColors.emerald,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'SOLO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Bottom Info Area
            Container(
              padding: const EdgeInsets.all(AddaSpacing.md),
              color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AddaColors.textPrimaryDark
                          : AddaColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 14,
                        color: isDark ? AddaColors.textMutedDark : AddaColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          game.playerRange,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AddaColors.textMutedDark : AddaColors.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isDark ? AddaColors.textMutedDark : AddaColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          game.durationLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AddaColors.textMutedDark : AddaColors.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
