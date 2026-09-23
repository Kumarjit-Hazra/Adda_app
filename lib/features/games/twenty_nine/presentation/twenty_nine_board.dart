import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../domain/game_session_notifier.dart';
import '../twenty_nine_models.dart';
import 'twenty_nine_controller.dart';
import '../../flame/core/flame_game_host.dart';
import '../../flame/twenty_nine/twenty_nine_flame_game.dart';

class TwentyNineBoard extends ConsumerStatefulWidget {
  const TwentyNineBoard({super.key});

  @override
  ConsumerState<TwentyNineBoard> createState() => _TwentyNineBoardState();
}

class _TwentyNineBoardState extends ConsumerState<TwentyNineBoard> {
  int _bidSelection = 17;
  late final TwentyNineController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TwentyNineController(ref);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider('twenty_nine'));
    final user = ref.watch(authProvider).valueOrNull;

    if (session == null || session.state is! TwentyNineState) {
      return const Center(
        child: CircularProgressIndicator(color: AddaColors.coral),
      );
    }

    final state = session.state as TwentyNineState;
    final myId = user?.id ?? session.players.first.id;
    final currentTurnPlayer = state.playerIds[state.currentTurnIndex];
    final isMyTurn = currentTurnPlayer == myId;

    return Stack(
      children: [
        // Flame Game Layer (Background, Seats, Table, Cards)
        Positioned.fill(
          child: FlameGameHost<TwentyNineState, TwentyNineFlameGame>(
            gameId: 'twenty_nine',
            gameFactory: () =>
                TwentyNineFlameGame(controller: _controller, localUserId: myId),
          ),
        ),

        // Flutter HUD Layer
        SafeArea(
          child: Column(
            children: [
              // Premium Score Area
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: AddaRadius.radiusLg,
                    border: Border.all(color: Colors.white.withAlpha(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Teams Score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTeamScore(
                            'TEAM YOU',
                            state.teamTrickPoints[0] ?? 0,
                            AddaColors.emerald,
                          ),
                          _buildTeamScore(
                            'TEAM OPP',
                            state.teamTrickPoints[1] ?? 0,
                            AddaColors.rose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(height: 1, color: Colors.white.withAlpha(20)),
                      const SizedBox(height: 12),
                      // Bid and Trump
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatBadge(
                            'BID',
                            state.highestBid.toString(),
                            Icons.gavel_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white.withAlpha(30),
                          ),
                          _buildTrumpBadge(state),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action Area
              if (state.phase == TwentyNinePhase.playing &&
                  !state.isTrumpRevealed &&
                  isMyTurn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppButton(
                    text: 'Reveal Trump 🔓',
                    onPressed: () =>
                        _controller.revealTrump(myId, state.version),
                  ),
                ),

              // Bidding Controls (if in bidding phase)
              if (state.phase == TwentyNinePhase.bidding && isMyTurn)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(220),
                    borderRadius: AddaRadius.radiusLg,
                    border: Border.all(color: AddaColors.amber),
                    boxShadow: [
                      BoxShadow(
                        color: AddaColors.amber.withAlpha(40),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Turn to Bid (Min ${state.highestBid + 1})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: (_bidSelection.clamp(
                          state.highestBid + 1,
                          28,
                        )).toDouble(),
                        min: (state.highestBid + 1).toDouble(),
                        max: 28.0,
                        divisions: (28 - (state.highestBid + 1))
                            .clamp(1, 12)
                            .toInt(),
                        activeColor: AddaColors.amber,
                        inactiveColor: Colors.white24,
                        onChanged: (val) =>
                            setState(() => _bidSelection = val.toInt()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AppButton.ghost(
                            text: 'Pass',
                            onPressed: () =>
                                _controller.passBid(myId, state.version),
                          ),
                          AppButton(
                            text: 'Bid $_bidSelection',
                            onPressed: () => _controller.bid(
                              _bidSelection,
                              myId,
                              state.version,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Keep bottom padding for the Flame player hand
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamScore(String name, int points, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color.withAlpha(200),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              points.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'pts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withAlpha(150),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrumpBadge(TwentyNineState state) {
    if (state.isTrumpRevealed && state.trumpSuit != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.trumpSuit!.symbol,
            style: TextStyle(
              fontSize: 24,
              color: state.trumpSuit!.color,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TRUMP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
              Text(
                state.trumpSuit!.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: state.trumpSuit!.color,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_rounded, size: 18, color: AddaColors.amber),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'TRUMP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            Text(
              'HIDDEN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AddaColors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
