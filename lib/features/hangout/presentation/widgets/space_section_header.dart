import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

/// Reusable section header for the Hangout screen.
/// Shows a title, optional count badge, and optional trailing action widget.
class SpaceSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;

  const SpaceSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: isDark
                  ? AddaColors.textPrimaryDark
                  : AddaColors.textPrimaryLight,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AddaColors.coral.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AddaColors.coral,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!, // ignore: use_null_aware_elements
        ],
      ),
    );
  }
}
