import 'package:flutter_test/flutter_test.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/spaces/data/space_repository_impl.dart';
import 'package:adda/features/spaces/domain/models/space_model.dart';

void main() {
  group('SpaceRepository Unit Tests', () {
    late StorageService storage;
    late SpaceRepositoryImpl repo;

    setUp(() {
      storage = StorageService();
      repo = SpaceRepositoryImpl(storage);
    });

    test('retrieves default starter spaces on fresh launch', () async {
      final spaces = await repo.getSpaces();
      expect(spaces.isNotEmpty, isTrue);
      expect(spaces.any((s) => s.type == SpaceType.friends), isTrue);
      expect(spaces.any((s) => s.type == SpaceType.gameNight), isTrue);
    });

    test('creates new space with unique 6-character code', () async {
      final newSpace = await repo.createSpace(
        name: 'Late Night Coders',
        type: SpaceType.study,
        description: 'Focus room for building cool things',
        ownerId: 'usr_test_1',
      );

      expect(newSpace.name, 'Late Night Coders');
      expect(newSpace.inviteCode.length, 6);

      final found = await repo.getSpaceByInviteCode(newSpace.inviteCode);
      expect(found, isNotNull);
      expect(found!.id, newSpace.id);
    });

    test('toggles favorite space state cleanly', () async {
      final spaces = await repo.getSpaces();
      final target = spaces.first;
      final initialFav = target.isFavorite;

      final toggled = await repo.toggleFavorite(target.id);
      expect(toggled.isFavorite, !initialFav);
    });

    test('default spaces include Phase 6 presence fields', () async {
      final spaces = await repo.getSpaces();
      // At least one space should be live with participants
      final liveSpaces = spaces.where((s) => s.isLive).toList();
      expect(liveSpaces.isNotEmpty, isTrue);
      expect(
        liveSpaces.any((s) => s.activeParticipantCount > 0),
        isTrue,
      );
      expect(
        liveSpaces.any((s) => s.currentActivityName != null),
        isTrue,
      );
    });

    test('serialization round-trip preserves presence fields', () async {
      final original = SpaceModel(
        id: 'spc_test_serial',
        name: 'Serial Test',
        description: 'Testing serialization',
        type: SpaceType.gameNight,
        inviteCode: 'TSTS01',
        ownerId: 'usr_test',
        memberIds: ['usr_test'],
        isFavorite: true,
        lastActiveAt: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 1),
        isLive: true,
        activeParticipantCount: 7,
        currentActivityName: 'Brain Arena',
        lastActivityAt: DateTime(2026, 9, 20, 14, 30),
      );

      final json = original.toJson();
      final restored = SpaceModel.fromJson(json);

      expect(restored.isLive, original.isLive);
      expect(
        restored.activeParticipantCount,
        original.activeParticipantCount,
      );
      expect(restored.currentActivityName, original.currentActivityName);
      expect(restored.lastActivityAt, original.lastActivityAt);
    });
  });
}
