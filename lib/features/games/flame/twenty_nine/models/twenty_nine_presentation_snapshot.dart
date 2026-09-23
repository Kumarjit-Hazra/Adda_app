import 'dart:collection';
import '../../../twenty_nine/twenty_nine_models.dart';

class PlayerPresentationData {
  final String id;
  final String name;
  final bool isTurn;

  const PlayerPresentationData({
    required this.id,
    required this.name,
    required this.isTurn,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerPresentationData &&
          other.id == id &&
          other.name == name &&
          other.isTurn == isTurn;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ isTurn.hashCode;
}

class TwentyNinePresentationSnapshot {
  final TwentyNinePhase phase;
  final UnmodifiableListView<PlayingCard> myHand;
  final UnmodifiableListView<PlayedTrickCard> currentTrick;
  final PlayerPresentationData myData;
  final PlayerPresentationData leftData;
  final PlayerPresentationData topData;
  final PlayerPresentationData rightData;
  final int version;

  TwentyNinePresentationSnapshot({
    required this.phase,
    required Iterable<PlayingCard> myHand,
    required Iterable<PlayedTrickCard> currentTrick,
    required this.myData,
    required this.leftData,
    required this.topData,
    required this.rightData,
    required this.version,
  }) : myHand = UnmodifiableListView(myHand),
       currentTrick = UnmodifiableListView(currentTrick);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwentyNinePresentationSnapshot &&
          other.version == version &&
          other.phase == phase &&
          _listEquals(other.myHand, myHand) &&
          _listEquals(other.currentTrick, currentTrick) &&
          other.myData == myData &&
          other.leftData == leftData &&
          other.topData == topData &&
          other.rightData == rightData;

  @override
  int get hashCode => version.hashCode;

  static bool _listEquals<T>(
    UnmodifiableListView<T> a,
    UnmodifiableListView<T> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
