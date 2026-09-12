import 'dart:math';
import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'rummy_models.dart';

class RummyEngine implements ActivityEngine<RummyState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'rummy',
    title: 'Indian Rummy (13 Cards)',
    description:
        'Classic 13-card Indian Rummy with pure sequences, wild jokers, and strategic melds.',
    category: ActivityCategory.cards,
    minPlayers: 2,
    maxPlayers: 6,
    estimatedDuration: Duration(minutes: 12),
    rules:
        '1. 13 cards dealt to each player.\n2. Draw 1 card from Closed or Open deck, Discard 1.\n3. Valid declaration requires at least 2 sequences, including 1 Pure Sequence.\n4. First valid declaration wins with 0 penalty points.',
  );

  List<RummyCard> _createTwoDecks() {
    final deck = <RummyCard>[];
    for (int d = 0; d < 2; d++) {
      for (final suit in RummySuit.values) {
        for (int r = 1; r <= 13; r++) {
          deck.add(RummyCard(suit: suit, rank: r));
        }
      }
    }
    deck.shuffle(Random(101));
    return deck;
  }

  @override
  RummyState createInitialState(List<String> playerIds) {
    final deck = _createTwoDecks();
    final players = <String, RummyPlayer>{};
    int cardIndex = 0;

    for (final pid in playerIds) {
      final hand = <RummyCard>[];
      for (int i = 0; i < 13; i++) {
        hand.add(deck[cardIndex++]);
      }
      players[pid] = RummyPlayer(
        id: pid,
        hand: hand,
        score: 0,
        hasDeclared: false,
      );
    }

    final wildJoker = deck[cardIndex++];
    final openDeck = [deck[cardIndex++]];
    final closedDeck = deck.sublist(cardIndex);

    return RummyState(
      version: 1,
      playerIds: playerIds,
      players: players,
      openDeck: openDeck,
      closedDeck: closedDeck,
      wildJoker: wildJoker,
      currentTurnIndex: 0,
      turnStage: RummyTurnStage.draw,
      isDeclared: false,
      isFinished: false,
    );
  }

  @override
  bool validateAction(RummyState state, PlayerAction action) {
    if (state.isFinished || state.isDeclared) return false;
    if (action.playerId != state.currentTurnPlayerId) return false;
    final player = state.players[action.playerId];
    if (player == null) return false;

    switch (action.type) {
      case 'draw_card':
        if (state.turnStage != RummyTurnStage.draw) return false;
        final source = action.payload['source'] as String?;
        if (source == 'open') return state.openDeck.isNotEmpty;
        if (source == 'closed') return state.closedDeck.isNotEmpty;
        return false;

      case 'discard_card':
        if (state.turnStage != RummyTurnStage.discard) return false;
        final index = action.payload['index'] as int?;
        return index != null && index >= 0 && index < player.hand.length;

      case 'declare':
        return state.turnStage == RummyTurnStage.discard &&
            player.hand.length == 14;

      default:
        return false;
    }
  }

  @override
  RummyState applyAction(RummyState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;
    final player = state.players[action.playerId]!;

    switch (action.type) {
      case 'draw_card':
        final source = action.payload['source'] as String;
        RummyCard drawnCard;
        List<RummyCard> updatedOpen = List.from(state.openDeck);
        List<RummyCard> updatedClosed = List.from(state.closedDeck);

        if (source == 'open') {
          drawnCard = updatedOpen.removeLast();
        } else {
          drawnCard = updatedClosed.removeLast();
        }

        final updatedHand = [...player.hand, drawnCard];
        final updatedPlayer = player.copyWith(hand: updatedHand);
        final updatedPlayers = Map<String, RummyPlayer>.from(state.players);
        updatedPlayers[action.playerId] = updatedPlayer;

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          openDeck: updatedOpen,
          closedDeck: updatedClosed,
          turnStage: RummyTurnStage.discard,
        );

      case 'discard_card':
        final index = action.payload['index'] as int;
        final discardedCard = player.hand[index];
        final updatedHand = List<RummyCard>.from(player.hand)..removeAt(index);

        final updatedPlayer = player.copyWith(hand: updatedHand);
        final updatedPlayers = Map<String, RummyPlayer>.from(state.players);
        updatedPlayers[action.playerId] = updatedPlayer;

        final nextTurn = (state.currentTurnIndex + 1) % state.playerIds.length;

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          openDeck: [...state.openDeck, discardedCard],
          currentTurnIndex: nextTurn,
          turnStage: RummyTurnStage.draw,
        );

      case 'declare':
        // Check groups or auto-validate
        final groups = <List<RummyCard>>[];
        final rawGroups = action.payload['groups'] as List<dynamic>?;

        if (rawGroups != null) {
          for (final g in rawGroups) {
            final cards = (g as List<dynamic>)
                .map((c) => RummyCard.fromMap(c as Map<String, dynamic>))
                .toList();
            groups.add(cards);
          }
        }

        final isValid =
            groups.isNotEmpty && RummyValidator.isValidDeclaration(groups);

        if (isValid) {
          final updatedPlayer = player.copyWith(hasDeclared: true);
          final updatedPlayers = Map<String, RummyPlayer>.from(state.players);
          updatedPlayers[action.playerId] = updatedPlayer;

          return state.copyWith(
            version: state.version + 1,
            players: updatedPlayers,
            isDeclared: true,
            winnerId: action.playerId,
            isFinished: true,
          );
        } else {
          // Wrong declaration penalty: 80 points, turn passes
          final updatedPlayer = player.copyWith(score: player.score + 80);
          final updatedPlayers = Map<String, RummyPlayer>.from(state.players);
          updatedPlayers[action.playerId] = updatedPlayer;
          final nextTurn =
              (state.currentTurnIndex + 1) % state.playerIds.length;

          return state.copyWith(
            version: state.version + 1,
            players: updatedPlayers,
            currentTurnIndex: nextTurn,
            turnStage: RummyTurnStage.draw,
          );
        }

      default:
        return state;
    }
  }

  @override
  bool isFinished(RummyState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(RummyState state) {
    return {
      'winnerId': state.winnerId,
      'isDeclared': state.isDeclared,
      'scores': state.players.map((k, v) => MapEntry(k, v.score)),
    };
  }

  @override
  String serialize(RummyState state) => state.toJson();

  @override
  RummyState deserialize(String raw) => RummyState.fromJson(raw);
}
