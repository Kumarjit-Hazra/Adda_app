import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/activities/engine/activity_definition.dart';
import '../../../../features/games/domain/game_registry.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  String _selectedCategory = 'All Games';

  final List<String> _categories = const [
    'All Games',
    'Card Classics',
    'Party & Deception',
    'Brain & Logic',
    'Co-op Mystery',
  ];

  @override
  void initState() {
    super.initState();
    GameRegistry.initialize();
  }

  List<GameDefinition> get _filteredGames {
    final allGames = GameRegistry.getAllDefinitions();
    if (_selectedCategory == 'All Games') return allGames;
    
    // Map display category names to enum values
    ActivityCategory? targetCategory;
    switch (_selectedCategory) {
      case 'Card Classics':
        targetCategory = ActivityCategory.cards;
        break;
      case 'Party & Deception':
        targetCategory = ActivityCategory.party;
        break;
      case 'Brain & Logic':
        targetCategory = ActivityCategory.brain;
        break;
      case 'Co-op Mystery':
        targetCategory = ActivityCategory.mystery;
        break;
    }
    
    if (targetCategory == null) return allGames;
    return allGames.where((g) => g.category == targetCategory).toList();
  }

  bool _supportsSoloPlay(String gameId) {
    // Currently only Twenty-Nine supports solo play via GameSession
    return gameId == 'twenty_nine';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const AddaTopBar(
        contextBadge: 'ARCADE',
        contextTitle: 'Play Arena',
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AddaSpacing.lg),
              child: SurfaceCard(
                padding: const EdgeInsets.all(AddaSpacing.xl),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2B1D3A), const Color(0xFF16152B)]
                      : [const Color(0xFFFAF0F8), const Color(0xFFF3E8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AddaColors.violet.withAlpha(80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AddaColors.violet.withAlpha(40),
                            borderRadius: AddaRadius.radiusFull,
                          ),
                          child: const Text(
                            'FEATURED THIS WEEK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AddaColors.violet,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: AddaColors.coral,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '29 Cards Championship',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Play the authentic trick-taking classic with room friends or quick-match into active tables.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AddaColors.textSecondaryDark
                            : AddaColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go('/hangout'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'Find Space to Play',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AddaColors.coral,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AddaRadius.radiusMd,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Selector
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.lg),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AddaColors.coral.withAlpha(30),
                      checkmarkColor: AddaColors.coral,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AddaColors.coral
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: isDark
                          ? AddaColors.surfaceVariantDark
                          : AddaColors.surfaceVariantLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: AddaRadius.radiusFull,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AddaColors.coral
                            : Colors.transparent,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AddaSpacing.md)),

          // Game Grid / List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final game = _filteredGames[index];
                final Color color = _getColorForCategory(game.category);
                final bool soloAvailable = _supportsSoloPlay(game.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: color.withAlpha(40),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: AddaRadius.radiusMd,
                          ),
                          child: Icon(
                            _getIconForGame(game.id),
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    game.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(30),
                                      borderRadius: AddaRadius.radiusXs,
                                    ),
                                    child: Text(
                                      game.badge ?? '',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  if (soloAvailable) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AddaColors.emerald.withAlpha(30),
                                        borderRadius: AddaRadius.radiusXs,
                                      ),
                                      child: const Text(
                                        'SOLO',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AddaColors.emerald,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game.description ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AddaColors.textSecondaryDark
                                      : AddaColors.textSecondaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 14,
                                    color: isDark
                                        ? AddaColors.textMutedDark
                                        : AddaColors.textMutedLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    game.playerRange,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AddaColors.textMutedDark
                                          : AddaColors.textMutedLight,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: isDark
                                        ? AddaColors.textMutedDark
                                        : AddaColors.textMutedLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    game.durationLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AddaColors.textMutedDark
                                          : AddaColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (soloAvailable)
                          AppButton(
                            text: 'Play Solo',
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            onPressed: () => context.go('/play/solo/${game.id}'),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                      ],
                    ),
                  ),
                );
              }, childCount: _filteredGames.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

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
}