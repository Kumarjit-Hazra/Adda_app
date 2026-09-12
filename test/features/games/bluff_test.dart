import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/bluff/bluff_engine.dart';
import 'package:adda/features/games/bluff/bluff_models.dart';

void main() {
  group('BluffEngine Unit Tests', () {
    late BluffEngine engine;
    final players = ['p0', 'p1', 'p2'];

    setUp(() {
      engine = BluffEngine();
    });

    test('initial state deals cards equally and starts with Aces', () {
      final state = engine.createInitialState(players);
      expect(state.playerIds.length, 3);
      expect(state.currentRankRequirement, BluffRank.ace);
      expect(state.centerPile.isEmpty, isTrue);
      expect(state.lastClaim, isNull);
    });

    test(
      'playing cards face-down establishes last claim and advances rank requirement',
      () {
        final card1 = const BluffCard(BluffRank.ace, 0);
        final card2 = const BluffCard(BluffRank.king, 1); // actual bluff
        final card3 = const BluffCard(BluffRank.five, 2);

        final state = BluffState(
          version: 1,
          playerIds: players,
          hands: {
            'p0': [card1, card2, card3],
            'p1': [],
            'p2': [],
          },
          centerPile: [],
          currentTurnIndex: 0,
          currentRankRequirement: BluffRank.ace,
        );

        final playAction = PlayerAction(
          actionId: 'b1',
          playerId: 'p0',
          activityId: 'bluff',
          type: 'play_cards',
          payload: {
            'cards': [card1.toMap(), card2.toMap()],
          },
          clientSequence: 1,
        );

        expect(engine.validateAction(state, playAction), isTrue);
        final nextState = engine.applyAction(state, playAction);

        expect(nextState.centerPile.length, 2);
        expect(nextState.lastClaim, isNotNull);
        expect(nextState.lastClaim!.declaredRank, BluffRank.ace);
        expect(nextState.lastClaim!.wasTruth, isFalse); // card2 was King!
        expect(nextState.currentRankRequirement, BluffRank.two);
      },
    );

    test('challenging a caught bluff forces claimant to pick up pile', () {
      final card1 = const BluffCard(BluffRank.king, 0); // bluff on Aces

      final state = BluffState(
        version: 2,
        playerIds: players,
        hands: {
          'p0': [],
          'p1': [const BluffCard(BluffRank.five, 0)],
          'p2': [],
        },
        centerPile: [card1],
        lastClaim: BluffClaim(
          claimantId: 'p0',
          declaredRank: BluffRank.ace,
          actualCards: [card1],
        ),
        currentTurnIndex: 1,
        currentRankRequirement: BluffRank.two,
      );

      final challengeAction = PlayerAction(
        actionId: 'b2',
        playerId: 'p1',
        activityId: 'bluff',
        type: 'challenge',
        payload: {},
        clientSequence: 2,
      );

      expect(engine.validateAction(state, challengeAction), isTrue);
      final resolved = engine.applyAction(state, challengeAction);

      expect(resolved.centerPile.isEmpty, isTrue);
      expect(
        resolved.hands['p0']!.contains(card1),
        isTrue,
      ); // p0 caught and penalized
    });
  });
}
