import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
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
              // Scoreboard Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.black.withAlpha(
                    120,
                  ), // Darker for visibility over flame
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AddaColors.coral,
                              borderRadius: AddaRadius.radiusSm,
                            ),
                            child: const Text(
                              '29 TABLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bid: ${state.highestBid}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AddaColors.amber,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Team You: ${state.teamTrickPoints[0] ?? 0} pts',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AddaColors.emerald,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Team Opp: ${state.teamTrickPoints[1] ?? 0} pts',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AddaColors.rose,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Trump and Action Banner
              if (state.phase == TwentyNinePhase.playing)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: AddaRadius.radiusSm,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Trump: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            if (state.isTrumpRevealed &&
                                state.trumpSuit != null) ...[
                              Text(
                                state.trumpSuit!.symbol,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: state.trumpSuit!.color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.trumpSuit!.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else
                              const Text(
                                '🔒 HIDDEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AddaColors.amber,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!state.isTrumpRevealed && isMyTurn)
                        AppButton.ghost(
                          text: 'Reveal Trump 🔓',
                          onPressed: () =>
                              _controller.revealTrump(myId, state.version),
                        ),
                    ],
                  ),
                ),

              // Bidding Controls (if in bidding phase)
              if (state.phase == TwentyNinePhase.bidding && isMyTurn)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AddaColors.surfaceVariantDark,
                    borderRadius: AddaRadius.radiusLg,
                    border: Border.all(color: AddaColors.amber),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Turn to Bid (Min ${state.highestBid + 1})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
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

              // Keep some bottom padding for the Flame player hand
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }
}
