import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../room/presentation/widgets/activity_launcher_sheet.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  void _showRulesDialog(BuildContext context, ActivityItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AddaColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: AddaRadius.radiusXl),
        title: Row(
          children: [
            Icon(item.icon, color: item.accentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 14,
                  color: AddaColors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  item.playerRange,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AddaColors.cyan,
                ),
                const SizedBox(width: 4),
                Text(
                  item.duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AppButton(text: 'Got It', onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Discover Activities',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AddaSpacing.lg),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(AddaSpacing.lg),
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1E4A), Color(0xFF160E2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AddaColors.violet.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AddaColors.violet,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AddaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modular Activity Engine',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All games run deterministically on the ADDA Activity SDK with zero voice drops.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AddaSpacing.lg),
          Text(
            'Signature Games & Puzzles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AddaSpacing.sm),
          ...ActivityLauncherSheet.activities.map((item) {
            return SurfaceCard(
              onTap: () => _showRulesDialog(context, item),
              margin: const EdgeInsets.only(bottom: AddaSpacing.md),
              padding: const EdgeInsets.all(AddaSpacing.md),
              borderColor: item.accentColor.withAlpha(60),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.accentColor.withAlpha(25),
                      borderRadius: AddaRadius.radiusMd,
                      border: Border.all(
                        color: item.accentColor.withAlpha(90),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(item.icon, color: item.accentColor, size: 26),
                  ),
                  const SizedBox(width: AddaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.accentColor.withAlpha(30),
                                borderRadius: AddaRadius.radiusXs,
                              ),
                              child: Text(
                                item.tag,
                                style: TextStyle(
                                  color: item.accentColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AddaColors.textSecondaryDark
                                : AddaColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 12,
                              color: isDark
                                  ? AddaColors.textMutedDark
                                  : AddaColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.playerRange,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AddaColors.textMutedDark
                                    : AddaColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: isDark
                                  ? AddaColors.textMutedDark
                                  : AddaColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.duration,
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
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    tooltip: 'View Rules',
                    onPressed: () => _showRulesDialog(context, item),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
