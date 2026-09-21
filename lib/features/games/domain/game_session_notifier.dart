import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import '../../auth/domain/models/user_profile.dart';
import 'game_session.dart';
import 'game_registry.dart';

/// Controls an independent game session.
/// Does NOT own widgets, navigation, WebRTC, chat, or RoomSession.
class GameSessionNotifier extends StateNotifier<GameSession?> {
  final ActivityEngine _engine;
  final GameDefinition _definition;
  final GameSessionMode _mode;
  Timer? _botTimer;

  GameSessionNotifier(
    this._engine,
    this._definition, {
    required GameSessionMode mode,
  }) : _mode = mode,
       super(null);

  /// Creates a new solo game session.
  Future<void> createSoloSession({
    required List<GamePlayer> players,
    required UserProfile localUser,
  }) async {
    final session = GameSession.createSolo(
      gameId: _definition.id,
      activityId: _definition.activityId,
      engine: _engine,
      players: players,
      localUser: localUser,
    );
    state = session;
    _scheduleBotTurnIfNeeded(session.state);
  }

  /// Creates a new local (pass-and-play) session.
  Future<void> createLocalSession({required List<GamePlayer> players}) async {
    final session = GameSession.createLocal(
      gameId: _definition.id,
      activityId: _definition.activityId,
      engine: _engine,
      players: players,
    );
    state = session;
  }

  /// Creates a new multiplayer session.
  Future<void> createMultiplayerSession({
    required List<GamePlayer> players,
    required String hostId,
  }) async {
    final session = GameSession.createMultiplayer(
      gameId: _definition.id,
      activityId: _definition.activityId,
      engine: _engine,
      players: players,
      hostId: hostId,
    );
    state = session;
  }

  /// Dispatches a player action to the engine.
  /// Returns true if action was valid and applied.
  bool dispatchAction(PlayerAction action) {
    final currentSession = state;
    if (currentSession == null) return false;
    if (!currentSession.isActive) return false;

    if (!_engine.validateAction(currentSession.state, action)) {
      return false;
    }

    final newState = _engine.applyAction(currentSession.state, action);
    final newHistory = [...currentSession.actionHistory, action];
    final newVersion = currentSession.version + 1;

    GameSessionStatus newStatus = currentSession.status;
    GameResult? result;
    DateTime? finishedAt;

    if (_engine.isFinished(newState)) {
      newStatus = GameSessionStatus.finished;
      final finished = DateTime.now();
      finishedAt = finished;
      final engineResult = _engine.getResult(newState);
      result = _buildGameResult(currentSession, engineResult, finished);
    }

    state = currentSession.copyWith(
      state: newState,
      status: newStatus,
      actionHistory: newHistory,
      version: newVersion,
      result: result,
      finishedAt: finishedAt,
    );

    // Trigger bot turn if in solo mode and it's a bot's turn
    if (_mode == GameSessionMode.solo &&
        newStatus == GameSessionStatus.playing) {
      _scheduleBotTurnIfNeeded(newState);
    }

    return true;
  }

  /// Schedules a bot turn if the current player is a bot.
  void _scheduleBotTurnIfNeeded(dynamic newState) {
    _botTimer?.cancel();

    final currentSession = state;
    if (currentSession == null ||
        currentSession.status != GameSessionStatus.playing) {
      return;
    }

    // Check if current player is a bot
    // We assume the engine exposes playerIds and currentTurnIndex.
    // However, it's safer to just check all bots if they have an action to perform.
    // If we have a specific current player turn mechanism, we extract the ID.
    // Since engines differ, we just let the bot check if it's its turn inside computeNextAction.

    _botTimer = Timer(const Duration(milliseconds: 600), () {
      _executeBotTurn();
    });
  }

