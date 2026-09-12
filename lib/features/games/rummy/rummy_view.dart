import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../activities/engine/player_action.dart';
import 'rummy_engine.dart';
import 'rummy_models.dart';

class RummyView extends ConsumerStatefulWidget {
  const RummyView({super.key});

  @override
  ConsumerState<RummyView> createState() => _RummyViewState();
}

class _RummyViewState extends ConsumerState<RummyView> {
  final RummyEngine _engine = RummyEngine();
  late RummyState _state;
  int? _selectedCardIndex;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Arjun']);
  }

  void _onOpponentTurn() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final currentId = _state.currentTurnPlayerId;

    if (currentId != myId && !_state.isFinished) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || _state.isFinished) return;

        // Draw from closed
        final drawAction = PlayerAction(
          actionId: const Uuid().v4(),
          playerId: currentId,
          activityId: 'rummy',
          type: 'draw_card',
          payload: {'source': 'closed'},
          clientSequence: _state.version,
        );
        setState(() {
          _state = _engine.applyAction(_state, drawAction);
        });
        AudioService.playCardPlay();

        // Discard first card after short pause
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted || _state.isFinished) return;
          final discardAction = PlayerAction(
            actionId: const Uuid().v4(),
            playerId: currentId,
            activityId: 'rummy',
            type: 'discard_card',
            payload: {'index': 0},
            clientSequence: _state.version,
          );
          setState(() {
            _state = _engine.applyAction(_state, discardAction);
          });
          AudioService.playCardPlay();
        });
      });
    }
  }

  void _drawCard(String source) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'rummy',
      type: 'draw_card',
      payload: {'source': source},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playCardPlay();
    HapticsService.lightTap();
  }

  void _discardSelectedCard() {
    if (_selectedCardIndex == null) return;
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'rummy',
      type: 'discard_card',
      payload: {'index': _selectedCardIndex!},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
      _selectedCardIndex = null;
    });
    AudioService.playCardPlay();
    HapticsService.mediumImpact();
    _onOpponentTurn();
  }

  void _declare() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final player = _state.players[myId];
    if (player == null) return;

    // Build dummy 4-card pure sequence, 3-card sequence, and sets for demo declare
    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'rummy',
      type: 'declare',
      payload: {
        'groups': [
          [
            const RummyCard(suit: RummySuit.spades, rank: 1).toMap(),
            const RummyCard(suit: RummySuit.spades, rank: 2).toMap(),
            const RummyCard(suit: RummySuit.spades, rank: 3).toMap(),
            const RummyCard(suit: RummySuit.spades, rank: 4).toMap(),
          ],
          [
            const RummyCard(suit: RummySuit.hearts, rank: 8).toMap(),
            const RummyCard(suit: RummySuit.hearts, rank: 9).toMap(),
            const RummyCard(suit: RummySuit.hearts, rank: 10).toMap(),
          ],
          [
            const RummyCard(suit: RummySuit.diamonds, rank: 5).toMap(),
            const RummyCard(suit: RummySuit.clubs, rank: 5).toMap(),
            const RummyCard(suit: RummySuit.spades, rank: 5).toMap(),
          ],
          [
            const RummyCard(suit: RummySuit.diamonds, rank: 7).toMap(),
            const RummyCard(suit: RummySuit.clubs, rank: 7).toMap(),
            const RummyCard(suit: RummySuit.spades, rank: 7).toMap(),
          ],
        ],
      },
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playCardPlay();
    HapticsService.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myPlayer = _state.players[myId];
    final isMyTurn = _state.currentTurnPlayerId == myId;

    if (_state.isFinished) {
      final result = _engine.getResult(_state);
      return _buildFinishedView(result);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 8),
            _buildCenterTable(isMyTurn),
            const Spacer(),
            if (myPlayer != null) _buildHandSection(myPlayer, isMyTurn),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: AddaSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.style_rounded, color: AddaColors.cyan, size: 20),
              SizedBox(width: 6),
              Text(
                'Indian Rummy (13 Cards)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: AddaRadius.radiusSm,
              border: Border.all(color: AddaColors.cyan.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Text(
                  'Joker: ',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '${_state.wildJoker.rankString}${_state.wildJoker.suitSymbol}',
                  style: TextStyle(
                    color: _state.wildJoker.isRed
                        ? Colors.redAccent
                        : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterTable(bool isMyTurn) {
    final topDiscard = _state.openDeck.isNotEmpty ? _state.openDeck.last : null;
    final canDraw = isMyTurn && _state.turnStage == RummyTurnStage.draw;

    return Padding(
      padding: const EdgeInsets.all(AddaSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Closed Draw Deck
          GestureDetector(
            onTap: canDraw ? () => _drawCard('closed') : null,
            child: Container(
              width: 72,
              height: 100,
              decoration: BoxDecoration(
                color: canDraw
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF1E3A8A),
                borderRadius: AddaRadius.radiusMd,
                border: Border.all(
                  color: canDraw ? AddaColors.cyan : Colors.white30,
                  width: canDraw ? 2 : 1,
                ),
                boxShadow: canDraw
                    ? [
                        BoxShadow(
                          color: AddaColors.cyan.withAlpha(60),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style, color: Colors.white70, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '${_state.closedDeck.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'DRAW',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Open Discard Deck
          GestureDetector(
            onTap: canDraw && topDiscard != null
                ? () => _drawCard('open')
                : null,
            child: Container(
              width: 72,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AddaRadius.radiusMd,
                border: Border.all(
                  color: canDraw ? AddaColors.emerald : Colors.white30,
                  width: canDraw ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: topDiscard != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${topDiscard.rankString}${topDiscard.suitSymbol}',
                          style: TextStyle(
                            color: topDiscard.isRed ? Colors.red : Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          topDiscard.suitSymbol,
                          style: TextStyle(
                            color: topDiscard.isRed ? Colors.red : Colors.black,
                            fontSize: 28,
                          ),
                        ),
                        const Text(
                          'DISCARD',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'EMPTY',
                        style: TextStyle(color: Colors.black38, fontSize: 10),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandSection(RummyPlayer me, bool isMyTurn) {
    final canDiscard = isMyTurn && _state.turnStage == RummyTurnStage.discard;

    return Container(
      padding: const EdgeInsets.all(AddaSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddaRadius.xl),
        ),
        border: Border.all(color: isMyTurn ? AddaColors.cyan : Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cards: ${me.hand.length}/13',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMyTurn ? AddaColors.cyan : Colors.white12,
                  borderRadius: AddaRadius.radiusSm,
                ),
                child: Text(
                  isMyTurn
                      ? (_state.turnStage == RummyTurnStage.draw
                            ? 'DRAW A CARD'
                            : 'DISCARD A CARD')
                      : 'OPPONENT TURN',
                  style: TextStyle(
                    color: isMyTurn ? Colors.black : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: me.hand.length,
              itemBuilder: (context, index) {
                final card = me.hand[index];
                final isSelected = _selectedCardIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(
                      () => _selectedCardIndex = isSelected ? null : index,
                    );
                    AudioService.playUiTap();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    transform: isSelected
                        ? Matrix4.translationValues(0, -8, 0)
                        : Matrix4.identity(),
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AddaRadius.radiusSm,
                      border: Border.all(
                        color: isSelected
                            ? AddaColors.cyan
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '${card.rankString}${card.suitSymbol}',
                              style: TextStyle(
                                color: card.isRed ? Colors.red : Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          card.suitSymbol,
                          style: TextStyle(
                            color: card.isRed ? Colors.red : Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AddaSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canDiscard && _selectedCardIndex != null
                      ? _discardSelectedCard
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AddaColors.coral,
                    side: const BorderSide(color: AddaColors.coral),
                  ),
                  child: const Text('Discard Card'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isMyTurn && me.hand.length == 14 ? _declare : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AddaColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Declare Show'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedView(Map<String, dynamic> result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AddaSpacing.xl),
        child: SurfaceCard(
          padding: const EdgeInsets.all(AddaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AddaColors.amber,
                size: 60,
              ),
              const SizedBox(height: 12),
              const Text(
                'Rummy Declared!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Winner: ${result['winnerId']} (0 Pts)',
                style: const TextStyle(
                  fontSize: 16,
                  color: AddaColors.emerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AddaSpacing.xl),
              AppButton(
                text: 'Play Another Deal',
                onPressed: () {
                  final user = ref.read(authProvider).valueOrNull;
                  final myId = user?.id ?? 'player_me';
                  setState(() {
                    _state = _engine.createInitialState([myId, 'Arjun']);
                    _selectedCardIndex = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
