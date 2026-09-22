import 'package:flutter/material.dart';
import '../../presentation/game_presentation_registry.dart';
import '../../domain/game_session.dart';
import 'twenty_nine_board.dart';
import '../twenty_nine_models.dart';

class TwentyNineAdapter implements GamePresentationAdapter {
  @override
  Widget buildBoard() {
    return const TwentyNineBoard();
  }

  @override
  String getResultMessage(GameSession session, String localUserId) {
    if (session.state is! TwentyNineState) return 'Game Over';
    final state = session.state as TwentyNineState;

    final myPlayer = session.players.firstWhere(
      (p) => p.id == localUserId,
      orElse: () => session.players.first,
    );
    final myTeam = myPlayer.teamIndex;

    if (state.winnerTeam == myTeam) {
      return 'Victory!\\nYour team scored ${state.teamTrickPoints[myTeam]} pts.';
    } else if (state.winnerTeam != null) {
      return 'Defeat!\\nOpponents scored ${state.teamTrickPoints[state.winnerTeam!]} pts.';
    }
    return 'Game Over';
  }

  @override
  bool isVictory(GameSession session, String localUserId) {
    if (session.state is! TwentyNineState) return false;
    final state = session.state as TwentyNineState;

    final myPlayer = session.players.firstWhere(
      (p) => p.id == localUserId,
      orElse: () => session.players.first,
    );
    return state.winnerTeam == myPlayer.teamIndex;
  }
}
