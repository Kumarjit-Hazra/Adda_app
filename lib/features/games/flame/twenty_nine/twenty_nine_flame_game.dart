import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../twenty_nine/twenty_nine_models.dart';
import '../../twenty_nine/presentation/twenty_nine_controller.dart';
import '../core/adda_flame_game.dart';
import '../../domain/game_session.dart';
import 'components/card_component.dart';
import 'components/player_seat_component.dart';
import 'components/trick_component.dart';
import 'models/twenty_nine_presentation_snapshot.dart';

class TwentyNineFlameGame extends AddaFlameGame<TwentyNineState>
    with TapCallbacks {
  final TwentyNineController controller;
  final String localUserId;

  PlayerSeatComponent? _topSeat;
  PlayerSeatComponent? _leftSeat;
  PlayerSeatComponent? _rightSeat;
  TrickComponent? _trickComponent;

  final List<CardComponent> _handCards = [];
  TwentyNinePresentationSnapshot? _snapshot;

  TwentyNineFlameGame({required this.controller, required this.localUserId});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Pre-create components
    _trickComponent = TrickComponent(currentTrick: [], isMyTurn: false);
    add(_trickComponent!);

    _topSeat = PlayerSeatComponent(playerId: '', name: '', isTurn: false);
    add(_topSeat!);

    _leftSeat = PlayerSeatComponent(playerId: '', name: '', isTurn: false);
    add(_leftSeat!);

    _rightSeat = PlayerSeatComponent(playerId: '', name: '', isTurn: false);
    add(_rightSeat!);

    if (gameSession != null && gameState != null) {
      _applyStateUpdate(gameSession!, gameState!);
    }
  }

  @override
  void onStateUpdate(GameSession session, TwentyNineState state) {
    _applyStateUpdate(session, state);
  }

  void _applyStateUpdate(GameSession session, TwentyNineState state) {
    if (!isMounted) return;

    final myIndex = state.playerIds.indexOf(localUserId);
    if (myIndex == -1) return; // Spectator or not in game

    final leftIndex = (myIndex + 1) % 4;
    final topIndex = (myIndex + 2) % 4;
    final rightIndex = (myIndex + 3) % 4;

    final leftId = state.playerIds[leftIndex];
    final topId = state.playerIds[topIndex];
    final rightId = state.playerIds[rightIndex];

    final currentTurnId = state.playerIds[state.currentTurnIndex];

    final newSnapshot = TwentyNinePresentationSnapshot(
      phase: state.phase,
      version: state.version,
      myHand: state.hands[localUserId] ?? [],
      currentTrick: state.currentTrick,
      myData: PlayerPresentationData(
        id: localUserId,
        name: _getPlayerName(session, localUserId),
        isTurn: currentTurnId == localUserId,
      ),
      leftData: PlayerPresentationData(
        id: leftId,
        name: _getPlayerName(session, leftId),
        isTurn: currentTurnId == leftId,
      ),
      topData: PlayerPresentationData(
        id: topId,
        name: _getPlayerName(session, topId),
        isTurn: currentTurnId == topId,
      ),
      rightData: PlayerPresentationData(
        id: rightId,
        name: _getPlayerName(session, rightId),
        isTurn: currentTurnId == rightId,
      ),
    );

    if (_snapshot == newSnapshot) return;

    _updateComponents(newSnapshot);
    _snapshot = newSnapshot;
  }

  String _getPlayerName(GameSession session, String playerId) {
    if (playerId.startsWith('bot_')) return 'Bot ${playerId.split('_').last}';
    try {
      return session.players.firstWhere((p) => p.id == playerId).name;
    } catch (_) {
      return playerId.length > 4 ? playerId.substring(0, 4) : playerId;
    }
  }

  void _updateComponents(TwentyNinePresentationSnapshot snapshot) {
    _trickComponent?.updateTrick(
      snapshot.currentTrick.toList(),
      snapshot.myData.isTurn && snapshot.phase == TwentyNinePhase.playing,
    );

    _topSeat?.updatePlayer(
      snapshot.topData.id,
      snapshot.topData.name,
      snapshot.topData.isTurn,
    );
    _leftSeat?.updatePlayer(
      snapshot.leftData.id,
      snapshot.leftData.name,
      snapshot.leftData.isTurn,
    );
    _rightSeat?.updatePlayer(
      snapshot.rightData.id,
      snapshot.rightData.name,
      snapshot.rightData.isTurn,
    );

    // Diff hand cards
    if (_snapshot == null ||
        !_listEquals(_snapshot!.myHand, snapshot.myHand) ||
        _snapshot!.phase != snapshot.phase ||
        _snapshot!.myData.isTurn != snapshot.myData.isTurn) {
      removeAll(_handCards);
      _handCards.clear();

      for (int i = 0; i < snapshot.myHand.length; i++) {
        final card = snapshot.myHand[i];
        final cardComp = CardComponent(
          card: card,
          isMyTurn:
              snapshot.myData.isTurn &&
              snapshot.phase == TwentyNinePhase.playing,
          onPlay: (PlayingCard playedCard) {
            controller.playCard(
              playedCard.toMap(),
              localUserId,
              snapshot.version,
            );
          },
        );
        _handCards.add(cardComp);
        add(cardComp);
      }
      _layoutHand();
    }
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutBoard();
  }

  void _layoutBoard() {
    _trickComponent?.position = Vector2(size.x / 2 - 100, size.y / 2 - 90);
    _topSeat?.position = Vector2(size.x / 2 - 40, 20);
    _leftSeat?.position = Vector2(10, size.y / 2 - 30);
    _rightSeat?.position = Vector2(size.x - 90, size.y / 2 - 30);
    _layoutHand();
  }

  void _layoutHand() {
    final handWidth = _handCards.length * 62.0;
    final startX = (size.x - handWidth) / 2;
    for (int i = 0; i < _handCards.length; i++) {
      _handCards[i].position = Vector2(startX + (i * 62), size.y - 100);
    }
  }
}
