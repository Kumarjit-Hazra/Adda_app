import 'activity_definition.dart';
import 'player_action.dart';

/// Abstract contract that all ADDA games and activities implement.
/// Ensures deterministic, testable, and recoverable multiplayer state progression.
abstract class ActivityEngine<TState> {
  ActivityDefinition get definition;

  TState createInitialState(List<String> playerIds);

  bool validateAction(TState state, PlayerAction action);

  TState applyAction(TState state, PlayerAction action);

  bool isFinished(TState state);

  Map<String, dynamic> getResult(TState state);

  String serialize(TState state);

  TState deserialize(String raw);
}
