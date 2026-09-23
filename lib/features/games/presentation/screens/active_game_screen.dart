import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../domain/game_session.dart';
import '../../domain/game_session_notifier.dart';
import '../../domain/game_registry.dart';
import '../game_presentation_registry.dart';
import '../widgets/game_overlay.dart';
import '../widgets/game_top_bar.dart';

class ActiveGameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const ActiveGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends ConsumerState<ActiveGameScreen> {
  bool _initializing = false;
  bool _initialized = false;

  void _triggerInitialization(UserProfile user) {
    if (_initializing || _initialized) return;
    // We cannot call setState here if we are inside build, but we can do it post-frame
    _initializing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession(user);
    });
  }

  Future<void> _initializeSession(UserProfile user) async {
    final definition = GameRegistry.getDefinition(widget.gameId);
    final adapter = GamePresentationRegistry.getAdapter(widget.gameId);

    if (definition == null || adapter == null || !definition.supportsSolo) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initialized = true;
        });
      }
      return;
    }

    final notifier = ref.read(
      gameSessionNotifierProvider(widget.gameId).notifier,
    );

    final factory = definition.soloPlayerFactory;
    List<GamePlayer> players;
    if (factory != null) {
      players = factory(user);
    } else {
      players = [
        GamePlayer.human(
          id: user.id,
          name: user.name,
          avatarUrl: user.avatarUrl,
          isHost: true,
        ),
        GamePlayer.bot(id: 'bot_1', name: 'Bot 🤖'),
      ];
    }

    await notifier.createSoloSession(players: players, localUser: user);

    if (mounted) {
      setState(() {
        _initializing = false;
        _initialized = true;
      });
    }
  }

  void _handleExit() {
    final session = ref.read(gameSessionProvider(widget.gameId));
    if (session != null && !session.isFinished) {
      ref.read(gameSessionNotifierProvider(widget.gameId).notifier).cancel();
    }
    context.go('/play');
  }

  void _handleRematch() {
    ref.read(gameSessionNotifierProvider(widget.gameId).notifier).rematch();
  }

  String _getGameTitle() {
    final def = GameRegistry.getDefinition(widget.gameId);
    return def?.title ?? 'Game';
  }

  Widget _buildGameBoard() {
    final adapter = GamePresentationRegistry.getAdapter(widget.gameId);
    if (adapter != null) {
      return adapter.buildBoard();
    }
    return const Center(
      child: Text(
        'Game Board Not Implemented',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  String? _getResultMessage(GameSession session) {
    if (!session.isFinished) return null;
    final adapter = GamePresentationRegistry.getAdapter(widget.gameId);
    final user = ref.read(authProvider).valueOrNull;
    if (adapter != null && user != null) {
      return adapter.getResultMessage(session, user.id);
    }
    if (user != null && session.result?.winnerIds.contains(user.id) == true) {
      return '🏆 YOU WON!';
    }
    return 'GAME OVER';
  }

  bool _isVictory(GameSession session) {
    final adapter = GamePresentationRegistry.getAdapter(widget.gameId);
    final user = ref.read(authProvider).valueOrNull;
    if (adapter != null && user != null) {
      return adapter.isVictory(session, user.id);
    }
    return user != null && session.result?.winnerIds.contains(user.id) == true;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider(widget.gameId));
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _triggerInitialization(next.value!);
      }
    });

    if (authState.hasValue && authState.value != null) {
      _triggerInitialization(authState.value!);
    }

    if (authState.isLoading && !_initialized) {
      return AppScaffold(
        appBar: GameTopBar(
          title: _getGameTitle(),
          isFinished: false,
          onRematch: _handleRematch,
          onExit: _handleExit,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.hasError) {
      return AppScaffold(
        appBar: GameTopBar(
          title: _getGameTitle(),
          isFinished: false,
          onRematch: _handleRematch,
          onExit: _handleExit,
        ),
        body: Center(child: Text('Failed to load profile: ${authState.error}')),
      );
    }

    return AppScaffold(
      appBar: GameTopBar(
        title: _getGameTitle(),
        isFinished: session?.isFinished ?? false,
        onRematch: _handleRematch,
        onExit: _handleExit,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF0F382A),
                  Color(0xFF081C15),
                  Color(0xFF05100C),
                ],
              ),
            ),
          ),

          // Game Board
          if (!_initializing && session != null)
            Positioned.fill(child: _buildGameBoard()),

          // Overlay (Unavailable)
          if (!_initializing && session == null)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videogame_asset_off,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Game Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This game is not available for solo play yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _handleExit,
                        child: const Text('Back to Play'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Overlay (Loading / Result)
          if ((_initializing || (session != null && session.isFinished)) &&
              session != null)
            Positioned.fill(
              child: GameOverlay(
                isLoading: _initializing,
                isFinished: session.isFinished,
                resultMessage: _getResultMessage(session),
                isVictory: _isVictory(session),
                onRematch: _handleRematch,
                onExit: _handleExit,
              ),
            ),
        ],
      ),
    );
  }
}
