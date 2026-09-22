import 'dart:math';
import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'bluff_models.dart';

class BluffEngine implements ActivityEngine<BluffState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'bluff',
    title: 'Bluff Masters',
    description:
        'Original high-stakes deception card game. Play cards face down and test your friends’ poker faces.',
    category: ActivityCategory.party,
    minPlayers: 3,
    maxPlayers: 6,
    estimatedDuration: Duration(minutes: 12),
    rules: '''
1. Ranks progress sequentially: Aces, 2s, 3s, ... Kings, then loops back to Aces.
2. Play 1 to 4 cards face down, claiming they match the required rank.
3. Any player can shout "BLUFF!" to challenge your claim.
4. Caught bluffing? You pick up the entire penalty pile! Falsely accused? The challenger takes the pile!
5. First player to get rid of all their cards wins.
''',
  );

  List<BluffCard> _generateDeck() {
    final deck = <BluffCard>[];
    for (final rank in BluffRank.values) {
      for (int s = 0; s < 4; s++) {
        deck.add(BluffCard(rank, s));
      }
    }
    return deck;
  }

  @override
  BluffState createInitialState(List<String> playerIds) {
    final actualPlayers = List<String>.from(playerIds);
    while (actualPlayers.length < 3) {
      actualPlayers.add('bot_${actualPlayers.length + 1}');
    }

    final deck = _generateDeck()..shuffle(Random(88));
    final hands = <String, List<BluffCard>>{};

    final perPlayer = deck.length ~/ actualPlayers.length;
    for (int i = 0; i < actualPlayers.length; i++) {
      hands[actualPlayers[i]] = deck.sublist(
        i * perPlayer,
        (i + 1) * perPlayer,
      );
    }

    return BluffState(
      version: 1,
      playerIds: actualPlayers,
      hands: hands,
      centerPile: [],
      lastClaim: null,
      currentTurnIndex: 0,
      currentRankRequirement: BluffRank.ace,
      challengeResultBanner: null,
      winnerId: null,
    );
  }

  @override
  bool validateAction(BluffState state, PlayerAction action) {
    if (state.winnerId != null) return false;
    final currentTurnId = state.playerIds[state.currentTurnIndex];

    switch (action.type) {
      case 'play_cards':
        if (action.playerId != currentTurnId) return false;
        final rawCards = action.payload['cards'] as List<dynamic>? ?? [];
        if (rawCards.isEmpty || rawCards.length > 4) return false;
        final played = rawCards
            .map((c) => BluffCard.fromMap(c as Map<String, dynamic>))
            .toList();
        final hand = state.hands[action.playerId] ?? [];
        return played.every((c) => hand.contains(c));

      case 'challenge':
        if (state.lastClaim == null) return false;
        if (action.playerId == state.lastClaim!.claimantId) return false;
        return true;

      case 'pass_challenge':
        return state.lastClaim != null;

      default:
        return false;
    }
  }

  @override
  BluffState applyAction(BluffState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;
    final count = state.playerIds.length;

    switch (action.type) {
      case 'play_cards':
        final rawCards = action.payload['cards'] as List<dynamic>;
        final played = rawCards
            .map((c) => BluffCard.fromMap(c as Map<String, dynamic>))
            .toList();

        final updatedHand = List<BluffCard>.from(state.hands[action.playerId]!);
        for (final c in played) {
          updatedHand.remove(c);
        }
        final newHands = Map<String, List<BluffCard>>.from(state.hands);
        newHands[action.playerId] = updatedHand;

        final newCenter = List<BluffCard>.from(state.centerPile)
          ..addAll(played);
        final claim = BluffClaim(
          claimantId: action.playerId,
          declaredRank: state.currentRankRequirement,
          actualCards: played,
        );

        // Win check
        if (updatedHand.isEmpty) {
          return state.copyWith(
            version: state.version + 1,
            hands: newHands,
            centerPile: newCenter,
            lastClaim: claim,
            winnerId: action.playerId,
          );
        }

        // Advance to next rank requirement (Ace -> 2 -> 3 ... King -> Ace)
        final nextRankIndex =
            (state.currentRankRequirement.index + 1) % BluffRank.values.length;
        final nextRank = BluffRank.values[nextRankIndex];
        final nextTurn = (state.currentTurnIndex + 1) % count;

        return state.copyWith(
          version: state.version + 1,
          hands: newHands,
          centerPile: newCenter,
          lastClaim: claim,
          currentTurnIndex: nextTurn,
          currentRankRequirement: nextRank,
          challengeResultBanner: null,
        );

      case 'challenge':
        final claim = state.lastClaim!;
        final wasTruthful = claim.wasTruth;
        final penaltyPile = List<BluffCard>.from(state.centerPile);
        final newHands = Map<String, List<BluffCard>>.from(state.hands);

        String banner;
        if (wasTruthful) {
          // Challenger loses and picks up the pile
          newHands[action.playerId] = [
            ...newHands[action.playerId]!,
            ...penaltyPile,
          ];
          banner =
              '${action.playerId} called bluff but ${claim.claimantId} told the truth! Challenger took the pile.';
        } else {
          // Claimant was bluffing and picks up the pile
          newHands[claim.claimantId] = [
            ...newHands[claim.claimantId]!,
            ...penaltyPile,
          ];
          banner =
              'CAUGHT BLUFFING! ${claim.claimantId} had to pick up the pile!';
        }

        return state.copyWith(
          version: state.version + 1,
          hands: newHands,
          centerPile: [],
          lastClaim: null,
          challengeResultBanner: banner,
        );

      case 'pass_challenge':
        return state.copyWith(
          version: state.version + 1,
          lastClaim: null,
          challengeResultBanner: null,
        );

      default:
        return state;
    }
  }

  @override
  String? getCurrentTurnPlayerId(BluffState state) => null;

  @override
  bool isFinished(BluffState state) => state.winnerId != null;

  @override
  Map<String, dynamic> getResult(BluffState state) => {
    'winnerId': state.winnerId,
  };

  @override
  String serialize(BluffState state) => state.toJson();

  @override
  BluffState deserialize(String raw) => BluffState.fromJson(raw);
}
