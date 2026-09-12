import 'dart:convert';

enum MafiaRole { mafia, doctor, detective, villager }

enum MafiaPhase { nightAction, nightReveal, dayDiscussion, dayVoting, finished }

class MafiaPlayer {
  final String id;
  final MafiaRole role;
  final bool isAlive;
  final String? votedFor;

  const MafiaPlayer({
    required this.id,
    required this.role,
    required this.isAlive,
    this.votedFor,
  });

  MafiaPlayer copyWith({
    String? id,
    MafiaRole? role,
    bool? isAlive,
    String? votedFor,
    bool clearVote = false,
  }) {
    return MafiaPlayer(
      id: id ?? this.id,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      votedFor: clearVote ? null : (votedFor ?? this.votedFor),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role.name,
    'isAlive': isAlive,
    'votedFor': votedFor,
  };

  factory MafiaPlayer.fromMap(Map<String, dynamic> map) => MafiaPlayer(
    id: map['id'] as String,
    role: MafiaRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => MafiaRole.villager,
    ),
    isAlive: map['isAlive'] as bool? ?? true,
    votedFor: map['votedFor'] as String?,
  );
}

class MafiaState {
  final int version;
  final List<String> playerIds;
  final Map<String, MafiaPlayer> players;
  final MafiaPhase phase;
  final int dayNumber;
  final String? mafiaTarget;
  final String? doctorTarget;
  final String? detectiveTarget;
  final String? detectiveResult;
  final String? lastEliminatedId;
  final String? lastEliminatedRole;
  final String? winnerFaction; // 'mafia' or 'villagers'
  final List<String> townLog;
  final bool isFinished;

  const MafiaState({
    required this.version,
    required this.playerIds,
    required this.players,
    required this.phase,
    required this.dayNumber,
    this.mafiaTarget,
    this.doctorTarget,
    this.detectiveTarget,
    this.detectiveResult,
    this.lastEliminatedId,
    this.lastEliminatedRole,
    this.winnerFaction,
    required this.townLog,
    this.isFinished = false,
  });

  List<MafiaPlayer> get alivePlayers =>
      players.values.where((p) => p.isAlive).toList();

  int get aliveMafiaCount =>
      alivePlayers.where((p) => p.role == MafiaRole.mafia).length;

  int get aliveVillagerCount =>
      alivePlayers.where((p) => p.role != MafiaRole.mafia).length;

  MafiaState copyWith({
    int? version,
    List<String>? playerIds,
    Map<String, MafiaPlayer>? players,
    MafiaPhase? phase,
    int? dayNumber,
    String? mafiaTarget,
    String? doctorTarget,
    String? detectiveTarget,
    String? detectiveResult,
    String? lastEliminatedId,
    String? lastEliminatedRole,
    String? winnerFaction,
    List<String>? townLog,
    bool? isFinished,
    bool clearNightTargets = false,
  }) {
    return MafiaState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      dayNumber: dayNumber ?? this.dayNumber,
      mafiaTarget: clearNightTargets ? null : (mafiaTarget ?? this.mafiaTarget),
      doctorTarget: clearNightTargets
          ? null
          : (doctorTarget ?? this.doctorTarget),
      detectiveTarget: clearNightTargets
          ? null
          : (detectiveTarget ?? this.detectiveTarget),
      detectiveResult: clearNightTargets
          ? null
          : (detectiveResult ?? this.detectiveResult),
      lastEliminatedId: lastEliminatedId ?? this.lastEliminatedId,
      lastEliminatedRole: lastEliminatedRole ?? this.lastEliminatedRole,
      winnerFaction: winnerFaction ?? this.winnerFaction,
      townLog: townLog ?? this.townLog,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'players': players.map((k, v) => MapEntry(k, v.toMap())),
    'phase': phase.name,
    'dayNumber': dayNumber,
    'mafiaTarget': mafiaTarget,
    'doctorTarget': doctorTarget,
    'detectiveTarget': detectiveTarget,
    'detectiveResult': detectiveResult,
    'lastEliminatedId': lastEliminatedId,
    'lastEliminatedRole': lastEliminatedRole,
    'winnerFaction': winnerFaction,
    'townLog': townLog,
    'isFinished': isFinished,
  };

  factory MafiaState.fromMap(Map<String, dynamic> map) => MafiaState(
    version: map['version'] as int,
    playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
    players: (map['players'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, MafiaPlayer.fromMap(v as Map<String, dynamic>)),
    ),
    phase: MafiaPhase.values.firstWhere(
      (p) => p.name == map['phase'],
      orElse: () => MafiaPhase.nightAction,
    ),
    dayNumber: map['dayNumber'] as int,
    mafiaTarget: map['mafiaTarget'] as String?,
    doctorTarget: map['doctorTarget'] as String?,
    detectiveTarget: map['detectiveTarget'] as String?,
    detectiveResult: map['detectiveResult'] as String?,
    lastEliminatedId: map['lastEliminatedId'] as String?,
    lastEliminatedRole: map['lastEliminatedRole'] as String?,
    winnerFaction: map['winnerFaction'] as String?,
    townLog: (map['townLog'] as List<dynamic>).cast<String>(),
    isFinished: map['isFinished'] as bool? ?? false,
  );

  String toJson() => json.encode(toMap());

  factory MafiaState.fromJson(String source) =>
      MafiaState.fromMap(json.decode(source) as Map<String, dynamic>);
}
