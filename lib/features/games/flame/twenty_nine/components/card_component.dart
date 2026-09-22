import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Image;
import '../../../twenty_nine/twenty_nine_models.dart';

class CardComponent extends PositionComponent with TapCallbacks {
  final PlayingCard card;
  final bool isMyTurn;
  final void Function(PlayingCard)? onPlay;

  bool _isTapped = false;
  static const _debounceMs = 500;
  int _lastTapTime = 0;

  CardComponent({required this.card, this.isMyTurn = false, this.onPlay})
    : super(size: Vector2(58, 86));

  @override
  Future<void> onLoad() async {
    final isRed = card.suit.color == Colors.redAccent;
    final color = isRed ? Colors.red.shade800 : Colors.black87;
    // Dim the text if it's not my turn
    final alpha = isMyTurn ? 255 : 102; // 1.0 vs 0.4
    final displayColor = color.withAlpha(alpha);

    final rankTextPaint = TextPaint(
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: displayColor),
    );

    final suitTextPaint = TextPaint(
      style: TextStyle(fontSize: 24, color: displayColor),
    );

    // Top Left Rank
    add(
      TextComponent(
        text: card.rank.label,
        textRenderer: rankTextPaint,
        position: Vector2(4, 4),
      ),
    );

    // Center Suit
    final suitComp = TextComponent(
      text: card.suit.symbol,
      textRenderer: suitTextPaint,
    );
    // Position it in the center
    suitComp.position = Vector2(size.x / 2 - 10, size.y / 2 - 14);
    add(suitComp);

    // Bottom Right Rank
    final bottomRankComp = TextComponent(
      text: card.rank.label,
      textRenderer: rankTextPaint,
    );
    bottomRankComp.position = Vector2(size.x - 14, size.y - 18);
    add(bottomRankComp);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final alpha = isMyTurn ? 255 : 153; // 1.0 vs 0.6
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final bgPaint = Paint()..color = const Color(0xFFFDFDFD).withAlpha(alpha);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isMyTurn ? const Color(0xFFFF6B6B).withAlpha(alpha) : Colors.black26.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isMyTurn ? 2 : 1;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isMyTurn || onPlay == null) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < _debounceMs || _isTapped) {
      return; // Debounce duplicate rapid taps
    }
    
    _isTapped = true;
    _lastTapTime = now;
    
    onPlay!(card);
    
    // We expect the state to update and rebuild/remove this component shortly,
    // but just in case, we reset the tap lock after a while.
    Future.delayed(const Duration(milliseconds: _debounceMs), () {
      _isTapped = false;
    });
  }
}
