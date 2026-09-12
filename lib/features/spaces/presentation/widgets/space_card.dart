import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../domain/models/space_model.dart';

class SpaceCard extends StatelessWidget {
  final SpaceModel space;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  const SpaceCard({
    super.key,
    required this.space,
    required this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, h:mm a').format(space.lastActiveAt);

    return SurfaceCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AddaSpacing.md),
      padding: const EdgeInsets.all(AddaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: space.type.color.withAlpha(28),
                  borderRadius: AddaRadius.radiusMd,
                  border: Border.all(
                    color: space.type.color.withAlpha(80),
                    width: 1.2,
                  ),
                ),
                child: Icon(space.type.icon, color: space.type.color, size: 22),
              ),
              const SizedBox(width: AddaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      space.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: space.type.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (onFavoriteTap != null)
                IconButton(
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    space.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: space.isFavorite
                        ? AddaColors.amber
                        : (isDark
                              ? AddaColors.textMutedDark
                              : AddaColors.textMutedLight),
                    size: 22,
                  ),
                ),
            ],
          ),
          if (space.description.isNotEmpty) ...[
            const SizedBox(height: AddaSpacing.sm),
            Text(
              space.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AddaColors.textSecondaryDark
                    : AddaColors.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AddaSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AddaColors.surfaceVariantDark
                      : AddaColors.surfaceVariantLight,
                  borderRadius: AddaRadius.radiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 13,
                      color: isDark
                          ? AddaColors.textMutedDark
                          : AddaColors.textMutedLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      space.inviteCode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark
                            ? AddaColors.textPrimaryDark
                            : AddaColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: isDark
                        ? AddaColors.textMutedDark
                        : AddaColors.textMutedLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AddaColors.textMutedDark
                          : AddaColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
