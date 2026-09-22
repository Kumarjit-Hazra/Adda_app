import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/game_session.dart';
import '../../domain/game_session_notifier.dart';
import '../../twenty_nine/presentation/twenty_nine_board.dart';
import '../widgets/game_overlay.dart';
import '../widgets/game_top_bar.dart';
import '../../twenty_nine/twenty_nine_models.dart';

class ActiveGameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const ActiveGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends ConsumerState<ActiveGameScreen> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final notifier = ref.read(
      gameSessionNotifierProvider(widget.gameId).notifier,
    );

    // TODO: Ideally we configure bots based on game definition.
    // Since TwentyNine is our reference, we hardcode 3 bots here for solo mode if it's twenty_nine
    List<GamePlayer> players = [];
    if (widget.gameId == 'twenty_nine') {
      players = [
        GamePlayer.human(
          id: user.id,
          name: user.name,
          avatarUrl: user.avatarUrl,
          isHost: true,
          teamIndex: 0,
        ),
        GamePlayer.bot(id: 'bot_1', name: 'Kabir Bot 🤖', teamIndex: 1),
        GamePlayer.bot(id: 'bot_2', name: 'Diya Bot 🤖', teamIndex: 0),
        GamePlayer.bot(id: 'bot_3', name: 'Aarav Bot 🤖', teamIndex: 1),
      ];
    } else {
      // Generic fallback for future games
      players = [
        GamePlayer.human(
          id: user.id,
          name: user.name,
          avatarUrl: user.avatarUrl,
          isHost: true,
          teamIndex: 0,
        ),
        GamePlayer.bot(id: 'bot_1', name: 'Bot 🤖', teamIndex: 1),
      ];
    }

    await notifier.createSoloSession(players: players, localUser: user);

    if (mounted) {
      setState(() {
        _initializing = false;
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
    if (widget.gameId == 'twenty_nine') return '29 Cards';
    return 'Game';
  }

  Widget _buildGameBoard() {
    if (widget.gameId == 'twenty_nine') {
      return const TwentyNineBoard();
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

    // For 29 specifically, check team
    if (widget.gameId == 'twenty_nine' && session.state is TwentyNineState) {
      final state = session.state as TwentyNineState;
      if (state.winnerTeam == 0) {
        return '🏆 YOU & DIYA WON!';
      } else {
        return 'DEFEAT — OPPONENTS WON';
      }
    }

    // Generic fallback
    final user = ref.read(authProvider).valueOrNull;
    if (user != null && session.result?.winnerIds.contains(user.id) == true) {
      return '🏆 YOU WON!';
    }
    return 'GAME OVER';
  }

  bool _isVictory(GameSession session) {
    if (widget.gameId == 'twenty_nine' && session.state is TwentyNineState) {
      return (session.state as TwentyNineState).winnerTeam == 0;
    }
    final user = ref.read(authProvider).valueOrNull;
    return user != null && session.result?.winnerIds.contains(user.id) == true;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider(widget.gameId));

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

          // Overlay (Loading / Result)
          if (_initializing || session == null || session.isFinished)
            Positioned.fill(
              child: GameOverlay(
                isLoading: _initializing || session == null,
                isFinished: session?.isFinished ?? false,
                resultMessage: session != null
                    ? _getResultMessage(session)
                    : null,
                isVictory: session != null ? _isVictory(session) : false,
                onRematch: _handleRematch,
                onExit: _handleExit,
              ),
            ),
        ],
      ),
    );
  }
}
