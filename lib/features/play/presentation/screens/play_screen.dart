import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
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

  final List<Map<String, dynamic>> _games = const [
    {
      'id': '29_cards',
      'title': '29 Cards',
      'category': 'Card Classics',
      'badge': 'FLAGSHIP',
      'players': '4 Players',
      'duration': '15 min',
      'color': AddaColors.coral,
      'icon': Icons.style_rounded,
      'description':
          'The legendary South Asian trick-taking card battle with jacks and nines.',
    },
    {
      'id': 'uno_clash',
      'title': 'UNO Clash',
      'category': 'Card Classics',
      'badge': 'POPULAR',
      'players': '2-6 Players',
      'duration': '10 min',
      'color': AddaColors.amber,
      'icon': Icons.filter_none_rounded,
      'description':
          'Color matches, reverse chaos, and draw-four faceoffs with friends.',
    },
    {
      'id': 'bluff_masters',
      'title': 'Bluff Masters',
      'category': 'Party & Deception',
      'badge': 'SOCIAL',
      'players': '3-8 Players',
      'duration': '12 min',
      'color': AddaColors.rose,
      'icon': Icons.psychology_alt_rounded,
      'description':
          'Call bluffs, disguise high cards, and catch lying friends red-handed.',
    },
    {
      'id': 'teen_patti',
      'title': 'Teen Patti',
      'category': 'Card Classics',
      'badge': 'EXPRESS',
      'players': '3-6 Players',
      'duration': '8 min',
      'color': AddaColors.emerald,
      'icon': Icons.monetization_on_rounded,
      'description':
          'Flash, pure sequence, and trail showdowns with virtual chips.',
    },
    {
      'id': 'rummy_rush',
      'title': 'Rummy Rush',
      'category': 'Card Classics',
      'badge': 'STRATEGY',
      'players': '2-4 Players',
      'duration': '15 min',
      'color': AddaColors.cyan,
      'icon': Icons.dashboard_customize_rounded,
      'description':
          'Form pure sequences, sets, and declare your hand before rivals.',
    },
    {
      'id': 'mafia_city',
      'title': 'Mafia: Nightfall',
      'category': 'Party & Deception',
      'badge': 'ROLEPLAY',
      'players': '5-12 Players',
      'duration': '20 min',
      'color': AddaColors.violet,
      'icon': Icons.nights_stay_rounded,
      'description':
          'Villagers vs Mafia. Secret votes, detective sleuthing, and doctor saves.',
    },
    {
      'id': 'brain_arena',
      'title': 'Brain Arena',
      'category': 'Brain & Logic',
      'badge': 'COMPETITIVE',
      'players': '1-8 Players',
      'duration': '5 min',
      'color': AddaColors.amber,
      'icon': Icons.bolt_rounded,
      'description':
          'Rapid-fire pattern recognition, mental math, and memory duels.',
    },
    {
      'id': 'coop_puzzle',
      'title': 'Mystery Crypt',
      'category': 'Co-op Mystery',
      'badge': 'CO-OP',
      'players': '2-4 Players',
      'duration': '18 min',
      'color': Color(0xFF3B82F6),
      'icon': Icons.extension_rounded,
      'description':
          'Escape rooms with asymmetric clues where voice communication is key.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredGames = _selectedCategory == 'All Games'
        ? _games
        : _games.where((g) => g['category'] == _selectedCategory).toList();

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
                final game = filteredGames[index];
                final Color color = game['color'] as Color;
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
                            game['icon'] as IconData,
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
                                    game['title'] as String,
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
                                      game['badge'] as String,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game['description'] as String,
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
                                    game['players'] as String,
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
                                    game['duration'] as String,
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
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: filteredGames.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
