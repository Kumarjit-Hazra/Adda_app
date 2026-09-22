import 'package:flame/game.dart';

/// Abstract base class for all Flame games within ADDA.
/// Receives immutable game state from the Flutter layer.
abstract class AddaFlameGame<T> extends FlameGame {
  T? _state;
  T? get gameState => _state;

  /// Updates the game state and allows the game components to react.
  void updateState(T state) {
    _state = state;
    onStateUpdate(state);
  }

  /// Override this to react to state updates in components.
  void onStateUpdate(T state);
}
