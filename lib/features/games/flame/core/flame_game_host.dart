import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game_session_notifier.dart';
import 'adda_flame_game.dart';

/// A Flutter widget that hosts a Flame game and synchronizes GameSession state.
class FlameGameHost<TState, TGame extends AddaFlameGame<TState>>
    extends ConsumerStatefulWidget {
  final String gameId;
  final TGame Function() gameFactory;

  const FlameGameHost({
    super.key,
    required this.gameId,
    required this.gameFactory,
  });

  @override
  ConsumerState<FlameGameHost> createState() =>
      _FlameGameHostState<TState, TGame>();
}

class _FlameGameHostState<TState, TGame extends AddaFlameGame<TState>>
    extends ConsumerState<FlameGameHost<TState, TGame>> {
  late final TGame _game;

  @override
  void initState() {
    super.initState();
    _game = widget.gameFactory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // In case the widget dependencies change, we might need to handle it.
  }

  @override
  void dispose() {
    // Flame automatically manages game disposal when GameWidget is unmounted.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider(widget.gameId));

    if (session != null && session.state is TState) {
      final state = session.state as TState;
      _game.updateState(state);
    }

    return GameWidget(
      game: _game,
      loadingBuilder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (context, error) => Center(
        child: Text(
          'Failed to load game environment: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
