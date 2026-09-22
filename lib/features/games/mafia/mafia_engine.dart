import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'mafia_models.dart';

class MafiaEngine implements ActivityEngine<MafiaState> {
  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'mafia',
    title: 'Mafia / Werewolf',
    description:
        'Social deduction thriller. Night killings, doctor heals, detective clues, and heated town hall trials.',
    category: ActivityCategory.party,
    minPlayers: 4,
    maxPlayers: 12,
    estimatedDuration: Duration(minutes: 15),
    rules:
        '1. Secret roles assigned: Mafia, Doctor, Detective, Villagers.\n2. Night: Mafia chooses victim, Doctor heals, Detective investigates.\n3. Day: Town discusses clues over voice and votes to eliminate a suspect.',
  );

  @override
  MafiaState createInitialState(List<String> playerIds) {
    final players = <String, MafiaPlayer>{};
    // Assign roles
    final roles = [
      MafiaRole.mafia,
      MafiaRole.doctor,
      MafiaRole.detective,
      MafiaRole.villager,
      MafiaRole.villager,
      MafiaRole.mafia,
    ];

    for (int i = 0; i < playerIds.length; i++) {
      final pid = playerIds[i];
      final role = i < roles.length ? roles[i] : MafiaRole.villager;
      players[pid] = MafiaPlayer(id: pid, role: role, isAlive: true);
    }

    return MafiaState(
      version: 1,
      playerIds: playerIds,
      players: players,
      phase: MafiaPhase.nightAction,
      dayNumber: 1,
      townLog: ['The sun sets on the town. Night 1 begins...'],
      isFinished: false,
    );
  }

  @override
  bool validateAction(MafiaState state, PlayerAction action) {
    if (state.isFinished) return false;
    final player = state.players[action.playerId];
    if (player == null || !player.isAlive) return false;

    switch (action.type) {
      case 'mafia_kill':
        return state.phase == MafiaPhase.nightAction &&
            player.role == MafiaRole.mafia;
      case 'doctor_heal':
        return state.phase == MafiaPhase.nightAction &&
            player.role == MafiaRole.doctor;
      case 'detective_check':
        return state.phase == MafiaPhase.nightAction &&
            player.role == MafiaRole.detective;
      case 'resolve_night':
        return state.phase == MafiaPhase.nightAction;
      case 'advance_to_voting':
        return state.phase == MafiaPhase.dayDiscussion;
      case 'vote_lynch':
        return state.phase == MafiaPhase.dayVoting;
      case 'resolve_day_vote':
        return state.phase == MafiaPhase.dayVoting;
      default:
        return false;
    }
  }

  @override
  MafiaState applyAction(MafiaState state, PlayerAction action) {
    if (!validateAction(state, action)) return state;
    final player = state.players[action.playerId]!;

    switch (action.type) {
      case 'mafia_kill':
        final target = action.payload['target'] as String?;
        return state.copyWith(version: state.version + 1, mafiaTarget: target);

      case 'doctor_heal':
        final target = action.payload['target'] as String?;
        return state.copyWith(version: state.version + 1, doctorTarget: target);

      case 'detective_check':
        final target = action.payload['target'] as String?;
        String? result;
        if (target != null && state.players.containsKey(target)) {
          final targetPlayer = state.players[target]!;
          result = targetPlayer.role == MafiaRole.mafia
              ? 'MAFIA 👺'
              : 'INNOCENT 😇';
        }
        return state.copyWith(
          version: state.version + 1,
          detectiveTarget: target,
          detectiveResult: result,
        );

      case 'resolve_night':
        final killed = state.mafiaTarget;
        final saved = state.doctorTarget;
        final updatedPlayers = Map<String, MafiaPlayer>.from(state.players);
        final newLogs = List<String>.from(state.townLog);

        String? eliminatedId;
        String? eliminatedRole;

        if (killed != null &&
            killed != saved &&
            updatedPlayers.containsKey(killed)) {
          final victim = updatedPlayers[killed]!;
          updatedPlayers[killed] = victim.copyWith(isAlive: false);
          eliminatedId = killed;
          eliminatedRole = victim.role.name;
          newLogs.add('Tragedy struck! $killed was eliminated by the Mafia.');
        } else if (killed != null && killed == saved) {
          newLogs.add(
            'A miracle occurred! The Doctor saved the victim from harm.',
          );
        } else {
          newLogs.add('The night was quiet. No one was harmed.');
        }

        final checkWin = _checkWinCondition(updatedPlayers);
        if (checkWin != null) {
          newLogs.add('GAME OVER: $checkWin');
          return state.copyWith(
            version: state.version + 1,
            players: updatedPlayers,
            phase: MafiaPhase.finished,
            winnerFaction: checkWin.contains('Villagers')
                ? 'villagers'
                : 'mafia',
            lastEliminatedId: eliminatedId,
            lastEliminatedRole: eliminatedRole,
            townLog: newLogs,
            isFinished: true,
          );
        }

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          phase: MafiaPhase.dayDiscussion,
          lastEliminatedId: eliminatedId,
          lastEliminatedRole: eliminatedRole,
          townLog: newLogs,
          clearNightTargets: true,
        );

      case 'advance_to_voting':
        return state.copyWith(
          version: state.version + 1,
          phase: MafiaPhase.dayVoting,
        );

      case 'vote_lynch':
        final target = action.payload['target'] as String?;
        final updatedPlayer = player.copyWith(votedFor: target);
        final updatedPlayers = Map<String, MafiaPlayer>.from(state.players);
        updatedPlayers[action.playerId] = updatedPlayer;

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
        );

      case 'resolve_day_vote':
        final votes = <String, int>{};
        for (final p in state.alivePlayers) {
          if (p.votedFor != null) {
            votes[p.votedFor!] = (votes[p.votedFor!] ?? 0) + 1;
          }
        }

        String? lynchedId;
        int maxVotes = 0;
        votes.forEach((target, count) {
          if (count > maxVotes) {
            maxVotes = count;
            lynchedId = target;
          }
        });

        final updatedPlayers = Map<String, MafiaPlayer>.from(state.players);
        final newLogs = List<String>.from(state.townLog);

        if (lynchedId != null && maxVotes > (state.alivePlayers.length / 2)) {
          final String targetId = lynchedId!;
          final condemned = updatedPlayers[targetId]!;
          updatedPlayers[targetId] = condemned.copyWith(isAlive: false);
          newLogs.add(
            'Town voted to execute $targetId (${condemned.role.name.toUpperCase()}).',
          );
        } else {
          newLogs.add(
            'No majority was reached. Town trial concluded with no elimination.',
          );
        }

        // Reset votes for alive players
        for (final id in updatedPlayers.keys) {
          updatedPlayers[id] = updatedPlayers[id]!.copyWith(clearVote: true);
        }

        final checkWin = _checkWinCondition(updatedPlayers);
        if (checkWin != null) {
          newLogs.add('GAME OVER: $checkWin');
          return state.copyWith(
            version: state.version + 1,
            players: updatedPlayers,
            phase: MafiaPhase.finished,
            winnerFaction: checkWin.contains('Villagers')
                ? 'villagers'
                : 'mafia',
            townLog: newLogs,
            isFinished: true,
          );
        }

        return state.copyWith(
          version: state.version + 1,
          players: updatedPlayers,
          phase: MafiaPhase.nightAction,
          dayNumber: state.dayNumber + 1,
          townLog: newLogs,
        );

      default:
        return state;
    }
  }

  String? _checkWinCondition(Map<String, MafiaPlayer> players) {
    final alive = players.values.where((p) => p.isAlive).toList();
    final mafiaCount = alive.where((p) => p.role == MafiaRole.mafia).length;
    final villagerCount = alive.where((p) => p.role != MafiaRole.mafia).length;

    if (mafiaCount == 0) return 'Villagers Win! 🕊️';
    if (mafiaCount >= villagerCount) return 'Mafia Wins! 👺';
    return null;
  }

  @override
  String? getCurrentTurnPlayerId(MafiaState state) => null;

  @override
  bool isFinished(MafiaState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(MafiaState state) {
    return {
      'winnerFaction': state.winnerFaction,
      'survivors': state.alivePlayers.map((p) => p.id).toList(),
      'daysElapsed': state.dayNumber,
    };
  }

  @override
  String serialize(MafiaState state) => state.toJson();

  @override
  MafiaState deserialize(String raw) => MafiaState.fromJson(raw);
}
