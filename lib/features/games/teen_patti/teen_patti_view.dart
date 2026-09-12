import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../activities/engine/player_action.dart';
import 'teen_patti_engine.dart';
import 'teen_patti_models.dart';

class TeenPattiView extends ConsumerStatefulWidget {
  const TeenPattiView({super.key});

  @override
  ConsumerState<TeenPattiView> createState() => _TeenPattiViewState();
}

class _TeenPattiViewState extends ConsumerState<TeenPattiView> {
  final TeenPattiEngine _engine = TeenPattiEngine();
  late TeenPattiState _state;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Kabir', 'Ananya']);
  }

  void _onPlayerTurnFinished() {
    // If it's now an AI/simulated opponent's turn, trigger after short delay
    final currentId = _state.currentTurnPlayerId;
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    if (currentId != myId && !_state.roundOver) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted || _state.roundOver) return;

        // Opponent decides to see or bet
        final opp = _state.players[currentId];
        if (opp == null || opp.isFolded) return;

        if (!opp.hasSeenCards && currentId == 'Kabir') {
          // Kabir sees cards
          final seeAction = PlayerAction(
            actionId: const Uuid().v4(),
            playerId: currentId,
            activityId: 'teen_patti',
            type: 'see_cards',
            payload: {},
            clientSequence: _state.version,
          );
          _state = _engine.applyAction(_state, seeAction);
        }

        // Opponent bets chaal or shows if 2 players
        if (_state.activePlayers.length == 2 && opp.currentBet > 50) {
          final showAction = PlayerAction(
            actionId: const Uuid().v4(),
            playerId: currentId,
            activityId: 'teen_patti',
            type: 'show_down',
            payload: {},
            clientSequence: _state.version,
          );
          setState(() {
            _state = _engine.applyAction(_state, showAction);
          });
          AudioService.playCardPlay();
          HapticsService.heavyImpact();
        } else {
          final betAction = PlayerAction(
            actionId: const Uuid().v4(),
            playerId: currentId,
            activityId: 'teen_patti',
            type: 'bet_chaal',
            payload: {},
            clientSequence: _state.version,
          );
          setState(() {
            _state = _engine.applyAction(_state, betAction);
          });
          AudioService.playCardPlay();
          _onPlayerTurnFinished();
        }
      });
    }
  }

  void _seeCards() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'teen_patti',
      type: 'see_cards',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
    HapticsService.lightTap();
  }

  void _betChaal() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'teen_patti',
      type: 'bet_chaal',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playCardPlay();
    HapticsService.mediumImpact();
    _onPlayerTurnFinished();
  }

  void _fold() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'teen_patti',
      type: 'fold',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playCardPlay();
    _onPlayerTurnFinished();
  }

  void _showDown() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'teen_patti',
      type: 'show_down',
      payload: {},
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
    final isMyTurn = _state.currentTurnPlayerId == myId && !_state.roundOver;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF1B4D3E), Color(0xFF0A231A), Color(0xFF04100C)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildOpponentsBar(myId),
            Expanded(child: Center(child: _buildCenterPot())),
            if (myPlayer != null) _buildMyHandSection(myPlayer, isMyTurn),
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
              Icon(Icons.diamond_rounded, color: AddaColors.amber, size: 20),
              SizedBox(width: 6),
              Text(
                'Teen Patti Royale',
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
              border: Border.all(color: AddaColors.amber.withAlpha(100)),
            ),
            child: Text(
              'Boot: ${_state.currentMinChaal}',
              style: const TextStyle(
                color: AddaColors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentsBar(String myId) {
    final opponents = _state.playerIds.where((id) => id != myId).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((oppId) {
          final opp = _state.players[oppId]!;
          final isTurn =
              _state.currentTurnPlayerId == oppId && !_state.roundOver;

          return SurfaceCard(
            padding: const EdgeInsets.all(AddaSpacing.sm),
            borderColor: isTurn ? AddaColors.amber : Colors.white12,
            backgroundColor: isTurn ? Colors.black87 : Colors.black45,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      opp.isFolded
                          ? Icons.cancel_outlined
                          : Icons.person_rounded,
                      size: 14,
                      color: opp.isFolded ? AddaColors.coral : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      opp.id,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: opp.isFolded ? AddaColors.coral : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  opp.isFolded
                      ? 'FOLDED'
                      : (opp.hasSeenCards ? 'SEEN' : 'BLIND'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: opp.hasSeenCards
                        ? AddaColors.cyan
                        : AddaColors.amber,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${opp.chips}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCenterPot() {
    if (_state.roundOver) {
      return SurfaceCard(
        padding: const EdgeInsets.all(AddaSpacing.lg),
        borderColor: AddaColors.amber,
        backgroundColor: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AddaColors.amber,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              '${_state.winnerId} Won Pot!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${_state.pot}',
              style: const TextStyle(
                color: AddaColors.amber,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _state.winningHandDescription ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: AddaSpacing.md),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(authProvider).valueOrNull;
                final myId = user?.id ?? 'player_me';
                setState(() {
                  _state = _engine.createInitialState([
                    myId,
                    'Kabir',
                    'Ananya',
                  ]);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AddaColors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'New Hand',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(color: AddaColors.amber.withAlpha(120), width: 2),
        boxShadow: [
          BoxShadow(
            color: AddaColors.amber.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'POT',
            style: TextStyle(
              color: AddaColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${_state.pot}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyHandSection(TeenPattiPlayer me, bool isMyTurn) {
    final betCost = me.hasSeenCards
        ? _state.currentMinChaal * 2
        : _state.currentMinChaal;

    return Container(
      padding: const EdgeInsets.all(AddaSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddaRadius.xl),
        ),
        border: Border.all(color: isMyTurn ? AddaColors.amber : Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Chips: ₹${me.chips}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMyTurn ? AddaColors.amber : Colors.white12,
                  borderRadius: AddaRadius.radiusSm,
                ),
                child: Text(
                  isMyTurn ? 'YOUR TURN' : 'WAITING',
                  style: TextStyle(
                    color: isMyTurn ? Colors.black : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AddaSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: me.cards
                .map((card) => _buildCardTile(card, me.hasSeenCards))
                .toList(),
          ),
          const SizedBox(height: AddaSpacing.md),
          if (!_state.roundOver && !me.isFolded)
            Row(
              children: [
                if (!me.hasSeenCards)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _seeCards,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AddaColors.cyan,
                        side: const BorderSide(color: AddaColors.cyan),
                      ),
                      child: const Text('See Cards'),
                    ),
                  ),
                if (!me.hasSeenCards) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isMyTurn ? _fold : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AddaColors.coral,
                      side: const BorderSide(color: AddaColors.coral),
                    ),
                    child: const Text('Pack / Fold'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isMyTurn ? _betChaal : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AddaColors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Chaal (₹$betCost)'),
                  ),
                ),
                if (_state.activePlayers.length == 2 && isMyTurn) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showDown,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AddaColors.emerald,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Show'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCardTile(TeenPattiCard card, bool hasSeen) {
    if (!hasSeen) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 60,
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: AddaRadius.radiusMd,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.lock_rounded, color: Colors.white54, size: 24),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 60,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AddaRadius.radiusMd,
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '${card.rankString}${card.suitSymbol}',
                style: TextStyle(
                  color: card.isRed ? Colors.red : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: card.isRed ? Colors.red : Colors.black,
              fontSize: 24,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${card.rankString}${card.suitSymbol}',
                style: TextStyle(
                  color: card.isRed ? Colors.red : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
