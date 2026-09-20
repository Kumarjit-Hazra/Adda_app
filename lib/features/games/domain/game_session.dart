import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import '../../auth/domain/models/user_profile.dart';

/// Represents the mode of a game session.
enum GameSessionMode {
  /// Solo play against bots (no networking, no WebRTC)
  solo,

  /// Local pass-and-play on a single device
  local,

  /// Multiplayer over network (requires RoomSession for social context)
  multiplayer,
}

/// Represents the current status of a game session.
enum GameSessionStatus {
  /// Session is being initialized
  initializing,

  /// Waiting for players to join (multiplayer)
  waitingForPlayers,

  /// Game is actively being played
  playing,

  /// Game has finished with a result
  finished,

  /// Session was cancelled/abandoned
  cancelled,
}

/// Result of a completed game session.
class GameResult {
  final Map<String, dynamic> engineResult;
  final Map<String, int> scores;
  final List<String> winnerIds;
  final Duration duration;
  final DateTime completedAt;

  const GameResult({
    required this.engineResult,
    required this.scores,
    required this.winnerIds,
    required this.duration,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'engineResult': engineResult,
      'scores': scores,
      'winnerIds': winnerIds,
      'durationMs': duration.inMilliseconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      engineResult: Map<String, dynamic>.from(map['engineResult'] as Map),
      scores: Map<String, int>.from(map['scores'] as Map),
      winnerIds: List<String>.from(map['winnerIds'] as List),
      duration: Duration(milliseconds: map['durationMs'] as int),
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }
}

/// A domain object representing an independent game session.
/// Does NOT depend on RoomSession, WebRTC, or chat.
class GameSession {
  final String sessionId;
  final String gameId;
  final String activityId;
  final List<GamePlayer> players;
  final dynamic state;
  final GameSessionStatus status;
  final GameSessionMode mode;
  final String? hostId;
  final GameResult? result;
  final List<PlayerAction> actionHistory;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int version;

  const GameSession({
    required this.sessionId,
    required this.gameId,
    required this.activityId,
    required this.players,
    required this.state,
    required this.status,
    required this.mode,
    this.hostId,
    this.result,
    this.actionHistory = const [],
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.version,
  });

  /// Creates a new solo game session.
  factory GameSession.createSolo({
    required String gameId,
    required String activityId,
    required ActivityEngine engine,
    required List<GamePlayer> players,
    required UserProfile localUser,
  }) {
    final sessionId = 'solo_${gameId}_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now();
    final playerIds = players.map((p) => p.id).toList();
    final initialState = engine.createInitialState(playerIds);

    return GameSession(
      sessionId: sessionId,
      gameId: gameId,
      activityId: activityId,
      players: players,
      state: initialState,
      status: GameSessionStatus.playing,
      mode: GameSessionMode.solo,
      hostId: localUser.id,
      createdAt: now,
      startedAt: now,
      version: 1,
    );
  }

  /// Creates a new local (pass-and-play) session.
  factory GameSession.createLocal({
    required String gameId,
    required String activityId,
    required ActivityEngine engine,
    required List<GamePlayer> players,
  }) {
    final sessionId = 'local_${gameId}_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now();
    final playerIds = players.map((p) => p.id).toList();
    final initialState = engine.createInitialState(playerIds);

    return GameSession(
      sessionId: sessionId,
      gameId: gameId,
      activityId: activityId,
      players: players,
      state: initialState,
      status: GameSessionStatus.playing,
      mode: GameSessionMode.local,
      hostId: players.first.id,
      createdAt: now,
      startedAt: now,
      version: 1,
    );
  }

  /// Creates a new multiplayer session (to be connected to RoomSession later).
  factory GameSession.createMultiplayer({
    required String gameId,
    required String activityId,
    required ActivityEngine engine,
    required List<GamePlayer> players,
    required String hostId,
  }) {
    final sessionId = 'mp_${gameId}_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now();
    final playerIds = players.map((p) => p.id).toList();
    final initialState = engine.createInitialState(playerIds);

    return GameSession(
      sessionId: sessionId,
      gameId: gameId,
      activityId: activityId,
      players: players,
      state: initialState,
      status: GameSessionStatus.waitingForPlayers,
      mode: GameSessionMode.multiplayer,
      hostId: hostId,
      createdAt: now,
      version: 1,
    );
  }

