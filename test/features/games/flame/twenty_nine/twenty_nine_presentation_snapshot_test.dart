import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/games/flame/twenty_nine/models/twenty_nine_presentation_snapshot.dart';
import 'package:adda/features/games/twenty_nine/twenty_nine_models.dart';

void main() {
  group('TwentyNinePresentationSnapshot', () {
    final p1 = PlayerPresentationData(id: 'p1', name: 'Player 1', isTurn: true);
    final p2 = PlayerPresentationData(id: 'p2', name: 'Player 2', isTurn: false);
    final p3 = PlayerPresentationData(id: 'p3', name: 'Player 3', isTurn: false);
    final p4 = PlayerPresentationData(id: 'p4', name: 'Player 4', isTurn: false);

    test('equality checks work correctly', () {
      final snapshotA = TwentyNinePresentationSnapshot(
        phase: TwentyNinePhase.playing,
        version: 1,
        myHand: [PlayingCard(CardSuit.hearts, CardRank.jack)],
        currentTrick: [],
        myData: p1,
        leftData: p2,
        topData: p3,
        rightData: p4,
      );

      final snapshotB = TwentyNinePresentationSnapshot(
        phase: TwentyNinePhase.playing,
        version: 1,
        myHand: [PlayingCard(CardSuit.hearts, CardRank.jack)],
        currentTrick: [],
        myData: p1,
        leftData: p2,
        topData: p3,
        rightData: p4,
      );

      expect(snapshotA, equals(snapshotB));
      expect(snapshotA.hashCode, equals(snapshotB.hashCode));
    });

    test('inequality when version changes', () {
      final snapshotA = TwentyNinePresentationSnapshot(
        phase: TwentyNinePhase.playing,
        version: 1,
        myHand: [],
        currentTrick: [],
        myData: p1,
        leftData: p2,
        topData: p3,
        rightData: p4,
      );

      final snapshotB = TwentyNinePresentationSnapshot(
        phase: TwentyNinePhase.playing,
        version: 2,
        myHand: [],
        currentTrick: [],
        myData: p1,
        leftData: p2,
        topData: p3,
        rightData: p4,
      );

      expect(snapshotA, isNot(equals(snapshotB)));
    });
    
    test('inequality when hand changes (different identity)', () {
      final snapshotA = TwentyNinePresentationSnapshot(
        phase: TwentyNinePhase.playing,
        version: 1,
        myHand: [PlayingCard(CardSuit.hearts, CardRank.jack)],
        currentTrick: [],
        myData: p1,
        leftData: p2,
        topData: p3,
        rightData: p4,
      );

      final snapshotB = TwentyNinePresentationSnapshot(
        phase: TwentyNinePhase.playing,
        version: 1,
        myHand: [PlayingCard(CardSuit.hearts, CardRank.nine)], // Changed
        currentTrick: [],
        myData: p1,
        leftData: p2,
        topData: p3,
        rightData: p4,
      );

      expect(snapshotA, isNot(equals(snapshotB)));
    });
  });
}
