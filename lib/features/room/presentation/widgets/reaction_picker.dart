import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';

class ReactionPicker extends StatelessWidget {
  final ValueChanged<String> onSelectEmoji;

  const ReactionPicker({super.key, required this.onSelectEmoji});

  static const List<String> _emojis = [
    '❤️',
    '😂',
    '🔥',
    '👏',
    '🎉',
    '☕️',
    '🤯',
    '🃏',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AddaColors.surfaceVariantDark
            : AddaColors.surfaceVariantLight,
        borderRadius: AddaRadius.radiusFull,
        border: Border.all(
          color: isDark
              ? AddaColors.borderLuminousDark
              : AddaColors.borderLuminousLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _emojis.map((emoji) {
          return GestureDetector(
            onTap: () => onSelectEmoji(emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
