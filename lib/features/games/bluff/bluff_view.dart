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
import 'bluff_engine.dart';
import 'bluff_models.dart';

class BluffView extends ConsumerStatefulWidget {
  const BluffView({super.key});

  @override
  ConsumerState<BluffView> createState() => _BluffViewState();
}

class _BluffViewState extends ConsumerState<BluffView> {
  final BluffEngine _engine = BluffEngine();
  late BluffState _state;
  final Set<BluffCard> _selectedCards = {};

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
      activityId: 'bluff',
      type: type,
      payload: payload,
      clientSequence: _state.version,
    );

    if (_engine.validateAction(_state, action)) {
      setState(() {
        _state = _engine.applyAction(_state, action);
        _selectedCards.clear();
      });
      AudioService.playCardPlay();
      HapticsService.cardPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myHand = _state.hands[myId] ?? [];
    final currentTurnPlayer = _state.playerIds[_state.currentTurnIndex];
    final isMyTurn = currentTurnPlayer == myId;
    final canChallenge =
        _state.lastClaim != null && _state.lastClaim!.claimantId != myId;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [Color(0xFF2A1526), Color(0xFF190C17), Color(0xFF0D060C)],
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
                          radius: 18,
                          backgroundColor: isTurn
                              ? AddaColors.rose
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
                            padding: const EdgeInsets.all(3),
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
                    const SizedBox(height: 2),
                    Text(
                      id,
                      style: TextStyle(
                        fontSize: 11,
                        color: isTurn ? AddaColors.rose : Colors.white60,
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

          // Center Penalty Pile & Table
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AddaColors.rose.withAlpha(90),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AddaColors.rose.withAlpha(50),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎭', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            '${_state.centerPile.length} Cards',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'PENALTY PILE',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white38,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AddaColors.surfaceDark,
                      borderRadius: AddaRadius.radiusFull,
                      border: Border.all(color: AddaColors.amber),
                    ),
                    child: Text(
                      'Required Claim: ${_state.currentRankRequirement.label}\'s',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AddaColors.amber,
                      ),
                    ),
                  ),
                  if (_state.lastClaim != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_state.lastClaim!.claimantId} claimed ${_state.lastClaim!.actualCards.length}x ${_state.lastClaim!.declaredRank.label}\'s',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Challenge Alert Banner or Action Buttons
          if (_state.challengeResultBanner != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AddaColors.amber.withAlpha(30),
                borderRadius: AddaRadius.radiusMd,
                border: Border.all(color: AddaColors.amber),
              ),
              child: Text(
                _state.challengeResultBanner!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (canChallenge)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.destructive(
                      text: 'CALL BLUFF! 🚨',
                      onPressed: () => _dispatch('challenge', {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.secondary(
                      text: 'Pass Challenge',
                      onPressed: () => _dispatch('pass_challenge', {}),
                    ),
                  ),
                ],
              ),
            ),

          // Winner banner
          if (_state.winnerId != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AddaColors.surfaceDark,
                borderRadius: AddaRadius.radiusLg,
                border: Border.all(color: AddaColors.rose),
              ),
              child: Column(
                children: [
                  Text(
                    _state.winnerId == myId
                        ? '👑 YOU WON BLUFF MASTERS!'
                        : 'Winner: ${_state.winnerId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AddaColors.rose,
                    ),
                  ),
                  const SizedBox(height: 6),
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

          // Play Selected Cards Button
          if (isMyTurn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: AppButton(
                text: _selectedCards.isEmpty
                    ? 'Select 1-4 Cards to Play'
                    : 'Play ${_selectedCards.length} as ${_state.currentRankRequirement.label}\'s',
                isFullWidth: true,
                onPressed: _selectedCards.isNotEmpty
                    ? () => _dispatch('play_cards', {
                        'cards': _selectedCards.map((c) => c.toMap()).toList(),
                      })
                    : null,
              ),
            ),

          // Player's Hand Cards
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: myHand.length,
                itemBuilder: (context, index) {
                  final card = myHand[index];
                  final isSelected = _selectedCards.contains(card);

                  return GestureDetector(
                    onTap: isMyTurn
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedCards.remove(card);
                              } else {
                                if (_selectedCards.length < 4) {
                                  _selectedCards.add(card);
                                }
                              }
                            });
                            HapticsService.selectionClick();
                          }
                        : null,
                    child: Container(
                      width: 58,
                      height: 88,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AddaColors.rose
                            : const Color(0xFFFBFBFB),
                        borderRadius: AddaRadius.radiusSm,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.black26,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          card.rank.label,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
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
}
