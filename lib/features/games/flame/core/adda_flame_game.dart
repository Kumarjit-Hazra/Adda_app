import 'package:flame/game.dart';
import '../../domain/game_session.dart';

/// Abstract base class for all Flame games within ADDA.
/// Receives immutable game state and session metadata from the Flutter layer.
abstract class AddaFlameGame<T> extends FlameGame {
  T? _state;
  T? get gameState => _state;

  GameSession? _session;
  GameSession? get gameSession => _session;

  /// Updates the game state and allows the game components to react.
  void updateState(GameSession session, T state) {
    _session = session;
    _state = state;
    onStateUpdate(session, state);
  }

  /// Override this to react to state updates in components.
  void onStateUpdate(GameSession session, T state);
}
