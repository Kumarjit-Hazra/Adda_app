import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/player_action.dart';
import 'package:adda/features/games/mafia/mafia_engine.dart';
import 'package:adda/features/games/mafia/mafia_models.dart';

void main() {
  group('MafiaEngine Unit Tests', () {
    late MafiaEngine engine;
    final players = ['p_mafia', 'p_doctor', 'p_detective', 'p_villager'];

    setUp(() {
      engine = MafiaEngine();
    });

    test('initializes with roles and night action phase', () {
      final state = engine.createInitialState(players);
      expect(state.phase, MafiaPhase.nightAction);
      expect(state.players['p_mafia']!.role, MafiaRole.mafia);
      expect(state.players['p_doctor']!.role, MafiaRole.doctor);
      expect(state.players['p_detective']!.role, MafiaRole.detective);
      expect(state.players['p_villager']!.role, MafiaRole.villager);
    });

    test('doctor saving mafia target prevents death', () {
      var state = engine.createInitialState(players);

      final killAction = PlayerAction(
        actionId: 'm1',
        playerId: 'p_mafia',
        activityId: 'mafia',
        type: 'mafia_kill',
        payload: {'target': 'p_villager'},
        clientSequence: 1,
      );

      final healAction = PlayerAction(
        actionId: 'm2',
        playerId: 'p_doctor',
        activityId: 'mafia',
        type: 'doctor_heal',
        payload: {'target': 'p_villager'},
        clientSequence: 2,
      );

      state = engine.applyAction(state, killAction);
      state = engine.applyAction(state, healAction);

      final resolveAction = PlayerAction(
        actionId: 'm3',
        playerId: 'p_mafia',
        activityId: 'mafia',
        type: 'resolve_night',
        payload: {},
        clientSequence: 3,
      );

      state = engine.applyAction(state, resolveAction);

      expect(state.phase, MafiaPhase.dayDiscussion);
      expect(state.players['p_villager']!.isAlive, isTrue);
      expect(state.townLog.last, contains('Doctor saved the victim'));
    });

    test('detective can check suspect', () {
      var state = engine.createInitialState(players);

      final checkAction = PlayerAction(
        actionId: 'm4',
        playerId: 'p_detective',
        activityId: 'mafia',
        type: 'detective_check',
        payload: {'target': 'p_mafia'},
        clientSequence: 1,
      );

      state = engine.applyAction(state, checkAction);
      expect(state.detectiveResult, contains('MAFIA'));
    });
  });
}
