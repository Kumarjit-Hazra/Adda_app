import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

class PlayerSeatComponent extends PositionComponent {
  String playerId;
  String name;
  bool isTurn;

  TextComponent? _initialComp;
  TextComponent? _nameComp;

  PlayerSeatComponent({
    required this.playerId,
    required this.name,
    this.isTurn = false,
  }) : super(size: Vector2(80, 60));

  @override
  Future<void> onLoad() async {
    final avatarPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );

    final centerX = size.x / 2;

    final initial = name.isNotEmpty ? name[0] : '?';
    _initialComp = TextComponent(text: initial, textRenderer: avatarPaint);
    _initialComp!.position = Vector2(
      centerX - 4,
      14,
    ); // roughly centered in circle
    add(_initialComp!);

    _nameComp = TextComponent(
      text: _formatName(name),
      textRenderer: _getNamePaint(),
    );
    _nameComp!.position = Vector2(centerX - 16, 44);
    add(_nameComp!);
  }

  void updatePlayer(String newPlayerId, String newName, bool newIsTurn) {
    bool requiresRedraw = isTurn != newIsTurn || name != newName;
    playerId = newPlayerId;
    name = newName;
    isTurn = newIsTurn;

    if (requiresRedraw) {
      if (_initialComp != null) {
        _initialComp!.text = name.isNotEmpty ? name[0] : '?';
      }
      if (_nameComp != null) {
        _nameComp!.text = _formatName(name);
        _nameComp!.textRenderer = _getNamePaint();
      }
    }
  }

  String _formatName(String rawName) {
    return rawName.length > 8 ? '${rawName.substring(0, 8)}...' : rawName;
  }

  TextPaint _getNamePaint() {
    return TextPaint(
      style: TextStyle(
        fontSize: 11,
        fontWeight: isTurn ? FontWeight.w700 : FontWeight.w500,
        color: isTurn ? const Color(0xFF10B981) : Colors.white70,
      ),
    );
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
