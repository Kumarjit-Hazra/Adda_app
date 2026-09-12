import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/watch_together/watch_together_engine.dart';

void main() {
  group('WatchTogetherEngine Unit Tests', () {
    late WatchTogetherEngine engine;
    final players = ['host_1', 'listener_2'];

    setUp(() {
      engine = WatchTogetherEngine();
    });

    test('initializes with default playlist, playing state, and host', () {
      final state = engine.createInitialState(players);
      expect(state.hostId, 'host_1');
      expect(state.playlist.isNotEmpty, isTrue);
      expect(state.isPlaying, isTrue);
      expect(state.playbackPositionSec, 0);
    });

    test('play, pause, and seek update state synchronously', () {
      var state = engine.createInitialState(players);

      final pauseAction = PlayerAction(
        actionId: 'wt1',
        playerId: 'host_1',
        activityId: 'watch_together',
        type: 'pause',
        payload: {},
        clientSequence: 1,
      );

      state = engine.applyAction(state, pauseAction);
      expect(state.isPlaying, isFalse);

      final seekAction = PlayerAction(
        actionId: 'wt2',
        playerId: 'listener_2',
        activityId: 'watch_together',
        type: 'seek',
        payload: {'positionSec': 45},
        clientSequence: 2,
      );

      state = engine.applyAction(state, seekAction);
      expect(state.playbackPositionSec, 45);
    });
  });
}
