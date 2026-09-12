import 'dart:math';
import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'teen_patti_models.dart';

class TeenPattiEngine implements ActivityEngine<TeenPattiState> {
  static const int defaultBoot = 10;

  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'teen_patti',
    title: 'Teen Patti Royale',
    description:
        'Traditional Indian 3-card poker. Chaal, Blind, Showdowns, and pure psychological bluffs.',
    category: ActivityCategory.cards,
    minPlayers: 2,
    maxPlayers: 6,
    estimatedDuration: Duration(minutes: 10),
    rules:
        '1. 3 cards dealt per player.\n2. Play Blind (1x bet) or Seen (2x bet).\n3. Trail > Pure Sequence > Sequence > Color > Pair > High Card.\n4. Show down when 2 players remain.',
  );

  List<TeenPattiCard> _createDeck() {
    final deck = <TeenPattiCard>[];
    for (final suit in CardSuit.values) {
      for (int r = 2; r <= 14; r++) {
        deck.add(TeenPattiCard(suit: suit, rank: r));
      }
    }
    deck.shuffle(Random(42));
    return deck;
  }

  @override
  TeenPattiState createInitialState(List<String> playerIds) {
    final deck = _createDeck();
    final players = <String, TeenPattiPlayer>{};
    int cardIndex = 0;

    for (final pid in playerIds) {
      final hand = [deck[cardIndex++], deck[cardIndex++], deck[cardIndex++]];
      players[pid] = TeenPattiPlayer(
        id: pid,
        chips: 1000 - defaultBoot,
        currentBet: defaultBoot,
        cards: hand,
        isFolded: false,
        hasSeenCards: false,
      );
    }

    return TeenPattiState(
      version: 1,
      playerIds: playerIds,
      players: players,
      pot: defaultBoot * playerIds.length,
      currentMinChaal: defaultBoot,
      currentTurnIndex: 0,
      roundOver: false,
      isFinished: false,
    );
  }

  @override
  bool validateAction(TeenPattiState state, PlayerAction action) {
    if (state.roundOver || state.isFinished) return false;
    final player = state.players[action.playerId];
    if (player == null || player.isFolded) return false;

    switch (action.type) {
      case 'see_cards':
        return !player.hasSeenCards;
      case 'bet_chaal':
        return action.playerId == state.currentTurnPlayerId;
      case 'fold':
        return action.playerId == state.currentTurnPlayerId;
      case 'show_down':
        return action.playerId == state.currentTurnPlayerId &&
            state.activePlayers.length == 2;
      default:
        return false;
    }
  }

  @override
  TeenPattiState applyAction(TeenPattiState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;
    final player = state.players[action.playerId]!;

    switch (action.type) {
      case 'see_cards':
        final updatedPlayer = player.copyWith(hasSeenCards: true);
        final updatedPlayers = Map<String, TeenPattiPlayer>.from(state.players);
        updatedPlayers[action.playerId] = updatedPlayer;

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
        );

      case 'bet_chaal':
        final betAmount = player.hasSeenCards
            ? state.currentMinChaal * 2
            : state.currentMinChaal;
        final updatedPlayer = player.copyWith(
          chips: player.chips - betAmount,
          currentBet: player.currentBet + betAmount,
        );

        final updatedPlayers = Map<String, TeenPattiPlayer>.from(state.players);
        updatedPlayers[action.playerId] = updatedPlayer;

        final nextTurn = _getNextTurnIndex(state, state.currentTurnIndex);

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          pot: state.pot + betAmount,
          currentTurnIndex: nextTurn,
        );

      case 'fold':
        final updatedPlayer = player.copyWith(isFolded: true);
        final updatedPlayers = Map<String, TeenPattiPlayer>.from(state.players);
        updatedPlayers[action.playerId] = updatedPlayer;

        final remaining = updatedPlayers.values
            .where((p) => !p.isFolded)
            .toList();
        if (remaining.length == 1) {
          // Single player remaining, auto-win
          final winner = remaining.first;
          final winnerWithPot = winner.copyWith(
            chips: winner.chips + state.pot,
          );
          updatedPlayers[winner.id] = winnerWithPot;

          return state.copyWith(
            version: state.version + 1,
            players: updatedPlayers,
            roundOver: true,
            winnerId: winner.id,
            winningHandDescription: 'Won by default (All opponents folded)',
            isFinished: true,
          );
        }

        final nextTurn = _getNextTurnIndex(state, state.currentTurnIndex);

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          currentTurnIndex: nextTurn,
        );

      case 'show_down':
        // Exactly 2 players show down
        final active = state.activePlayers;
        final p1 = active[0];
        final p2 = active[1];

        final eval1 = HandEvaluator.evaluate(p1.cards);
        final eval2 = HandEvaluator.evaluate(p2.cards);

        final p1Wins = eval1.score >= eval2.score;
        final winnerId = p1Wins ? p1.id : p2.id;
        final bestEval = p1Wins ? eval1 : eval2;

        final updatedPlayers = Map<String, TeenPattiPlayer>.from(state.players);
        final winner = updatedPlayers[winnerId]!;
        updatedPlayers[winnerId] = winner.copyWith(
          chips: winner.chips + state.pot,
        );

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          roundOver: true,
          winnerId: winnerId,
          winningHandDescription:
              '${bestEval.description} (${bestEval.type.name.toUpperCase()})',
          isFinished: true,
        );

      default:
        return state;
    }
  }

  int _getNextTurnIndex(TeenPattiState state, int currentIndex) {
    int next = (currentIndex + 1) % state.playerIds.length;
    while (state.players[state.playerIds[next]]!.isFolded) {
      next = (next + 1) % state.playerIds.length;
    }
    return next;
  }

  @override
  bool isFinished(TeenPattiState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(TeenPattiState state) {
    return {
      'winnerId': state.winnerId,
      'potWon': state.pot,
      'winningHand': state.winningHandDescription,
    };
  }

  @override
  String serialize(TeenPattiState state) => state.toJson();

  @override
  TeenPattiState deserialize(String raw) => TeenPattiState.fromJson(raw);
}
