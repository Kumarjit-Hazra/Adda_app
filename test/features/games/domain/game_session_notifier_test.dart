import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/games/domain/game_session.dart';
import 'package:adda/features/games/domain/game_session_notifier.dart';
import 'package:adda/features/games/domain/game_registry.dart';
import 'package:adda/features/auth/domain/models/user_profile.dart';
import 'package:adda/features/activities/engine/activity_engine.dart';
import 'package:adda/features/activities/engine/activity_definition.dart';
import 'package:adda/features/activities/engine/player_action.dart';

class MockEngine implements ActivityEngine<String> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'mock',
    title: 'Mock',
    description: 'Mock Engine',
    category: ActivityCategory.cards,
    minPlayers: 2,
    maxPlayers: 4,
    estimatedDuration: Duration(minutes: 5),
    rules: 'Mock rules',
  );
  @override
  String createInitialState(List<String> playerIds) => 'state_1';

  @override
  bool validateAction(String state, PlayerAction action) =>
      action.type == 'valid';

  @override
  String applyAction(String state, PlayerAction action) => 'state_2';

  @override
  bool isFinished(String state) => state == 'state_2';

  @override
  Map<String, dynamic> getResult(String state) => {'winnerId': 'u1'};

  @override
  String serialize(String state) => state;

  @override
  String deserialize(String raw) => raw;
}

void main() {
  group('GameSessionNotifier Tests', () {
    final engine = MockEngine();
    final definition = GameDefinition(
      id: 'mock_game',
      activityId: 'mock',
      title: 'Mock',
      category: ActivityCategory.cards,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedDuration: const Duration(minutes: 5),
    );
    final localUser = UserProfile(
      id: 'u1',
      name: 'Test',
      createdAt: DateTime.now(),
    );
    final players = [
      GamePlayer.human(id: 'u1', name: 'Player 1', isHost: true),
      GamePlayer.bot(id: 'b1', name: 'Bot 1'),
    ];

    test('createSoloSession initializes and schedules bot', () async {
      final notifier = GameSessionNotifier(
        engine,
        definition,
        mode: GameSessionMode.solo,
      );

      await notifier.createSoloSession(players: players, localUser: localUser);

      final session = notifier.state;
      expect(session, isNotNull);
      expect(session!.mode, GameSessionMode.solo);
      expect(session.state, 'state_1');
      expect(session.status, GameSessionStatus.playing);

      notifier.dispose();
    });

    test(
      'dispatchAction processes valid action and transitions state',
      () async {
        final notifier = GameSessionNotifier(
          engine,
          definition,
          mode: GameSessionMode.solo,
        );
        await notifier.createSoloSession(
          players: players,
          localUser: localUser,
        );

        final action = PlayerAction(
          actionId: 'a1',
          playerId: 'u1',
          activityId: 'mock',
          type: 'valid',
          payload: {},
          clientSequence: 1,
        );

        final success = notifier.dispatchAction(action);

        expect(success, isTrue);

        final session = notifier.state!;
        expect(session.state, 'state_2');
        expect(session.version, 2);
        expect(session.actionHistory.length, 1);

        // Since it's finished
        expect(session.status, GameSessionStatus.finished);
        expect(session.result, isNotNull);
        expect(session.result!.winnerIds, contains('u1'));

        notifier.dispose();
      },
    );

    test('dispatchAction rejects invalid action', () async {
      final notifier = GameSessionNotifier(
        engine,
        definition,
        mode: GameSessionMode.solo,
      );
      await notifier.createSoloSession(players: players, localUser: localUser);

      final action = PlayerAction(
        actionId: 'a2',
        playerId: 'u1',
        activityId: 'mock',
        type: 'invalid',
        payload: {},
        clientSequence: 1,
      );

      final success = notifier.dispatchAction(action);

      expect(success, isFalse);

      final session = notifier.state!;
      expect(session.state, 'state_1'); // Unchanged
      expect(session.version, 1);

      notifier.dispose();
    });

    test('rematch resets session correctly', () async {
      final notifier = GameSessionNotifier(
        engine,
        definition,
        mode: GameSessionMode.solo,
      );
      await notifier.createSoloSession(players: players, localUser: localUser);

      final action = PlayerAction(
        actionId: 'a1',
        playerId: 'u1',
        activityId: 'mock',
        type: 'valid',
        payload: {},
        clientSequence: 1,
      );
      notifier.dispatchAction(action);

      expect(notifier.state!.status, GameSessionStatus.finished);

      notifier.rematch();

      final session = notifier.state!;
      expect(session.status, GameSessionStatus.playing);
      expect(session.state, 'state_1');
      expect(session.version, 1);
      expect(session.actionHistory, isEmpty);

      notifier.dispose();
    });

    test('cancel session sets status to cancelled', () async {
      final notifier = GameSessionNotifier(
        engine,
        definition,
        mode: GameSessionMode.solo,
      );
      await notifier.createSoloSession(players: players, localUser: localUser);

      notifier.cancel();

      expect(notifier.state!.status, GameSessionStatus.cancelled);

      notifier.dispose();
    });
  });
}
