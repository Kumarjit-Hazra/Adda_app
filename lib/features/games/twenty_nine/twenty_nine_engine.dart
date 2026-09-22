import 'dart:math';
import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'twenty_nine_models.dart';

class TwentyNineEngine implements ActivityEngine<TwentyNineState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'twenty_nine',
    title: '29 (Twenty-Nine)',
    description:
        'Classic South Asian trick-taking card game played by 4 players in fixed partnerships.',
    category: ActivityCategory.cards,
    minPlayers: 4,
    maxPlayers: 4,
    estimatedDuration: Duration(minutes: 15),
    rules: '''
1. 32-card deck (J: 3pts, 9: 2pts, A: 1pt, 10: 1pt, K/Q/8/7: 0pts). Total 28 card points + 1 last trick bonus.
2. Players bid from 16 to 28. The highest bidder chooses the hidden Trump suit.
3. Players must follow the lead suit if they hold it. If void, they can reveal Trump and play a Trump card.
4. Highest trump card wins trick; if no trump, highest card of lead suit wins.
5. If the bidding team gets equal to or greater than their bid, they win the set!
''',
  );

  List<PlayingCard> _generate32Deck() {
    final deck = <PlayingCard>[];
    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        deck.add(PlayingCard(suit, rank));
      }
    }
    return deck;
  }

  @override
  TwentyNineState createInitialState(List<String> playerIds) {
    // 4 players required, fallback to simulated IDs if less provided
    final actualPlayers = List<String>.from(playerIds);
    while (actualPlayers.length < 4) {
      actualPlayers.add('bot_${actualPlayers.length + 1}');
    }

    final deck = _generate32Deck()..shuffle(Random(42));
    final hands = <String, List<PlayingCard>>{};

    for (int i = 0; i < 4; i++) {
      hands[actualPlayers[i]] = deck.sublist(i * 8, (i + 1) * 8);
    }

    return TwentyNineState(
      version: 1,
      playerIds: actualPlayers,
      hands: hands,
      phase: TwentyNinePhase.bidding,
      currentTurnIndex: 0,
      highestBid: 16,
      highestBidderId: actualPlayers[0],
      trumpSuit: null,
      isTrumpRevealed: false,
      currentTrick: [],
      completedTricks: [],
      teamTrickPoints: {0: 0, 1: 0},
      winnerTeam: null,
    );
  }

  @override
  bool validateAction(TwentyNineState state, PlayerAction action) {
    if (state.phase == TwentyNinePhase.finished) return false;
    final currentExpectedPlayer = state.playerIds[state.currentTurnIndex];

    switch (action.type) {
      case 'bid':
        if (state.phase != TwentyNinePhase.bidding) return false;
        if (action.playerId != currentExpectedPlayer) return false;
        final bid = action.payload['bid'] as int? ?? 0;
        final isPass = action.payload['pass'] as bool? ?? false;
        if (isPass) return true;
        return bid > state.highestBid && bid <= 29;

      case 'set_trump':
        if (state.phase != TwentyNinePhase.bidding) return false;
        if (action.playerId != state.highestBidderId) return false;
        final suitName = action.payload['suit'] as String?;
        return suitName != null &&
            CardSuit.values.any((s) => s.name == suitName);

      case 'reveal_trump':
        if (state.phase != TwentyNinePhase.playing) return false;
        return !state.isTrumpRevealed;

      case 'play_card':
        if (state.phase != TwentyNinePhase.playing) return false;
        if (action.playerId != currentExpectedPlayer) return false;
        final card = PlayingCard.fromMap(
          action.payload['card'] as Map<String, dynamic>,
        );
        final hand = state.hands[action.playerId] ?? [];
        if (!hand.contains(card)) return false;

        // If lead suit is established, player must follow suit if they have it
        if (state.currentTrick.isNotEmpty) {
          final leadSuit = state.currentTrick.first.card.suit;
          final hasLeadSuit = hand.any((c) => c.suit == leadSuit);
          if (hasLeadSuit && card.suit != leadSuit) {
            return false;
          }
        }
        return true;

      default:
        return false;
    }
  }

  @override
  TwentyNineState applyAction(TwentyNineState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;

    switch (action.type) {
      case 'bid':
        final isPass = action.payload['pass'] as bool? ?? false;
        final bid = action.payload['bid'] as int? ?? 0;

        var nextBid = state.highestBid;
        var nextBidder = state.highestBidderId;

        if (!isPass && bid > state.highestBid) {
          nextBid = bid;
          nextBidder = action.playerId;
        }

        final nextTurn = (state.currentTurnIndex + 1) % 4;

        // Once everyone has had a chance to bid, prompt bidder to set trump
        final isBiddingDone =
            nextTurn == 0 ||
            (isPass && nextTurn == 1 && state.highestBidderId != null);

        return state.copyWith(
          version: state.version + 1,
          highestBid: nextBid,
          highestBidderId: nextBidder,
          currentTurnIndex: nextTurn,
          trumpSuit: isBiddingDone ? CardSuit.hearts : state.trumpSuit,
          phase: isBiddingDone
              ? TwentyNinePhase.playing
              : TwentyNinePhase.bidding,
        );

      case 'set_trump':
        final suit = CardSuit.values.firstWhere(
          (s) => s.name == action.payload['suit'],
        );
        return state.copyWith(
          version: state.version + 1,
          trumpSuit: suit,
          phase: TwentyNinePhase.playing,
          currentTurnIndex: 0,
        );

      case 'reveal_trump':
        return state.copyWith(
          version: state.version + 1,
          isTrumpRevealed: true,
        );

      case 'play_card':
        final card = PlayingCard.fromMap(
          action.payload['card'] as Map<String, dynamic>,
        );
        final updatedHand = List<PlayingCard>.from(
          state.hands[action.playerId]!,
        )..remove(card);
        final newHands = Map<String, List<PlayingCard>>.from(state.hands);
        newHands[action.playerId] = updatedHand;

        final newTrick = List<PlayedTrickCard>.from(state.currentTrick)
          ..add(PlayedTrickCard(playerId: action.playerId, card: card));

        // If trick is full (4 cards played)
        if (newTrick.length == 4) {
          final winner = _evaluateTrickWinner(
            newTrick,
            state.trumpSuit,
            state.isTrumpRevealed,
          );
          final winnerIndex = state.playerIds.indexOf(winner.playerId);
          final winnerTeam = winnerIndex % 2; // Team 0 or Team 1

          final trickPoints = newTrick.fold(
            0,
            (sum, item) => sum + item.card.points,
          );
          final updatedTeamPoints = Map<int, int>.from(state.teamTrickPoints);
          updatedTeamPoints[winnerTeam] =
              (updatedTeamPoints[winnerTeam] ?? 0) + trickPoints;

          final newCompleted = List<List<PlayedTrickCard>>.from(
            state.completedTricks,
          )..add(newTrick);

          // If all 8 tricks finished
          if (newCompleted.length == 8) {
            final bidderIndex = state.playerIds.indexOf(
              state.highestBidderId ?? state.playerIds[0],
            );
            final bidderTeam = bidderIndex % 2;
            final bidderPoints = updatedTeamPoints[bidderTeam] ?? 0;

            final won = bidderPoints >= state.highestBid;
            final winningTeam = won ? bidderTeam : (1 - bidderTeam);

            return state.copyWith(
              version: state.version + 1,
              hands: newHands,
              currentTrick: [],
              completedTricks: newCompleted,
              teamTrickPoints: updatedTeamPoints,
              phase: TwentyNinePhase.finished,
              winnerTeam: winningTeam,
            );
          }

          return state.copyWith(
            version: state.version + 1,
            hands: newHands,
            currentTrick: [],
            completedTricks: newCompleted,
            teamTrickPoints: updatedTeamPoints,
            currentTurnIndex: winnerIndex,
          );
        }

        // Continue trick to next player
        return state.copyWith(
          version: state.version + 1,
          hands: newHands,
          currentTrick: newTrick,
          currentTurnIndex: (state.currentTurnIndex + 1) % 4,
        );

      default:
        return state;
    }
  }

  PlayedTrickCard _evaluateTrickWinner(
    List<PlayedTrickCard> trick,
    CardSuit? trump,
    bool isTrumpRevealed,
  ) {
    final leadSuit = trick.first.card.suit;
    PlayedTrickCard best = trick.first;

    for (int i = 1; i < trick.length; i++) {
      final current = trick[i];
      // If trump is active
      if (isTrumpRevealed && trump != null) {
        if (current.card.suit == trump && best.card.suit != trump) {
          best = current;
        } else if (current.card.suit == trump && best.card.suit == trump) {
          if (current.card.power > best.card.power) {
            best = current;
          }
        } else if (best.card.suit != trump && current.card.suit == leadSuit) {
          if (current.card.power > best.card.power) {
            best = current;
          }
        }
      } else {
        if (current.card.suit == leadSuit &&
            current.card.power > best.card.power) {
          best = current;
        }
      }
    }
    return best;
  }

  @override
  String? getCurrentTurnPlayerId(TwentyNineState state) {
    if (state.phase == TwentyNinePhase.finished) return null;
    return state.playerIds[state.currentTurnIndex];
  }

  @override
  bool isFinished(TwentyNineState state) =>
      state.phase == TwentyNinePhase.finished;

  @override
  Map<String, dynamic> getResult(TwentyNineState state) {
    return {
      'winnerTeam': state.winnerTeam,
      'bid': state.highestBid,
      'bidderId': state.highestBidderId,
      'team0Points': state.teamTrickPoints[0],
      'team1Points': state.teamTrickPoints[1],
    };
  }

  @override
  String serialize(TwentyNineState state) => state.toJson();

  @override
  TwentyNineState deserialize(String raw) => TwentyNineState.fromJson(raw);
}
