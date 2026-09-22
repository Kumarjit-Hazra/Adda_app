import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Image;
import '../../../twenty_nine/twenty_nine_models.dart';

class CardComponent extends PositionComponent with TapCallbacks {
  final PlayingCard card;
  final bool isMyTurn;
  final void Function(PlayingCard)? onPlay;

  CardComponent({required this.card, this.isMyTurn = false, this.onPlay})
    : super(size: Vector2(58, 86));

  @override
  Future<void> onLoad() async {
    final isRed = card.suit.color == Colors.redAccent;
    final color = isRed ? Colors.red.shade800 : Colors.black87;

    final rankTextPaint = TextPaint(
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
    );

    final suitTextPaint = TextPaint(
      style: TextStyle(fontSize: 24, color: color),
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
    // Position it in the center (rough estimation)
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

    // Draw card background
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final bgPaint = Paint()..color = const Color(0xFFFDFDFD);
    canvas.drawRRect(rrect, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = isMyTurn ? const Color(0xFFFF6B6B) : Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = isMyTurn ? 2 : 1;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isMyTurn && onPlay != null) {
      onPlay!(card);
    }
  }
}
