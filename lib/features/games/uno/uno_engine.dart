import 'dart:math';
import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'uno_models.dart';

class UnoEngine implements ActivityEngine<UnoState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'uno',
    title: 'UNO Clash',
    description:
        'Fast-paced card matching game. Match color or number, play action cards, and empty your hand first.',
    category: ActivityCategory.cards,
    minPlayers: 2,
    maxPlayers: 6,
    estimatedDuration: Duration(minutes: 10),
    rules: '''
1. Each player starts with 7 cards.
2. Match the top card by Color, Number, or Action.
3. Action cards: Skip, Reverse, Draw Two (+2).
4. Wild cards can be played anytime to change the active color.
5. First player to empty their hand wins!
''',
  );

  List<UnoCard> _generateDeck() {
    final deck = <UnoCard>[];
    const standardColors = [
      UnoColor.red,
      UnoColor.blue,
      UnoColor.green,
      UnoColor.yellow,
    ];

    for (final color in standardColors) {
      deck.add(UnoCard(color, UnoValue.zero));
      for (int i = 0; i < 2; i++) {
        deck.add(UnoCard(color, UnoValue.one));
        deck.add(UnoCard(color, UnoValue.two));
        deck.add(UnoCard(color, UnoValue.three));
        deck.add(UnoCard(color, UnoValue.four));
        deck.add(UnoCard(color, UnoValue.five));
        deck.add(UnoCard(color, UnoValue.six));
        deck.add(UnoCard(color, UnoValue.seven));
        deck.add(UnoCard(color, UnoValue.eight));
        deck.add(UnoCard(color, UnoValue.nine));
        deck.add(UnoCard(color, UnoValue.skip));
        deck.add(UnoCard(color, UnoValue.reverse));
        deck.add(UnoCard(color, UnoValue.drawTwo));
      }
    }

    for (int i = 0; i < 4; i++) {
      deck.add(const UnoCard(UnoColor.wild, UnoValue.wild));
      deck.add(const UnoCard(UnoColor.wild, UnoValue.wildDrawFour));
    }

    return deck;
  }

  @override
  UnoState createInitialState(List<String> playerIds) {
    final actualPlayers = List<String>.from(playerIds);
    while (actualPlayers.length < 3) {
      actualPlayers.add('bot_${actualPlayers.length + 1}');
    }

    final deck = _generateDeck()..shuffle(Random(123));
    final hands = <String, List<UnoCard>>{};

    for (int i = 0; i < actualPlayers.length; i++) {
      hands[actualPlayers[i]] = deck.sublist(i * 7, (i + 1) * 7);
    }

    // Find a non-wild starting card for the discard pile
    int startCardIndex = actualPlayers.length * 7;
    while (deck[startCardIndex].isWild) {
      startCardIndex++;
    }

    final firstDiscard = deck[startCardIndex];
    final remainingDeck = List<UnoCard>.from(deck)..removeAt(startCardIndex);
    final drawPile = remainingDeck.sublist(actualPlayers.length * 7);

    return UnoState(
      version: 1,
      playerIds: actualPlayers,
      hands: hands,
      drawPile: drawPile,
      discardPile: [firstDiscard],
      currentTurnIndex: 0,
      isClockwise: true,
      activeColor: firstDiscard.color,
      winnerId: null,
      hasShoutedUno: false,
    );
  }

  @override
  bool validateAction(UnoState state, PlayerAction action) {
    if (state.winnerId != null) return false;
    final currentPlayerId = state.playerIds[state.currentTurnIndex];
    if (action.playerId != currentPlayerId) return false;

    switch (action.type) {
      case 'play_card':
        final card = UnoCard.fromMap(
          action.payload['card'] as Map<String, dynamic>,
        );
        final hand = state.hands[action.playerId] ?? [];
        if (!hand.contains(card)) return false;

        // Card must match active color or top discard value, or be wild
        if (card.isWild) return true;
        if (card.color == state.activeColor) return true;
        if (card.value == state.topDiscard.value) return true;
        return false;

      case 'draw_card':
        return true;

      case 'shout_uno':
        final hand = state.hands[action.playerId] ?? [];
        return hand.length <= 2;

      default:
        return false;
    }
  }

  @override
  UnoState applyAction(UnoState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    final count = state.playerIds.length;
    int step = state.isClockwise ? 1 : -1;

    switch (action.type) {
      case 'shout_uno':
        return state.copyWith(version: state.version + 1, hasShoutedUno: true);

      case 'draw_card':
        var currentDrawPile = List<UnoCard>.from(state.drawPile);
        var currentDiscardPile = List<UnoCard>.from(state.discardPile);

        if (currentDrawPile.isEmpty) {
          final top = currentDiscardPile.removeLast();
          currentDrawPile = currentDiscardPile..shuffle();
          currentDiscardPile = [top];
        }

        final drawn = currentDrawPile.removeLast();
        final updatedHand = List<UnoCard>.from(state.hands[action.playerId]!)
          ..add(drawn);
        final newHands = Map<String, List<UnoCard>>.from(state.hands);
        newHands[action.playerId] = updatedHand;

        final nextTurn = (state.currentTurnIndex + step + count) % count;

        return state.copyWith(
          version: state.version + 1,
          hands: newHands,
          drawPile: currentDrawPile,
          discardPile: currentDiscardPile,
          currentTurnIndex: nextTurn,
        );

      case 'play_card':
        final card = UnoCard.fromMap(
          action.payload['card'] as Map<String, dynamic>,
        );
        final chosenColorStr = action.payload['chosenColor'] as String?;
        final chosenColor = chosenColorStr != null
            ? UnoColor.values.firstWhere(
                (c) => c.name == chosenColorStr,
                orElse: () => UnoColor.red,
              )
            : card.color;

        final updatedHand = List<UnoCard>.from(state.hands[action.playerId]!)
          ..remove(card);
        final newHands = Map<String, List<UnoCard>>.from(state.hands);
        newHands[action.playerId] = updatedHand;

        final newDiscard = List<UnoCard>.from(state.discardPile)..add(card);
        var newDrawPile = List<UnoCard>.from(state.drawPile);

        // Win check
        if (updatedHand.isEmpty) {
          return state.copyWith(
            version: state.version + 1,
            hands: newHands,
            discardPile: newDiscard,
            winnerId: action.playerId,
          );
        }

        // Evaluate action card effects
        var nextClockwise = state.isClockwise;
        var nextTurn = state.currentTurnIndex;

        if (card.value == UnoValue.reverse) {
          nextClockwise = !nextClockwise;
          step = nextClockwise ? 1 : -1;
          nextTurn = (state.currentTurnIndex + step + count) % count;
        } else if (card.value == UnoValue.skip) {
          nextTurn = (state.currentTurnIndex + (step * 2) + count) % count;
        } else if (card.value == UnoValue.drawTwo) {
          final victimIndex = (state.currentTurnIndex + step + count) % count;
          final victimId = state.playerIds[victimIndex];
          final victimHand = List<UnoCard>.from(newHands[victimId]!);

          for (int i = 0; i < 2; i++) {
            if (newDrawPile.isNotEmpty) {
              victimHand.add(newDrawPile.removeLast());
            }
          }
          newHands[victimId] = victimHand;
          nextTurn = (state.currentTurnIndex + (step * 2) + count) % count;
        } else if (card.value == UnoValue.wildDrawFour) {
          final victimIndex = (state.currentTurnIndex + step + count) % count;
          final victimId = state.playerIds[victimIndex];
          final victimHand = List<UnoCard>.from(newHands[victimId]!);

          for (int i = 0; i < 4; i++) {
            if (newDrawPile.isNotEmpty) {
              victimHand.add(newDrawPile.removeLast());
            }
          }
          newHands[victimId] = victimHand;
          nextTurn = (state.currentTurnIndex + (step * 2) + count) % count;
        } else {
          nextTurn = (state.currentTurnIndex + step + count) % count;
        }

        return state.copyWith(
          version: state.version + 1,
          hands: newHands,
          discardPile: newDiscard,
          drawPile: newDrawPile,
          currentTurnIndex: nextTurn,
          isClockwise: nextClockwise,
          activeColor: card.isWild ? chosenColor : card.color,
          hasShoutedUno: false,
        );

      default:
        return state;
    }
  }

  @override
  String? getCurrentTurnPlayerId(UnoState state) {
    if (state.winnerId != null) return null;
    return state.playerIds[state.currentTurnIndex];
  }

  @override
  bool isFinished(UnoState state) => state.winnerId != null;

  @override
  Map<String, dynamic> getResult(UnoState state) => {
    'winnerId': state.winnerId,
  };

  @override
  String serialize(UnoState state) => state.toJson();

  @override
  UnoState deserialize(String raw) => UnoState.fromJson(raw);
}
