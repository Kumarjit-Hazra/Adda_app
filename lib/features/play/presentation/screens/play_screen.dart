import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/activities/engine/activity_definition.dart';
import '../../../../features/games/domain/game_registry.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../widgets/game_card.dart';
import '../widgets/game_detail_sheet.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  ActivityCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    GameRegistry.initialize();
  }

  List<GameDefinition> get _filteredGames {
    final allGames = GameRegistry.getAllDefinitions();
    if (_selectedCategory == null) return allGames;
    return allGames.where((g) => g.category == _selectedCategory).toList();
  }

  void _showGameDetails(BuildContext context, GameDefinition game) {
    GameDetailSheet.show(context, game);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamically get categories based on registered games
    final allGames = GameRegistry.getAllDefinitions();
    final categories = allGames.map((g) => g.category).toSet().toList();

    // Pick a featured game (hardcoding twenty_nine for now as it's flagship)
    final featuredGame = GameRegistry.getDefinition('twenty_nine');

    return AppScaffold(
      appBar: const AddaTopBar(
        contextBadge: 'ARCADE',
        contextTitle: 'Play Arena',
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Banner
          if (featuredGame != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AddaSpacing.lg),
                child: GestureDetector(
                  onTap: () => _showGameDetails(context, featuredGame),
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
                                  fontWeight: FontWeight.w900,
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
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          featuredGame.description ??
                              'Play the authentic trick-taking classic with room friends or quick-match into active tables.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AddaColors.textSecondaryDark
                                    : AddaColors.textSecondaryLight,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.go('/play/solo/twenty_nine'),
                              icon: const Icon(
                                Icons.flash_on_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'Quick Play Solo',
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
            ),

          // Category Selector
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.lg),
              child: Row(
                children: [
                  _buildCategoryChip(null, 'All Games', isDark),
                  ...categories.map(
                    (cat) => _buildCategoryChip(
                      cat,
                      _formatCategoryName(cat),
                      isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AddaSpacing.md)),

          // Game Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.lg),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid: 2 columns on small tablets/phones, 3 on larger screens
                int crossAxisCount = constraints.crossAxisExtent > 600 ? 3 : 2;

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = _filteredGames[index];
                    return GameCard(
                      game: game,
                      isDark: isDark,
                      onTap: () => _showGameDetails(context, game),
                    );
                  }, childCount: _filteredGames.length),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    ActivityCategory? category,
    String label,
    bool isDark,
  ) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AddaColors.coral.withAlpha(30),
        checkmarkColor: AddaColors.coral,
        labelStyle: TextStyle(
          color: isSelected
              ? AddaColors.coral
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: isDark
            ? AddaColors.surfaceVariantDark
            : AddaColors.surfaceVariantLight,
        shape: RoundedRectangleBorder(borderRadius: AddaRadius.radiusFull),
        side: BorderSide(
          color: isSelected ? AddaColors.coral : Colors.transparent,
        ),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }

  String _formatCategoryName(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.cards:
        return 'Card Classics';
      case ActivityCategory.party:
        return 'Party & Deception';
      case ActivityCategory.brain:
        return 'Brain & Logic';
      case ActivityCategory.mystery:
        return 'Co-op Mystery';
      case ActivityCategory.creative:
        return 'Creative';
      case ActivityCategory.couple:
        return 'Couple';
      case ActivityCategory.study:
        return 'Study';
    }
  }
}
