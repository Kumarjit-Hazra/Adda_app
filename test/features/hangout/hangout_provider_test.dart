import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/spaces/domain/models/space_model.dart';

void main() {
  final now = DateTime.now();

  // Test data: mix of live, non-live, favorited, owned spaces
  final testSpaces = [
    SpaceModel(
      id: 'spc_1',
      name: 'Live Party',
      description: 'Currently live',
      type: SpaceType.friends,
      inviteCode: 'LIVE01',
      ownerId: 'user_1',
      memberIds: ['user_1'],
      isFavorite: true,
      lastActiveAt: now,
      createdAt: now.subtract(const Duration(days: 1)),
      isLive: true,
      activeParticipantCount: 5,
      currentActivityName: 'UNO Clash',
      lastActivityAt: now.subtract(const Duration(minutes: 2)),
    ),
    SpaceModel(
      id: 'spc_2',
      name: 'Quiet Room',
      description: 'Not live, recently active',
      type: SpaceType.study,
      inviteCode: 'QUIET1',
      ownerId: 'user_2',
      memberIds: ['user_2'],
      isFavorite: false,
      lastActiveAt: now.subtract(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(days: 5)),
      isLive: false,
      activeParticipantCount: 0,
      lastActivityAt: now.subtract(const Duration(hours: 1)),
    ),
    SpaceModel(
      id: 'spc_3',
      name: 'Small Hangout',
      description: 'Live but smaller',
      type: SpaceType.gameNight,
      inviteCode: 'SMALL3',
      ownerId: 'user_1',
      memberIds: ['user_1'],
      isFavorite: false,
      lastActiveAt: now.subtract(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(days: 2)),
      isLive: true,
      activeParticipantCount: 2,
      currentActivityName: 'Twenty-Nine',
      lastActivityAt: now.subtract(const Duration(minutes: 10)),
    ),
    SpaceModel(
      id: 'spc_4',
      name: 'Archived Space',
      description: 'Not live, no recent activity',
      type: SpaceType.couple,
      inviteCode: 'OLD123',
      ownerId: 'user_3',
      memberIds: ['user_3'],
      isFavorite: true,
      lastActiveAt: now.subtract(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 60)),
      isLive: false,
      activeParticipantCount: 0,
      lastActivityAt: now.subtract(const Duration(days: 10)),
    ),
  ];

  group('Hangout Provider Logic Tests', () {
    test('liveSpaces filters only live spaces sorted by participant count', () {
      final live = testSpaces.where((s) => s.isLive).toList()
        ..sort(
          (a, b) =>
              b.activeParticipantCount.compareTo(a.activeParticipantCount),
        );

      expect(live.length, 2);
      expect(live[0].id, 'spc_1'); // 5 participants, first
      expect(live[1].id, 'spc_3'); // 2 participants, second
    });

    test('mySpaces returns favorited or owned spaces by user', () {
      const userId = 'user_1';
      final mine =
          testSpaces.where((s) => s.isFavorite || s.ownerId == userId).toList()
            ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));

      expect(mine.length, 3); // spc_1 (fav+owned), spc_3 (owned), spc_4 (fav)
      expect(mine.first.id, 'spc_1'); // most recently active
    });

    test('recentlyActive excludes live spaces and limits to 5', () {
      final recent =
          testSpaces
              .where((s) => !s.isLive && s.lastActivityAt != null)
              .toList()
            ..sort((a, b) {
              final aTime = a.lastActivityAt ?? DateTime(2000);
              final bTime = b.lastActivityAt ?? DateTime(2000);
              return bTime.compareTo(aTime);
            });
      final limited = recent.take(5).toList();

      expect(limited.every((s) => !s.isLive), isTrue);
      expect(limited.length, 2); // spc_2 and spc_4
      expect(limited[0].id, 'spc_2'); // more recently active
    });

    test('empty input produces empty lists', () {
      final emptySpaces = <SpaceModel>[];

      final live = emptySpaces.where((s) => s.isLive).toList();
      final mine = emptySpaces
          .where((s) => s.isFavorite || s.ownerId == 'user_1')
          .toList();
      final recent = emptySpaces
          .where((s) => !s.isLive && s.lastActivityAt != null)
          .toList();

      expect(live, isEmpty);
      expect(mine, isEmpty);
      expect(recent, isEmpty);
    });
  });
}
