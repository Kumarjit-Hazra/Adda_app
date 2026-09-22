import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../twenty_nine/twenty_nine_models.dart';
import '../../twenty_nine/presentation/twenty_nine_controller.dart';
import '../core/adda_flame_game.dart';
import 'components/card_component.dart';
import 'components/player_seat_component.dart';
import 'components/trick_component.dart';

class TwentyNineFlameGame extends AddaFlameGame<TwentyNineState>
    with TapCallbacks {
  final TwentyNineController controller;
  final String localUserId;

  PlayerSeatComponent? _topSeat;
  PlayerSeatComponent? _leftSeat;
  PlayerSeatComponent? _rightSeat;
  TrickComponent? _trickComponent;

  final List<CardComponent> _handCards = [];

  TwentyNineFlameGame({required this.controller, required this.localUserId});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Initialize components if state is already present
    if (gameState != null) {
      _rebuildBoard(gameState!);
    }
  }

  @override
  void onStateUpdate(TwentyNineState state) {
    _rebuildBoard(state);
  }

  void _rebuildBoard(TwentyNineState state) {
    if (!isMounted) return;

    // We assume 4 players. Top, Left, Right, Bottom (us).
    // In ADDA's current board: index 2 is top (partner), index 1 is left, index 3 is right.
    // Wait, the players list might not be indexed this way, but TwentyNineState
    // provides playerIds ordered by turn sequence.

    final myIndex = state.playerIds.indexOf(localUserId);
    if (myIndex == -1) return; // Spectator or not in game

    final leftIndex = (myIndex + 1) % 4;
    final topIndex = (myIndex + 2) % 4;
    final rightIndex = (myIndex + 3) % 4;

    final leftId = state.playerIds[leftIndex];
    final topId = state.playerIds[topIndex];
    final rightId = state.playerIds[rightIndex];

    // Cleanup old components
    if (_topSeat != null) remove(_topSeat!);
    if (_leftSeat != null) remove(_leftSeat!);
    if (_rightSeat != null) remove(_rightSeat!);
    if (_trickComponent != null) remove(_trickComponent!);

    removeAll(_handCards);
    _handCards.clear();

    // Recreate Trick
    _trickComponent = TrickComponent(
      currentTrick: state.currentTrick,
      isMyTurn:
          state.playerIds[state.currentTurnIndex] == localUserId &&
          state.phase == TwentyNinePhase.playing,
    );

    // Position trick in center
    _trickComponent!.position = Vector2(size.x / 2 - 100, size.y / 2 - 90);
    add(_trickComponent!);

    // Top seat
    _topSeat = PlayerSeatComponent(
      playerId: topId,
      name: _getPlayerName(topId),
      isTurn: state.playerIds[state.currentTurnIndex] == topId,
    );
    _topSeat!.position = Vector2(size.x / 2 - 40, 20); // Top center
    add(_topSeat!);

    // Left seat
    _leftSeat = PlayerSeatComponent(
      playerId: leftId,
      name: _getPlayerName(leftId),
      isTurn: state.playerIds[state.currentTurnIndex] == leftId,
    );
    _leftSeat!.position = Vector2(10, size.y / 2 - 30); // Left middle
    add(_leftSeat!);

    // Right seat
    _rightSeat = PlayerSeatComponent(
      playerId: rightId,
      name: _getPlayerName(rightId),
      isTurn: state.playerIds[state.currentTurnIndex] == rightId,
    );
    _rightSeat!.position = Vector2(
      size.x - 90,
      size.y / 2 - 30,
    ); // Right middle
    add(_rightSeat!);

    // Player Hand (Bottom)
    final myHand = state.hands[localUserId] ?? [];
    final handWidth = myHand.length * 62.0; // 58 card width + 4 margin
    final startX = (size.x - handWidth) / 2;

    final isMyTurn = state.playerIds[state.currentTurnIndex] == localUserId;

    for (int i = 0; i < myHand.length; i++) {
      final card = myHand[i];
      final cardComp = CardComponent(
        card: card,
        isMyTurn: isMyTurn && state.phase == TwentyNinePhase.playing,
        onPlay: (PlayingCard playedCard) {
          controller.playCard(playedCard.toMap(), localUserId, state.version);
        },
      );

      cardComp.position = Vector2(startX + (i * 62), size.y - 100);
      _handCards.add(cardComp);
      add(cardComp);
    }
  }

  String _getPlayerName(String playerId) {
    // We don't have direct access to GameSession.players here.
    // The name is normally retrieved from GameSession.
    // Since we don't pass GameSession to Flame, only TwentyNineState,
    // and TwentyNineState only has IDs, we might need a workaround.
    // For simplicity, we just use the ID as a placeholder or 'Player X'.
    // Ideally, state would carry names, but to preserve architecture without
    // modifying domain excessively, we'll use a shortened ID.
    if (playerId == 'bot_1') return 'Bot 1';
    if (playerId == 'bot_2') return 'Bot 2';
    if (playerId == 'bot_3') return 'Bot 3';
    return playerId.length > 4 ? playerId.substring(0, 4) : playerId;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Re-layout if state exists
    if (gameState != null) {
      _rebuildBoard(gameState!);
    }
  }
}