  /// Executes a bot turn.
  void _executeBotTurn() {
    final currentSession = state;
    if (currentSession == null ||
        currentSession.status != GameSessionStatus.playing) {
      return;
    }

    // Find any bot that can take an action
    for (final player in currentSession.players) {
      if (!player.isHuman) {
        final bot = GameRegistry.createBot(currentSession.gameId, player.id);
        if (bot != null) {
          final action = bot.computeNextAction(currentSession.state);
          if (action != null) {
            // Dispatch the first valid bot action found
            dispatchAction(action);
            return; // Exit loop; dispatchAction will reschedule next turn
          }
        }
      }
    }
  }

  /// Resets the session for a rematch with the same players.
  void rematch() {
    final currentSession = state;
    if (currentSession == null) return;

    final playerIds = currentSession.players.map((p) => p.id).toList();
    final newState = _engine.createInitialState(playerIds);
    final now = DateTime.now();

    state = currentSession.copyWith(
      state: newState,
      status: GameSessionStatus.playing,
      actionHistory: [],
      version: 1,
      result: null,
      startedAt: now,
      finishedAt: null,
    );

    if (_mode == GameSessionMode.solo) {
      _scheduleBotTurnIfNeeded(newState);
    }
  }

  /// Cancels/abandons the current session.
  void cancel() {
    final currentSession = state;
    if (currentSession == null) return;

    _botTimer?.cancel();

    state = currentSession.copyWith(
      status: GameSessionStatus.cancelled,
      finishedAt: DateTime.now(),
    );
  }

  /// Serializes the session for persistence.
  GameSessionBundle serialize() {
    final currentSession = state;
    if (currentSession == null) {
      throw StateError('No active session to serialize');
    }
    return GameSessionBundle(
      session: currentSession,
      serializedEngineState: _engine.serialize(currentSession.state),
    );
  }

  /// Restores a session from serialized data.
  void restore(GameSessionBundle bundle) {
    final restoredState = _engine.deserialize(bundle.serializedEngineState);
    state = bundle.session.copyWith(state: restoredState);
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  GameResult _buildGameResult(
    GameSession session,
    Map<String, dynamic> engineResult,
    DateTime finishedAt,
  ) {
    // Build a standard GameResult from engine result
    final scores = <String, int>{};
    final winnerIds = <String>[];

    // Extract scores from engine result (engine-specific)
    if (engineResult.containsKey('team0Points') &&
        engineResult.containsKey('team1Points')) {
      // Team-based game (like 29)
      scores['team0'] = engineResult['team0Points'] as int;
      scores['team1'] = engineResult['team1Points'] as int;
      final winnerTeam = engineResult['winnerTeam'] as int?;
      if (winnerTeam != null) {
        for (final player in session.players) {
          if (player.teamIndex == winnerTeam) {
            winnerIds.add(player.id);
          }
        }
      }
    } else if (engineResult.containsKey('winnerId')) {
      // Single winner games
      final winnerId = engineResult['winnerId'] as String?;
      if (winnerId != null) {
        winnerIds.add(winnerId);
        scores[winnerId] = 1;
      }
    }

    return GameResult(
      engineResult: engineResult,
      scores: scores,
      winnerIds: winnerIds,
      duration: finishedAt.difference(session.startedAt ?? session.createdAt),
      completedAt: finishedAt,
    );
  }
}

/// StateNotifierProvider family for GameSessionNotifier.
/// Usage: ref.watch(gameSessionNotifierProvider('twenty_nine').notifier).
final gameSessionNotifierProvider =
    StateNotifierProvider.family<GameSessionNotifier, GameSession?, String>((
      ref,
      gameId,
    ) {
      final definition = GameRegistry.getDefinition(gameId);
      if (definition == null) {
        throw ArgumentError('Unknown game: $gameId');
      }
      final engine = GameRegistry.createEngine(gameId);
      return GameSessionNotifier(
        engine,
        definition,
        mode: GameSessionMode.solo,
      );
    });

/// Provider for the current game session state.
/// Usage: ref.watch(gameSessionProvider('twenty_nine')).
final gameSessionProvider = Provider.family<GameSession?, String>((
  ref,
  gameId,
) {
  final notifier = ref.watch(gameSessionNotifierProvider(gameId));
  return notifier;
});
