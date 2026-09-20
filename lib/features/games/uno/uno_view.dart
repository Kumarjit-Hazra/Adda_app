import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../activities/engine/player_action.dart';
import 'uno_engine.dart';
import 'uno_models.dart';

class UnoView extends ConsumerStatefulWidget {
  const UnoView({super.key});

  @override
  ConsumerState<UnoView> createState() => _UnoViewState();
}

class _UnoViewState extends ConsumerState<UnoView> {
  final UnoEngine _engine = UnoEngine();
  late UnoState _state;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Aarav', 'Diya']);
  }

  void _dispatch(String type, Map<String, dynamic> payload) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'uno',
      type: type,
      payload: payload,
      clientSequence: _state.version,
    );

    if (_engine.validateAction(_state, action)) {
      setState(() {
        _state = _engine.applyAction(_state, action);
      });
      AudioService.playCardPlay();
      HapticsService.cardPlay();
    }
  }

  void _promptWildColorChoice(UnoCard card) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AddaColors.surfaceDark,
        title: const Text(
          'Choose Color',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              [
                UnoColor.red,
                UnoColor.blue,
                UnoColor.green,
                UnoColor.yellow,
              ].map((c) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _dispatch('play_card', {
                      'card': card.toMap(),
                      'chosenColor': c.name,
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.displayColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.displayColor.withAlpha(90),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myHand = _state.hands[myId] ?? [];
    final currentTurnPlayer = _state.playerIds[_state.currentTurnIndex];
    final isMyTurn = currentTurnPlayer == myId;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [Color(0xFF221A3B), Color(0xFF130E24), Color(0xFF0A0714)],
        ),
      ),
      child: Column(
        children: [
          // Opponents Seat Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _state.playerIds.where((id) => id != myId).map((id) {
                final cardCount = _state.hands[id]?.length ?? 0;
                final isTurn = currentTurnPlayer == id;
                return Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isTurn
                              ? AddaColors.amber
                              : Colors.white12,
                          child: Text(
                            id[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AddaColors.coral,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$cardCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      id,
                      style: TextStyle(
                        fontSize: 11,
                        color: isTurn ? AddaColors.amber : Colors.white60,
                        fontWeight: isTurn
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Center Table with Discard and Draw Piles
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Draw Pile
                  GestureDetector(
                    onTap: isMyTurn ? () => _dispatch('draw_card', {}) : null,
                    child: Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2438),
                        borderRadius: AddaRadius.radiusMd,
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'DRAW',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${_state.drawPile.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Top Discard Pile with Active Color Glow
                  Container(
                    width: 86,
                    height: 128,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: _state.activeColor.displayColor.withAlpha(140),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _buildUnoCardView(_state.topDiscard),
                  ),
                ],
              ),
            ),
          ),

          // Active Color and Direction Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Color: ',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _state.activeColor.displayColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _state.activeColor.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _state.activeColor.displayColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  _state.isClockwise
                      ? 'Direction: ↻ Clockwise'
                      : 'Direction: ↺ Counter-Clockwise',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),

          // Uno Shout Banner
          if (myHand.length <= 2 && !_state.hasShoutedUno)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AppButton(
                text: 'SHOUT UNO! 🔥',
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                onPressed: () => _dispatch('shout_uno', {}),
              ),
            ),

          // Winner banner
          if (_state.winnerId != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AddaColors.surfaceDark,
                borderRadius: AddaRadius.radiusLg,
                border: Border.all(color: AddaColors.amber),
              ),
              child: Column(
                children: [
                  Text(
                    _state.winnerId == myId
                        ? '🎉 YOU WON UNO!'
                        : 'Winner: ${_state.winnerId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AddaColors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Play Again',
                    onPressed: () {
                      setState(() {
                        _state = _engine.createInitialState(_state.playerIds);
                      });
                    },
                  ),
                ],
              ),
            ),

          // Player's Hand Cards
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: myHand.length,
                itemBuilder: (context, index) {
                  final card = myHand[index];
                  final isPlayable =
                      isMyTurn &&
                      (card.isWild ||
                          card.color == _state.activeColor ||
                          card.value == _state.topDiscard.value);

                  return GestureDetector(
                    onTap: isPlayable
                        ? () {
                            if (card.isWild) {
                              _promptWildColorChoice(card);
                            } else {
                              _dispatch('play_card', {'card': card.toMap()});
                            }
                          }
                        : null,
                    child: Opacity(
                      opacity: isPlayable || !isMyTurn ? 1.0 : 0.45,
                      child: _buildUnoCardView(card, isPlayable: isPlayable),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnoCardView(UnoCard card, {bool isPlayable = false}) {
    return Container(
      width: 64,
      height: 96,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: card.color.displayColor,
        borderRadius: AddaRadius.radiusMd,
        border: Border.all(
          color: isPlayable ? Colors.white : Colors.white24,
          width: isPlayable ? 2.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              card.value.label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Center(
            child: Text(
              card.value.label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 6,
            child: Text(
              card.value.label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
