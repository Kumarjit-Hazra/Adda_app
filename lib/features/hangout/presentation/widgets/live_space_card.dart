import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../spaces/domain/models/space_model.dart';
import 'activity_badge.dart';

/// Compact horizontal card for the "Live Now" carousel in the Hangout screen.
/// Shows a pulsing green dot, space name, current activity, and participant count.
class LiveSpaceCard extends StatefulWidget {
  final SpaceModel space;
  final VoidCallback onTap;

  const LiveSpaceCard({super.key, required this.space, required this.onTap});

  @override
  State<LiveSpaceCard> createState() => _LiveSpaceCardState();
}

class _LiveSpaceCardState extends State<LiveSpaceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final space = widget.space;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: AddaSpacing.md),
        padding: const EdgeInsets.all(AddaSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? AddaColors.surfaceVariantDark
              : AddaColors.surfaceVariantLight,
          borderRadius: AddaRadius.radiusLg,
          border: Border.all(color: space.type.color.withAlpha(80), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: space.type.color.withAlpha(isDark ? 18 : 10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: icon + live indicator
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: space.type.color.withAlpha(28),
                    borderRadius: AddaRadius.radiusMd,
                  ),
                  child: Icon(
                    space.type.icon,
                    color: space.type.color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AddaColors.emerald.withAlpha(25),
                      borderRadius: AddaRadius.radiusFull,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: AddaColors.emerald),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AddaColors.emerald,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AddaSpacing.md),

            // Space name
            Text(
              space.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Activity badge
            if (space.currentActivityName != null)
              ActivityBadge(activityName: space.currentActivityName!),
            if (space.currentActivityName != null) const SizedBox(height: 8),

            // Participant count
            Row(
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: isDark
                      ? AddaColors.textMutedDark
                      : AddaColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${space.activeParticipantCount} online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AddaColors.textSecondaryDark
                        : AddaColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
