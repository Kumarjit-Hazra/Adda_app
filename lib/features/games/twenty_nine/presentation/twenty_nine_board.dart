import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../activities/engine/player_action.dart';

import '../../domain/game_session_notifier.dart';
import '../twenty_nine_models.dart';

class TwentyNineBoard extends ConsumerStatefulWidget {
  const TwentyNineBoard({super.key});

  @override
  ConsumerState<TwentyNineBoard> createState() => _TwentyNineBoardState();
}

class _TwentyNineBoardState extends ConsumerState<TwentyNineBoard> {
  int _bidSelection = 17;

  void _dispatch(String type, Map<String, dynamic> payload) {
    final session = ref.read(gameSessionProvider('twenty_nine'));
    if (session == null) return;

    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? session.players.first.id;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'twenty_nine',
      type: type,
      payload: payload,
      clientSequence: session.version,
    );

    final notifier = ref.read(
      gameSessionNotifierProvider('twenty_nine').notifier,
    );
    if (notifier.dispatchAction(action)) {
      AudioService.playCardPlay();
      HapticsService.cardPlay();
    }
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
    final myHand = state.hands[myId] ?? [];
    final currentTurnPlayer = state.playerIds[state.currentTurnIndex];
    final isMyTurn = currentTurnPlayer == myId;

    return Column(
      children: [
        // Scoreboard Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            backgroundColor: Colors.black.withAlpha(90),
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

        // Partner (Across / Top)
        _buildPlayerSeat(
          state.playerIds[2],
          session.players[2].name,
          state.currentTurnIndex == 2,
        ),

        // Felt Center Table with Opponents on Sides + Trick in Center
        Expanded(
          child: Row(
            children: [
              // Opponent Left (West)
              SizedBox(
                width: 90,
                child: _buildPlayerSeat(
                  state.playerIds[1],
                  session.players[1].name,
                  state.currentTurnIndex == 1,
                ),
              ),

              // Center Trick Table
              Expanded(
                child: Center(
                  child: Container(
                    width: 200,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(60),
                      borderRadius: AddaRadius.radiusXl,
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (state.currentTrick.isEmpty &&
                            state.phase == TwentyNinePhase.playing)
                          Text(
                            isMyTurn
                                ? 'Your Turn to Lead'
                                : 'Waiting for card...',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ...state.currentTrick.map((t) {
                          return _buildCardTile(t.card, isCenterTrick: true);
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Opponent Right (East)
              SizedBox(
                width: 90,
                child: _buildPlayerSeat(
                  state.playerIds[3],
                  session.players[3].name,
                  state.currentTurnIndex == 3,
                ),
              ),
            ],
          ),
        ),

        // Trump and Action Banner
        if (state.phase == TwentyNinePhase.playing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: AddaRadius.radiusSm,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Trump: ',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      if (state.isTrumpRevealed && state.trumpSuit != null) ...[
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
                    onPressed: () => _dispatch('reveal_trump', {}),
                  ),
              ],
            ),
          ),

        // Bidding Controls (if in bidding phase)
        if (state.phase == TwentyNinePhase.bidding && isMyTurn)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  divisions: (28 - (state.highestBid + 1)).clamp(1, 12).toInt(),
                  activeColor: AddaColors.amber,
                  onChanged: (val) =>
                      setState(() => _bidSelection = val.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppButton.ghost(
                      text: 'Pass',
                      onPressed: () => _dispatch('bid', {'pass': true}),
                    ),
                    AppButton(
                      text: 'Bid $_bidSelection',
                      onPressed: () => _dispatch('bid', {'bid': _bidSelection}),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Player's Hand Cards (South)
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: myHand.length,
              itemBuilder: (context, index) {
                final card = myHand[index];
                return GestureDetector(
                  onTap: isMyTurn && state.phase == TwentyNinePhase.playing
                      ? () => _dispatch('play_card', {'card': card.toMap()})
                      : null,
                  child: _buildCardTile(card, isMyTurn: isMyTurn),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSeat(String playerId, String name, bool isTurn) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isTurn ? AddaColors.emerald : Colors.white24,
              width: isTurn ? 2.5 : 1,
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: isTurn
                ? AddaColors.emerald.withAlpha(40)
                : Colors.black45,
            child: Text(
              name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isTurn ? FontWeight.w700 : FontWeight.w500,
            color: isTurn ? AddaColors.emerald : Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCardTile(
    PlayingCard card, {
    bool isMyTurn = false,
    bool isCenterTrick = false,
  }) {
    return Container(
      width: 58,
      height: 86,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: AddaRadius.radiusSm,
        border: Border.all(
          color: isMyTurn ? AddaColors.coral : Colors.black26,
          width: isMyTurn ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            card.rank.label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: card.suit.color == Colors.redAccent
                  ? Colors.red.shade800
                  : Colors.black87,
            ),
          ),
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                fontSize: 24,
                color: card.suit.color == Colors.redAccent
                    ? Colors.red.shade800
                    : Colors.black87,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              card.rank.label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: card.suit.color == Colors.redAccent
                    ? Colors.red.shade800
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
