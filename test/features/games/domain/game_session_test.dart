import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/games/domain/game_session.dart';
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
  String createInitialState(List<String> playerIds) => 'init_state';

  @override
  bool validateAction(String state, PlayerAction action) => true;

  @override
  String applyAction(String state, PlayerAction action) => 'new_state';

  @override
  bool isFinished(String state) => state == 'finished';

  @override
  Map<String, dynamic> getResult(String state) => {'winnerId': 'p1'};

  @override
  String serialize(String state) => state;

  @override
  String deserialize(String raw) => raw;
}

void main() {
  group('GameSession Tests', () {
    final engine = MockEngine();
    final localUser = UserProfile(id: 'u1', name: 'Test', createdAt: DateTime.now());
    final players = [
      GamePlayer.human(id: 'u1', name: 'Player 1', isHost: true),
      GamePlayer.bot(id: 'b1', name: 'Bot 1'),
    ];

    test('createSolo initializes correctly', () {
      final session = GameSession.createSolo(
        gameId: 'mock_game',
        activityId: 'mock_activity',
        engine: engine,
        players: players,
        localUser: localUser,
      );

      expect(session.sessionId, startsWith('solo_mock_game_'));
      expect(session.gameId, 'mock_game');
      expect(session.activityId, 'mock_activity');
      expect(session.players.length, 2);
      expect(session.status, GameSessionStatus.playing);
      expect(session.mode, GameSessionMode.solo);
      expect(session.hostId, 'u1');
      expect(session.state, 'init_state');
      expect(session.version, 1);
      expect(session.isActive, true);
      expect(session.isFinished, false);
      expect(session.localPlayer?.id, 'u1');
    });

    test('createLocal initializes correctly', () {
      final session = GameSession.createLocal(
        gameId: 'mock_game',
        activityId: 'mock_activity',
        engine: engine,
        players: players,
      );

      expect(session.sessionId, startsWith('local_mock_game_'));
      expect(session.mode, GameSessionMode.local);
      expect(session.hostId, 'u1'); // players.first.id
    });

    test('createMultiplayer initializes correctly', () {
      final session = GameSession.createMultiplayer(
        gameId: 'mock_game',
        activityId: 'mock_activity',
        engine: engine,
        players: players,
        hostId: 'h1',
      );

      expect(session.sessionId, startsWith('mp_mock_game_'));
      expect(session.mode, GameSessionMode.multiplayer);
      expect(session.hostId, 'h1');
      expect(session.status, GameSessionStatus.waitingForPlayers);
    });

    test('serialization and restoration integrity', () {
      final session = GameSession.createSolo(
        gameId: 'mock_game',
        activityId: 'mock_activity',
        engine: engine,
        players: players,
        localUser: localUser,
      );

      final bundle = GameSessionBundle(
        session: session,
        serializedEngineState: engine.serialize(session.state),
      );

      final jsonStr = bundle.toJson();
      
      // Deserialize
      final decodedMap = jsonDecode(jsonStr);
      final decoded = GameSessionBundle(
        session: GameSession.fromMap(decodedMap['session']),
        serializedEngineState: decodedMap['engineState'],
      );
      
      final restoredSession = decoded.session.copyWith(
        state: engine.deserialize(decoded.serializedEngineState)
      );

      expect(restoredSession.sessionId, session.sessionId);
      expect(restoredSession.gameId, session.gameId);
      expect(restoredSession.players.first.id, session.players.first.id);
      expect(restoredSession.status, session.status);
      expect(restoredSession.mode, session.mode);
      expect(restoredSession.hostId, session.hostId);
      expect(restoredSession.version, session.version);
      expect(restoredSession.state, session.state);
    });
  });
}
