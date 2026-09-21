import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class ChatComposer extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool isSending;

  const ChatComposer({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: AddaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AddaColors.borderDark : AddaColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _handleSend(),
                enabled: !widget.isSending,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  fillColor: isDark
                      ? AddaColors.surfaceVariantDark
                      : AddaColors.surfaceVariantLight,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: AddaRadius.radiusFull,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: widget.isSending ? null : _handleSend,
              icon: widget.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AddaColors.coral,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AddaColors.coral.withValues(alpha: 0.5 * 255),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
