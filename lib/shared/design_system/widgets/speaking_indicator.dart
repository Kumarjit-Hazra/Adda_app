import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Animated multi-bar speaking wave indicator.
class SpeakingIndicator extends StatefulWidget {
  final bool isSpeaking;
  final Color? color;
  final double height;

  const SpeakingIndicator({
    super.key,
    required this.isSpeaking,
    this.color,
    this.height = 14,
  });

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isSpeaking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AddaColors.emerald;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (index) {
            final phase = (index * 0.25);
            final value = widget.isSpeaking
                ? ((_controller.value + phase) % 1.0)
                : 0.2;
            final barHeight = (widget.height * (0.3 + (value * 0.7))).clamp(
              3.0,
              widget.height,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              width: 2.8,
              height: barHeight,
              decoration: BoxDecoration(
                color: widget.isSpeaking
                    ? activeColor
                    : activeColor.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
