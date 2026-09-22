import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:adda/features/home/presentation/widgets/quick_play_carousel.dart';
import 'package:adda/features/home/application/daily_providers.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/core/storage/storage_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class MockStorage extends StorageService {
  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => true;
}

class MockDailyNotifier extends DailyStateNotifier {
  MockDailyNotifier(super.repository) {
    state = const AsyncValue.data(
      DailyState(dateId: '2026-09-20', dailyPrompt: 'Test'),
    );
  }

  int brainCompletedCalls = 0;

  @override
  Future<void> markBrainCompleted() async {
    brainCompletedCalls++;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('QuickPlayCarousel: supportsSolo=true game routes to solo, '
      'supportsSolo=false game routes to /play', (tester) async {
    String? lastRoute;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: QuickPlayCarousel()),
        ),
        GoRoute(
          path: '/play/solo/:gameId',
          builder: (context, state) {
            lastRoute = '/play/solo/${state.pathParameters['gameId']}';
            return const Scaffold();
          },
        ),
        GoRoute(
          path: '/play',
          builder: (context, state) {
            lastRoute = '/play';
            return const Scaffold();
          },
        ),
      ],
    );

    final repo = DailyRepository(MockStorage());
    final mockNotifier = MockDailyNotifier(repo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyStateProvider.overrideWith((ref) => mockNotifier),
          storageServiceProvider.overrideWithValue(MockStorage()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    // --- Twenty Nine is supportsSolo=true → solo route ---
    await tester.tap(find.text('29 (Twenty-Nine)'));
    await tester.pumpAndSettle();

    expect(lastRoute, '/play/solo/twenty_nine');

    // Go back.
    router.go('/');
    await tester.pumpAndSettle();

    // --- Brain Arena is supportsSolo=false → /play catalog ---
    await tester.tap(find.text('Brain Arena'));
    await tester.pumpAndSettle();

    expect(lastRoute, '/play');

    // --- Verify no Daily completion side-effects from quick play ---
    expect(
      mockNotifier.brainCompletedCalls,
      0,
      reason: 'QuickPlay must NOT call markBrainCompleted',
    );
  });

  testWidgets('QuickPlayCarousel renders all curated games without crash', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: QuickPlayCarousel()),
        ),
        GoRoute(path: '/play', builder: (_, s) => const Scaffold()),
        GoRoute(
          path: '/play/solo/:gameId',
          builder: (_, s) => const Scaffold(),
        ),
      ],
    );

    final repo = DailyRepository(MockStorage());
    final notifier = MockDailyNotifier(repo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyStateProvider.overrideWith((ref) => notifier),
          storageServiceProvider.overrideWithValue(MockStorage()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Quick Play header renders.
    expect(find.text('Quick Play 🚀'), findsOneWidget);
    // View All button routes to /play catalog.
    expect(find.text('View all'), findsOneWidget);
  });
}
