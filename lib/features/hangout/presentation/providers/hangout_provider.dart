import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../spaces/domain/models/space_model.dart';
import '../../../spaces/presentation/providers/space_provider.dart';

/// Spaces currently live (isLive == true), sorted by active participant count
/// descending so the busiest spaces appear first in the carousel.
final liveSpacesProvider = Provider<List<SpaceModel>>((ref) {
  final spacesAsync = ref.watch(spacesProvider);
  return spacesAsync.when(
    data: (spaces) {
      final live = spaces.where((s) => s.isLive).toList()
        ..sort(
          (a, b) =>
              b.activeParticipantCount.compareTo(a.activeParticipantCount),
        );
      return live;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});

/// Spaces the user owns or has favorited, sorted by last active time.
final mySpacesProvider = Provider<List<SpaceModel>>((ref) {
  final spacesAsync = ref.watch(spacesProvider);
  final user = ref.watch(authProvider).valueOrNull;
  final userId = user?.id ?? '';

  return spacesAsync.when(
    data: (spaces) {
      final mine = spaces
          .where((s) => s.isFavorite || s.ownerId == userId)
          .toList()
        ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
      return mine;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});

/// Non-live spaces that had activity recently, sorted by lastActivityAt
/// descending, limited to 5.
final recentlyActiveProvider = Provider<List<SpaceModel>>((ref) {
  final spacesAsync = ref.watch(spacesProvider);
  return spacesAsync.when(
    data: (spaces) {
      final recent = spaces
          .where((s) => !s.isLive && s.lastActivityAt != null)
          .toList()
        ..sort((a, b) {
          final aTime = a.lastActivityAt ?? DateTime(2000);
          final bTime = b.lastActivityAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
      return recent.take(5).toList();
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
