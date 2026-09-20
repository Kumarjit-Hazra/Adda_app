import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../activities/engine/player_action.dart';
import '../../domain/game_session.dart';
import '../../domain/game_session_notifier.dart';
import '../../twenty_nine/twenty_nine_models.dart';

/// Solo Twenty-Nine game screen using GameSession architecture.
/// Runs independently without RoomSession, WebRTC, or Chat.
class TwentyNineGameScreen extends ConsumerStatefulWidget {
  const TwentyNineGameScreen({super.key});

  @override
  ConsumerState<TwentyNineGameScreen> createState() =>
      _TwentyNineGameScreenState();
}

class _TwentyNineGameScreenState extends ConsumerState<TwentyNineGameScreen> {
  int _bidSelection = 17;

  @override
  void initState() {
    super.initState();
    // Initialize the solo session after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSoloSession();
    });
  }

  Future<void> _initializeSoloSession() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final notifier = ref.read(
      gameSessionNotifierProvider('twenty_nine').notifier,
    );

    // Create players: human + 3 bots
    final players = [
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

    await notifier.createSoloSession(players: players, localUser: user);
  }

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
    final myId = user?.id ?? session?.players.first.id ?? '';

    if (session == null) {
      return AppScaffold(
        appBar: const AddaTopBar(
          contextBadge: 'ARCADE',
          contextTitle: '29 Cards',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AddaColors.coral),
        ),
      );
    }

    final myHand = session.state.hands[myId] ?? [];
    final currentTurnPlayer =
        session.state.playerIds[session.state.currentTurnIndex];
    final isMyTurn = currentTurnPlayer == myId;

    return AppScaffold(
      appBar: AddaTopBar(
        contextBadge: 'ARCADE',
        contextTitle: '29 Cards',
        actions: [
          if (session.isFinished)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AddaColors.coral),
              onPressed: () {
                ref
                    .read(gameSessionNotifierProvider('twenty_nine').notifier)
                    .rematch();
              },
              tooltip: 'Rematch',
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Exit Game',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF0F382A), Color(0xFF081C15), Color(0xFF05100C)],
          ),
        ),
        child: Column(
          children: [
            // Scoreboard Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                          'Bid: ${session.state.highestBid}',
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
                          'Team You: ${session.state.teamTrickPoints[0] ?? 0} pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AddaColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Team Opp: ${session.state.teamTrickPoints[1] ?? 0} pts',
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
              session.state.playerIds[2],
              session.players[2].name,
              session.state.currentTurnIndex == 2,
            ),

            // Felt Center Table with Opponents on Sides + Trick in Center
            Expanded(
              child: Row(
                children: [
                  // Opponent Left (West)
                  SizedBox(
                    width: 90,
                    child: _buildPlayerSeat(
                      session.state.playerIds[1],
                      session.players[1].name,
                      session.state.currentTurnIndex == 1,
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
                            if (session.state.currentTrick.isEmpty &&
                                session.state.phase == TwentyNinePhase.playing)
                              Text(
                                isMyTurn
                                    ? 'Your Turn to Lead'
                                    : 'Waiting for card...',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ...session.state.currentTrick.map((t) {
                              return _buildCardTile(
                                t.card,
                                isCenterTrick: true,
                              );
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
                      session.state.playerIds[3],
                      session.players[3].name,
                      session.state.currentTurnIndex == 3,
                    ),
                  ),
                ],
              ),
            ),

            // Trump and Action Banner
            if (session.state.phase == TwentyNinePhase.playing)
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
                        color: Colors.black.withAlpha(120),
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
                          if (session.state.isTrumpRevealed &&
                              session.state.trumpSuit != null) ...[
                            Text(
                              session.state.trumpSuit!.symbol,
                              style: TextStyle(
                                fontSize: 16,
                                color: session.state.trumpSuit!.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              session.state.trumpSuit!.name.toUpperCase(),
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
                    if (!session.state.isTrumpRevealed && isMyTurn)
                      AppButton.ghost(
                        text: 'Reveal Trump 🔓',
                        onPressed: () => _dispatch('reveal_trump', {}),
                      ),
                  ],
                ),
              ),

            // Bidding Controls (if in bidding phase)
            if (session.state.phase == TwentyNinePhase.bidding && isMyTurn)
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
                      'Your Turn to Bid (Min ${session.state.highestBid + 1})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Slider(
                      value: (_bidSelection.clamp(
                        session.state.highestBid + 1,
                        28,
                      )).toDouble(),
                      min: (session.state.highestBid + 1).toDouble(),
                      max: 28.0,
                      divisions: (28 - (session.state.highestBid + 1))
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
                          onPressed: () => _dispatch('bid', {'pass': true}),
                        ),
                        AppButton(
                          text: 'Bid $_bidSelection',
                          onPressed: () =>
                              _dispatch('bid', {'bid': _bidSelection}),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Finish / Rematch banner
            if (session.isFinished)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AddaColors.surfaceDark,
                  borderRadius: AddaRadius.radiusLg,
                  border: Border.all(color: AddaColors.coral),
                ),
                child: Column(
                  children: [
                    Text(
                      session.state.winnerTeam == 0
                          ? '🏆 YOU & DIYA WON!'
                          : 'DEFEAT — OPPONENTS WON',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: session.state.winnerTeam == 0
                            ? AddaColors.emerald
                            : AddaColors.rose,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Rematch 🔄',
                      onPressed: () {
                        ref
                            .read(
                              gameSessionNotifierProvider(
                                'twenty_nine',
                              ).notifier,
                            )
                            .rematch();
                      },
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
                      onTap:
                          isMyTurn &&
                              session.state.phase == TwentyNinePhase.playing
                          ? () => _dispatch('play_card', {'card': card.toMap()})
                          : null,
                      child: _buildCardTile(card, isMyTurn: isMyTurn),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
