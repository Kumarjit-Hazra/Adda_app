import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/state_views.dart';
import '../../domain/models/space_model.dart';
import '../providers/space_provider.dart';
import '../widgets/create_space_sheet.dart';
import '../widgets/join_space_dialog.dart';
import '../widgets/space_card.dart';

class SpacesScreen extends ConsumerStatefulWidget {
  const SpacesScreen({super.key});

  @override
  ConsumerState<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends ConsumerState<SpacesScreen> {
  SpaceType? _filterType;

  @override
  Widget build(BuildContext context) {
    final spacesAsync = ref.watch(spacesProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Spaces',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
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
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AddaSpacing.lg,
              vertical: AddaSpacing.sm,
            ),
            child: Row(
              children: [
                _buildFilterChip('All Spaces', null),
                ...SpaceType.values.map(
                  (type) => _buildFilterChip(type.displayName, type),
                ),
              ],
            ),
          ),
          const Divider(),

          // Space list
          Expanded(
            child: spacesAsync.when(
              loading: () =>
                  const LoadingStateView(message: 'Loading Spaces...'),
              error: (err, _) => ErrorStateView(
                message: err.toString(),
                onRetry: () => ref.read(spacesProvider.notifier).loadSpaces(),
              ),
              data: (allSpaces) {
                final filtered = _filterType == null
                    ? allSpaces
                    : allSpaces.where((s) => s.type == _filterType).toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: 'No Spaces Found',
                    message: _filterType == null
                        ? 'Create your first Space to start hanging out with friends.'
                        : 'No ${_filterType!.displayName} spaces yet.',
                    actionLabel: 'Create Space',
                    onAction: () => CreateSpaceSheet.show(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AddaSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final space = filtered[index];
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
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildFilterChip(String label, SpaceType? type) {
    final isSelected = _filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AddaColors.coral.withAlpha(40),
        checkmarkColor: AddaColors.coral,
        labelStyle: TextStyle(
          color: isSelected
              ? AddaColors.coral
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        backgroundColor: isDark
            ? AddaColors.surfaceVariantDark
            : AddaColors.surfaceVariantLight,
        shape: RoundedRectangleBorder(borderRadius: AddaRadius.radiusFull),
        side: BorderSide(
          color: isSelected ? AddaColors.coral : Colors.transparent,
        ),
        onSelected: (_) => setState(() => _filterType = type),
      ),
    );
  }
}
