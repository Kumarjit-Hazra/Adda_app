import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';

import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/state_views.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../room/presentation/providers/room_provider.dart';
import '../../../spaces/presentation/providers/space_provider.dart';
import '../../../spaces/presentation/widgets/create_space_sheet.dart';
import '../../../spaces/presentation/widgets/join_space_dialog.dart';
import '../../../spaces/presentation/widgets/space_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final spacesAsync = ref.watch(spacesProvider);
    final activeRoom = ref.watch(roomProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const AddaTopBar(),

      // Floating persistent bar if currently connected to a room while browsing home!
      floatingOverlay: activeRoom != null
          ? GestureDetector(
              onTap: () => context.push(
                '/space/${activeRoom.spaceId}/room',
                extra: activeRoom.spaceName,
              ),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                backgroundColor: AddaColors.surfaceElevatedDark,
                borderColor: AddaColors.emerald,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AddaColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Connected to ${activeRoom.spaceName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${activeRoom.participants.length} peers in voice • Tap to return',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AddaColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: userAsync.when(
        loading: () => const LoadingStateView(message: 'Starting your Adda...'),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.read(authProvider.notifier).loadUser(),
        ),
        data: (user) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AddaSpacing.lg,
                    vertical: AddaSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey, ${user.name} 👋',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.statusMessage ??
                                  'Ready to hang out and play games',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AddaColors.textSecondaryDark
                                    : AddaColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Hero Card (Create / Join Space)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AddaSpacing.lg,
                  ),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(AddaSpacing.xl),
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF1F283C), Color(0xFF131826)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFEFF3FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Private Hangout',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Talk over WebRTC voice and play 29, UNO, Bluff or solve mystery puzzles in one shared space.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AddaSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Create Space',
                                icon: const Icon(Icons.add_rounded, size: 18),
                                onPressed: () async {
                                  final space = await CreateSpaceSheet.show(
                                    context,
                                  );
                                  if (space != null && context.mounted) {
                                    context.push(
                                      '/space/${space.id}/room',
                                      extra: space.name,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton.secondary(
                                text: 'Join with Code',
                                icon: const Icon(Icons.key_rounded, size: 16),
                                onPressed: () async {
                                  final space = await JoinSpaceDialog.show(
                                    context,
                                  );
                                  if (space != null && context.mounted) {
                                    context.push(
                                      '/space/${space.id}/room',
                                      extra: space.name,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Play Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AddaSpacing.lg,
                    top: AddaSpacing.xl,
                    bottom: AddaSpacing.sm,
                  ),
                  child: Text(
                    'Quick Play 🚀',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AddaSpacing.lg,
                    ),
                    children: [
                      _buildQuickPlayCard(
                        context,
                        title: '29 Cards',
                        subtitle: 'Trick Taking',
                        icon: Icons.style_rounded,
                        color: AddaColors.coral,
                        onTap: () => _enterFirstSpace(context, ref),
                      ),
                      _buildQuickPlayCard(
                        context,
                        title: 'UNO Clash',
                        subtitle: 'Color Match',
                        icon: Icons.filter_none_rounded,
                        color: AddaColors.amber,
                        onTap: () => _enterFirstSpace(context, ref),
                      ),
                      _buildQuickPlayCard(
                        context,
                        title: 'Bluff Masters',
                        subtitle: 'Social Deception',
                        icon: Icons.psychology_alt_rounded,
                        color: AddaColors.rose,
                        onTap: () => _enterFirstSpace(context, ref),
                      ),
                      _buildQuickPlayCard(
                        context,
                        title: 'Brain Arena',
                        subtitle: 'Speed & Logic',
                        icon: Icons.bolt_rounded,
                        color: AddaColors.violet,
                        onTap: () => _enterFirstSpace(context, ref),
                      ),
                    ],
                  ),
                ),
              ),

              // Spaces List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AddaSpacing.lg,
                    right: AddaSpacing.lg,
                    top: AddaSpacing.xl,
                    bottom: AddaSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Active Spaces',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => context.go('/hangout'),
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
              ),

              spacesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load spaces: $err'),
                  ),
                ),
                data: (spaces) {
                  if (spaces.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyStateView(
                        icon: Icons.group_work_outlined,
                        title: 'No Spaces Yet',
                        message:
                            'Create a space or join with a code from a friend.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AddaSpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final space = spaces[index];
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
                      }, childCount: spaces.length),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  void _enterFirstSpace(BuildContext context, WidgetRef ref) {
    final spaces = ref.read(spacesProvider).valueOrNull ?? [];
    if (spaces.isNotEmpty) {
      final space = spaces.first;
      context.push('/space/${space.id}/room', extra: space.name);
    } else {
      CreateSpaceSheet.show(context);
    }
  }

  Widget _buildQuickPlayCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderColor: color.withAlpha(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: AddaRadius.radiusSm,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
