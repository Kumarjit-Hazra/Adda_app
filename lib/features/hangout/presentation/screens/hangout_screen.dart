import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/state_views.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../spaces/presentation/providers/space_provider.dart';
import '../../../spaces/presentation/widgets/create_space_sheet.dart';
import '../../../spaces/presentation/widgets/join_space_dialog.dart';
import '../../../spaces/presentation/widgets/space_card.dart';
import '../providers/hangout_provider.dart';
import '../widgets/live_space_card.dart';
import '../widgets/space_section_header.dart';

class HangoutScreen extends ConsumerStatefulWidget {
  const HangoutScreen({super.key});

  @override
  ConsumerState<HangoutScreen> createState() => _HangoutScreenState();
}

class _HangoutScreenState extends ConsumerState<HangoutScreen> {
  @override
  Widget build(BuildContext context) {
    final spacesAsync = ref.watch(spacesProvider);
    final liveSpaces = ref.watch(liveSpacesProvider);
    final mySpaces = ref.watch(mySpacesProvider);
    final recentlyActive = ref.watch(recentlyActiveProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AddaTopBar(
        contextBadge: 'LIVE',
        contextTitle: 'Hangout',
        badgeColor: AddaColors.emerald,
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded, size: 20),
            tooltip: 'Join with Code',
            onPressed: () async {
              final space = await JoinSpaceDialog.show(context);
              if (space != null && context.mounted) {
                context.push('/space/${space.id}/room', extra: space.name);
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AddaColors.coral,
            ),
            tooltip: 'Create Space',
            onPressed: () async {
              final space = await CreateSpaceSheet.show(context);
              if (space != null && context.mounted) {
                context.push('/space/${space.id}/room', extra: space.name);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: spacesAsync.when(
        loading: () => const LoadingStateView(message: 'Loading Spaces...'),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.read(spacesProvider.notifier).loadSpaces(),
        ),
        data: (allSpaces) {
          if (allSpaces.isEmpty) {
            return EmptyStateView(
              icon: Icons.groups_outlined,
              title: 'No Spaces Yet',
              message:
                  'Create your first Space to start hanging out with friends.',
              actionLabel: 'Create Space',
              onAction: () => CreateSpaceSheet.show(context),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Live Social Activity Indicator ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AddaSpacing.lg,
                    vertical: AddaSpacing.xs,
                  ),
                  child: SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    backgroundColor: isDark
                        ? AddaColors.surfaceElevatedDark
                        : AddaColors.surfaceVariantLight,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AddaColors.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            liveSpaces.isEmpty
                                ? 'No spaces are live right now — be the first!'
                                : '${liveSpaces.length} space${liveSpaces.length > 1 ? 's' : ''} live right now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AddaColors.textSecondaryDark
                                  : AddaColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── LIVE NOW Section ──
              if (liveSpaces.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SpaceSectionHeader(
                    title: 'Live Now',
                    count: liveSpaces.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AddaSpacing.lg,
                      ),
                      itemCount: liveSpaces.length,
                      itemBuilder: (context, index) {
                        final space = liveSpaces[index];
                        return LiveSpaceCard(
                          space: space,
                          onTap: () => context.push(
                            '/space/${space.id}/room',
                            extra: space.name,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AddaSpacing.sm),
                ),
              ],

              // ── MY SPACES Section ──
              if (mySpaces.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Divider(height: 1)),
                SliverToBoxAdapter(
                  child: SpaceSectionHeader(
                    title: 'My Spaces',
                    count: mySpaces.length,
                    trailing: TextButton(
                      onPressed: () => CreateSpaceSheet.show(context),
                      child: const Text(
                        '+ New',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AddaColors.coral,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AddaSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final space = mySpaces[index];
                      return SpaceCard(
                        space: space,
                        onTap: () => context.push(
                          '/space/${space.id}/room',
                          extra: space.name,
                        ),
                        onFavoriteTap: () => ref
                            .read(spacesProvider.notifier)
                            .toggleFavorite(space.id),
                      );
                    }, childCount: mySpaces.length),
                  ),
                ),
              ],

              // ── RECENTLY ACTIVE Section ──
              if (recentlyActive.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Divider(height: 1)),
                const SliverToBoxAdapter(
                  child: SpaceSectionHeader(title: 'Recently Active'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AddaSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final space = recentlyActive[index];
                      return SpaceCard(
                        space: space,
                        onTap: () => context.push(
                          '/space/${space.id}/room',
                          extra: space.name,
                        ),
                        onFavoriteTap: () => ref
                            .read(spacesProvider.notifier)
                            .toggleFavorite(space.id),
                      );
                    }, childCount: recentlyActive.length),
                  ),
                ),
              ],

              // Bottom padding for FAB clearance
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AddaColors.coral,
        foregroundColor: Colors.white,
        onPressed: () => CreateSpaceSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Space',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
