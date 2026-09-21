import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../activities/engine/activity_definition.dart';
import '../../../games/domain/game_registry.dart';
import '../../application/daily_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickPlayCarousel extends ConsumerWidget {
  const QuickPlayCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select a few diverse games for quick play
    final List<String> quickPlayIds = [
      'twenty_nine',
      'uno',
      'bluff',
      'brain_arena',
    ];
    final games = quickPlayIds
        .map((id) => GameRegistry.getDefinition(id))
        .whereType<GameDefinition>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AddaSpacing.lg,
            right: AddaSpacing.lg,
            bottom: AddaSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Play 🚀',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.go('/play'),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AddaColors.coral,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.lg),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildQuickPlayCard(context, ref, game);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPlayCard(
    BuildContext context,
    WidgetRef ref,
    GameDefinition game,
  ) {
    Color getCategoryColor(ActivityCategory category) {
      switch (category) {
        case ActivityCategory.cards:
          return AddaColors.coral;
        case ActivityCategory.party:
          return AddaColors.rose;
        case ActivityCategory.brain:
          return AddaColors.violet;
        case ActivityCategory.creative:
          return AddaColors.amber;
        default:
          return AddaColors.emerald;
      }
    }

    IconData getCategoryIcon(ActivityCategory category) {
      switch (category) {
        case ActivityCategory.cards:
          return Icons.style_rounded;
        case ActivityCategory.party:
          return Icons.celebration_rounded;
        case ActivityCategory.brain:
          return Icons.psychology_rounded;
        case ActivityCategory.creative:
          return Icons.brush_rounded;
        default:
          return Icons.games_rounded;
      }
    }

    final color = getCategoryColor(game.category);
    final icon = getCategoryIcon(game.category);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: SurfaceCard(
        onTap: () {
          // If it's brain arena, mark it completed on the daily tasks
          if (game.id == 'brain_arena') {
            ref.read(dailyStateProvider.notifier).markBrainCompleted();
          }
          context.push('/play/${game.id}');
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderColor: color.withValues(alpha: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 30),
                borderRadius: AddaRadius.radiusSm,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${game.playerRange} • ${game.durationLabel}',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
