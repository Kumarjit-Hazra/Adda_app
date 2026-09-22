import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

class PlayerSeatComponent extends PositionComponent {
  final String playerId;
  final String name;
  final bool isTurn;

  PlayerSeatComponent({
    required this.playerId,
    required this.name,
    this.isTurn = false,
  }) : super(size: Vector2(80, 60));

  @override
  Future<void> onLoad() async {
    final namePaint = TextPaint(
      style: TextStyle(
        fontSize: 11,
        fontWeight: isTurn ? FontWeight.w700 : FontWeight.w500,
        color: isTurn ? const Color(0xFF10B981) : Colors.white70,
      ),
    );

    final avatarPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );

    final centerX = size.x / 2;

    final initial = name.isNotEmpty ? name[0] : '?';
    final initialComp = TextComponent(text: initial, textRenderer: avatarPaint);
    initialComp.position = Vector2(
      centerX - 4,
      14,
    ); // roughly centered in circle
    add(initialComp);

    final nameStr = name.length > 8 ? '${name.substring(0, 8)}...' : name;
    final nameComp = TextComponent(text: nameStr, textRenderer: namePaint);
    nameComp.position = Vector2(centerX - 16, 44);
    add(nameComp);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final centerX = size.x / 2;

    // Draw avatar border/circle
    final avatarCenter = Offset(centerX, 20);
    final bgPaint = Paint()
      ..color = isTurn ? const Color(0xFF10B981).withAlpha(40) : Colors.black45;
    canvas.drawCircle(avatarCenter, 16, bgPaint);

    final borderPaint = Paint()
      ..color = isTurn ? const Color(0xFF10B981) : Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTurn ? 2.5 : 1.0;
    canvas.drawCircle(avatarCenter, 18, borderPaint);
  }
}
