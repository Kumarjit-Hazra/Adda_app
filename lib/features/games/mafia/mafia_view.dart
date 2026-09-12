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
import 'mafia_engine.dart';
import 'mafia_models.dart';

class MafiaView extends ConsumerStatefulWidget {
  const MafiaView({super.key});

  @override
  ConsumerState<MafiaView> createState() => _MafiaViewState();
}

class _MafiaViewState extends ConsumerState<MafiaView> {
  final MafiaEngine _engine = MafiaEngine();
  late MafiaState _state;
  bool _revealRole = false;
  String? _selectedTarget;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Maya', 'Dev', 'Tara']);
  }

  void _dispatchNightAction(String type, String? target) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'mafia',
      type: type,
      payload: {'target': target},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
      _selectedTarget = null;
    });
    AudioService.playUiTap();
    HapticsService.mediumImpact();
  }

  void _resolveNight() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'mafia',
      type: 'resolve_night',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
    HapticsService.heavyImpact();
  }

  void _advanceToVoting() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'mafia',
      type: 'advance_to_voting',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
  }

  void _voteLynch(String target) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'mafia',
      type: 'vote_lynch',
      payload: {'target': target},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
    HapticsService.lightTap();
  }

  void _resolveDayVote() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'mafia',
      type: 'resolve_day_vote',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
    HapticsService.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myPlayer = _state.players[myId] ?? _state.players.values.first;

    if (_state.isFinished) {
      final result = _engine.getResult(_state);
      return _buildFinishedView(result);
    }

    final isNight = _state.phase == MafiaPhase.nightAction;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? [const Color(0xFF0F0B1E), const Color(0xFF05030A)]
              : [const Color(0xFF2E1A47), const Color(0xFF140D26)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AddaSpacing.md,
            vertical: AddaSpacing.sm,
          ),
          child: Column(
            children: [
              _buildTopBar(isNight),
              const SizedBox(height: AddaSpacing.md),
              _buildMyRoleCard(myPlayer),
              const SizedBox(height: AddaSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (isNight)
                        _buildNightSection(myPlayer)
                      else
                        _buildDaySection(myPlayer),
                      const SizedBox(height: AddaSpacing.md),
                      _buildTownLog(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isNight) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: AddaSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                color: isNight ? AddaColors.violet : AddaColors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isNight
                    ? 'Night ${_state.dayNumber}'
                    : 'Day ${_state.dayNumber} Town Hall',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: AddaRadius.radiusSm,
            ),
            child: Text(
              'Alive: ${_state.alivePlayers.length}/${_state.playerIds.length}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRoleCard(MafiaPlayer me) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.md),
      borderColor: AddaColors.violet.withAlpha(80),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AddaColors.violet.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              me.role == MafiaRole.mafia
                  ? Icons.masks_rounded
                  : (me.role == MafiaRole.doctor
                        ? Icons.medical_services_rounded
                        : (me.role == MafiaRole.detective
                              ? Icons.search_rounded
                              : Icons.person_rounded)),
              color: AddaColors.violet,
            ),
          ),
          const SizedBox(width: AddaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _revealRole ? me.role.name.toUpperCase() : 'SECRET ROLE',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  _revealRole
                      ? _getRoleDescription(me.role)
                      : 'Tap eye icon to view role',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _revealRole ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _revealRole = !_revealRole),
          ),
        ],
      ),
    );
  }

  String _getRoleDescription(MafiaRole role) {
    switch (role) {
      case MafiaRole.mafia:
        return 'Eliminate villagers during the night.';
      case MafiaRole.doctor:
        return 'Protect 1 player each night from death.';
      case MafiaRole.detective:
        return 'Investigate 1 player each night for guilt.';
      case MafiaRole.villager:
        return 'Find the impostor in day discussions.';
    }
  }

  Widget _buildNightSection(MafiaPlayer me) {
    if (!me.isAlive) {
      return const Padding(
        padding: EdgeInsets.all(AddaSpacing.lg),
        child: Text(
          'You are a ghost. Watch the town in peace 👻',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final otherAlive = _state.alivePlayers.where((p) => p.id != me.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          me.role == MafiaRole.mafia
              ? 'Select Victim to Eliminate:'
              : (me.role == MafiaRole.doctor
                    ? 'Select Citizen to Protect:'
                    : (me.role == MafiaRole.detective
                          ? 'Select Suspect to Investigate:'
                          : 'Close your eyes. Town is asleep...')),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        if (me.role != MafiaRole.villager) ...[
          Wrap(
            spacing: 8,
            children: otherAlive.map((target) {
              final isSelected = _selectedTarget == target.id;
              return ChoiceChip(
                label: Text(target.id),
                selected: isSelected,
                onSelected: (val) {
                  setState(() => _selectedTarget = val ? target.id : null);
                  if (val) {
                    if (me.role == MafiaRole.mafia) {
                      _dispatchNightAction('mafia_kill', target.id);
                    } else if (me.role == MafiaRole.doctor) {
                      _dispatchNightAction('doctor_heal', target.id);
                    } else if (me.role == MafiaRole.detective) {
                      _dispatchNightAction('detective_check', target.id);
                    }
                  }
                },
                selectedColor: AddaColors.violet,
              );
            }).toList(),
          ),
          if (_state.detectiveResult != null &&
              me.role == MafiaRole.detective) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: AddaRadius.radiusSm,
              ),
              child: Text(
                'Clue: ${_state.detectiveTarget} is ${_state.detectiveResult}',
                style: const TextStyle(
                  color: AddaColors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: AddaSpacing.md),
        AppButton(
          text: 'Wake Up Town (Resolve Night)',
          onPressed: _resolveNight,
        ),
      ],
    );
  }

  Widget _buildDaySection(MafiaPlayer me) {
    final isVoting = _state.phase == MafiaPhase.dayVoting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(AddaSpacing.md),
          backgroundColor: AddaColors.coral.withAlpha(25),
          borderColor: AddaColors.coral.withAlpha(80),
          child: Row(
            children: const [
              Icon(
                Icons.record_voice_over_rounded,
                color: AddaColors.coral,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Talk over live voice! Present clues, defend yourself, and unmask the Mafia.',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AddaSpacing.md),
        if (!isVoting) ...[
          AppButton(text: 'Call Town Vote 🗳️', onPressed: _advanceToVoting),
        ] else ...[
          const Text(
            'Cast Your Vote:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _state.alivePlayers.map((target) {
              final isVoted = me.votedFor == target.id;
              return ActionChip(
                avatar: isVoted ? const Icon(Icons.check, size: 16) : null,
                label: Text(target.id),
                onPressed: me.isAlive ? () => _voteLynch(target.id) : null,
                backgroundColor: isVoted ? AddaColors.coral : Colors.white12,
              );
            }).toList(),
          ),
          const SizedBox(height: AddaSpacing.md),
          AppButton(
            text: 'Tally Votes & Conclude Trial',
            onPressed: _resolveDayVote,
          ),
        ],
      ],
    );
  }

  Widget _buildTownLog() {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Town Gazette Archive',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          ..._state.townLog.reversed
              .take(4)
              .map(
                (log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $log',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFinishedView(Map<String, dynamic> result) {
    final faction = result['winnerFaction'] as String?;
    final isVillagers = faction == 'villagers';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AddaSpacing.xl),
        child: SurfaceCard(
          padding: const EdgeInsets.all(AddaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVillagers ? Icons.celebration_rounded : Icons.masks_rounded,
                color: isVillagers ? AddaColors.emerald : AddaColors.rose,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                isVillagers ? 'Villagers Win!' : 'Mafia Wins!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Survived after ${result['daysElapsed']} days of deception.',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: AddaSpacing.xl),
              AppButton(
                text: 'New Trial',
                onPressed: () {
                  final user = ref.read(authProvider).valueOrNull;
                  final myId = user?.id ?? 'player_me';
                  setState(() {
                    _state = _engine.createInitialState([
                      myId,
                      'Maya',
                      'Dev',
                      'Tara',
                    ]);
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
