import 'package:flutter/material.dart';
import '../domain/game_session.dart';
import '../twenty_nine/presentation/twenty_nine_adapter.dart';

/// Interface for bridging generic GameSession states to game-specific UI and interpretation.
abstract class GamePresentationAdapter {
  /// Builds the game-specific board.
  Widget buildBoard();

  /// Gets a localized or custom result message based on the game's engine state.
  String getResultMessage(GameSession session, String localUserId);

  /// Determines if the local player won the game.
  bool isVictory(GameSession session, String localUserId);
}

/// Registry mapping game IDs to their specific presentation adapters.
class GamePresentationRegistry {
  static final Map<String, GamePresentationAdapter Function()> _adapters = {};

  static bool _initialized = false;

  /// Registers a presentation adapter for a specific game.
  static void register(
    String gameId,
    GamePresentationAdapter Function() adapterFactory,
  ) {
    _adapters[gameId] = adapterFactory;
  }

  /// Initializes the registry with default adapters.
  static void initialize() {
    if (_initialized) return;
    register('twenty_nine', () => TwentyNineAdapter());
    _initialized = true;
  }

  /// Gets the presentation adapter for a game. Returns null if unsupported.
  static GamePresentationAdapter? getAdapter(String gameId) {
    initialize();
    final factory = _adapters[gameId];
    return factory?.call();
  }
}