  /// Returns the local player (for solo/local modes).
  GamePlayer? get localPlayer {
    // In solo mode, the first human player is the local player
    try {
      return players.firstWhere((p) => p.isHuman);
    } catch (_) {
      return players.isNotEmpty ? players.first : null;
    }
  }

  /// Returns true if the session is active (playing or waiting).
  bool get isActive =>
      status == GameSessionStatus.playing ||
      status == GameSessionStatus.waitingForPlayers;

  /// Returns true if the game has finished.
  bool get isFinished => status == GameSessionStatus.finished;

  GameSession copyWith({
    String? sessionId,
    String? gameId,
    String? activityId,
    List<GamePlayer>? players,
    dynamic state,
    GameSessionStatus? status,
    GameSessionMode? mode,
    String? hostId,
    GameResult? result,
    List<PlayerAction>? actionHistory,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? version,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      gameId: gameId ?? this.gameId,
      activityId: activityId ?? this.activityId,
      players: players ?? this.players,
      state: state ?? this.state,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      hostId: hostId ?? this.hostId,
      result: result ?? this.result,
      actionHistory: actionHistory ?? this.actionHistory,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'gameId': gameId,
      'activityId': activityId,
      'players': players.map((p) => p.toMap()).toList(),
      'status': status.name,
      'mode': mode.name,
      'hostId': hostId,
      'result': result?.toMap(),
      'actionHistory': actionHistory.map((a) => a.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'version': version,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      sessionId: map['sessionId'] as String,
      gameId: map['gameId'] as String,
      activityId: map['activityId'] as String,
      players: (map['players'] as List)
          .map((p) => GamePlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      state: null, // State deserialization is engine-specific
      status: GameSessionStatus.values.firstWhere(
        (s) => s.name == map['status'],
      ),
      mode: GameSessionMode.values.firstWhere((m) => m.name == map['mode']),
      hostId: map['hostId'] as String?,
      result: map['result'] != null
          ? GameResult.fromMap(map['result'] as Map<String, dynamic>)
          : null,
      actionHistory: (map['actionHistory'] as List)
          .map((a) => PlayerAction.fromMap(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'] as String)
          : null,
      finishedAt: map['finishedAt'] != null
          ? DateTime.parse(map['finishedAt'] as String)
          : null,
      version: map['version'] as int,
    );
  }
}

/// A player in a game session.
class GamePlayer {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isHuman;
  final bool isHost;
  final int teamIndex; // For team-based games

  const GamePlayer({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isHuman,
    this.isHost = false,
    this.teamIndex = 0,
  });

  factory GamePlayer.human({
    required String id,
    required String name,
    String? avatarUrl,
    bool isHost = false,
    int teamIndex = 0,
  }) {
    return GamePlayer(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isHuman: true,
      isHost: isHost,
      teamIndex: teamIndex,
    );
  }

  factory GamePlayer.bot({
    required String id,
    required String name,
    String? avatarUrl,
    int teamIndex = 0,
  }) {
    return GamePlayer(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isHuman: false,
      teamIndex: teamIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isHuman': isHuman,
      'isHost': isHost,
      'teamIndex': teamIndex,
    };
  }

  factory GamePlayer.fromMap(Map<String, dynamic> map) {
    return GamePlayer(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      isHuman: map['isHuman'] as bool,
      isHost: map['isHost'] as bool? ?? false,
      teamIndex: map['teamIndex'] as int? ?? 0,
    );
  }
}

/// Serialization bundle for a game session (session metadata + engine state).
class GameSessionBundle {
  final GameSession session;
  final String serializedEngineState;

  const GameSessionBundle({
    required this.session,
    required this.serializedEngineState,
  });

  Map<String, dynamic> toMap() {
    return {'session': session.toMap(), 'engineState': serializedEngineState};
  }

  String toJson() => json.encode(toMap());
}
