import 'dart:math';
import 'package:flutter/material.dart';

class FloatingItem {
  final Key key;
  final String emoji;
  final double startX; // 0.0 to 1.0 fraction of screen width
  final DateTime createdAt;

  FloatingItem({
    required this.key,
    required this.emoji,
    required this.startX,
    required this.createdAt,
  });
}

class FloatingReactionOverlay extends StatefulWidget {
  final Widget child;

  const FloatingReactionOverlay({super.key, required this.child});

  static FloatingReactionOverlayState of(BuildContext context) {
    final state = context
        .findAncestorStateOfType<FloatingReactionOverlayState>();
    assert(state != null, 'No FloatingReactionOverlay found in context');
    return state!;
  }

  @override
  FloatingReactionOverlayState createState() => FloatingReactionOverlayState();
}

class FloatingReactionOverlayState extends State<FloatingReactionOverlay>
    with TickerProviderStateMixin {
  final List<FloatingItem> _items = [];

  void spawnSticker(String emoji) {
    final randX = 0.65 + (Random().nextDouble() * 0.25); // towards right side
    final item = FloatingItem(
      key: UniqueKey(),
      emoji: emoji,
      startX: randX,
      createdAt: DateTime.now(),
    );

    setState(() {
      _items.add(item);
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _items.remove(item);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: _items
                  .map((item) => _FloatingBubble(item: item))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingBubble extends StatefulWidget {
  final FloatingItem item;

  _FloatingBubble({required this.item}) : super(key: item.key);

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  late double _wobblePhase;

  @override
  void initState() {
    super.initState();
    _wobblePhase = Random().nextDouble() * 2 * pi;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final screen = MediaQuery.of(context).size;
        final t = _progress.value;

        final y = screen.height * (0.85 - (t * 0.6));
        final wobble = sin((t * 4 * pi) + _wobblePhase) * 20.0;
        final x = (widget.item.startX * screen.width) + wobble;

        final opacity = t < 0.2
            ? (t / 0.2)
            : (t > 0.7 ? ((1.0 - t) / 0.3).clamp(0.0, 1.0) : 1.0);
        final scale = t < 0.2 ? (0.6 + (t / 0.2) * 0.6) : (1.2 - (t * 0.2));

        return Positioned(
          left: x - 25,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.item.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
