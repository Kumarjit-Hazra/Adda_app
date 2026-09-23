import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../../twenty_nine/twenty_nine_models.dart';
import 'card_component.dart';

class TrickComponent extends PositionComponent {
  final List<PlayedTrickCard> _currentTrick = [];
  bool isMyTurn;

  TextComponent? _emptyTextComp;

  TrickComponent({
    required List<PlayedTrickCard> currentTrick,
    this.isMyTurn = false,
  }) : super(size: Vector2(200, 180)) {
    _currentTrick.addAll(currentTrick);
  }

  @override
  Future<void> onLoad() async {
    final textPaint = TextPaint(
      style: const TextStyle(color: Colors.white38, fontSize: 12),
    );

    _emptyTextComp = TextComponent(text: '', textRenderer: textPaint);
    add(_emptyTextComp!);

    _syncCards();
  }

  void updateTrick(List<PlayedTrickCard> newTrick, bool newIsMyTurn) {
    bool shouldSync = false;

    if (_currentTrick.length != newTrick.length ||
        (_currentTrick.isNotEmpty &&
            newTrick.isNotEmpty &&
            _currentTrick.last.card.id != newTrick.last.card.id)) {
      _currentTrick.clear();
      _currentTrick.addAll(newTrick);
      shouldSync = true;
    }

    if (isMyTurn != newIsMyTurn) {
      isMyTurn = newIsMyTurn;
      shouldSync = true;
    }

    if (shouldSync) {
      _syncCards();
    }
  }

  void _syncCards() {
    removeAll(children.whereType<CardComponent>());

    if (_currentTrick.isEmpty) {
      if (_emptyTextComp != null) {
        _emptyTextComp!.text = isMyTurn
            ? 'Your Turn to Lead'
            : 'Waiting for card...';
        _emptyTextComp!.position = Vector2(size.x / 2 - 40, size.y / 2 - 6);
      }
      return;
    }

    if (_emptyTextComp != null) {
      _emptyTextComp!.text = '';
    }

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < _currentTrick.length; i++) {
      final trickCard = _currentTrick[i];
      final cardComp = CardComponent(card: trickCard.card);

      final offset = (i - (_currentTrick.length - 1) / 2) * 20;
      cardComp.position = Vector2(
        centerX - cardComp.size.x / 2 + offset,
        centerY - cardComp.size.y / 2 + (offset.abs() * 0.2),
      );

      add(cardComp);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    final bgPaint = Paint()..color = Colors.black.withAlpha(60);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);
  }
}
