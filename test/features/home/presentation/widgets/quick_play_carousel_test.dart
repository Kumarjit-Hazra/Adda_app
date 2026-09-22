import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:adda/features/home/presentation/widgets/quick_play_carousel.dart';
import 'package:adda/features/home/application/daily_providers.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/shared/design_system/widgets/surface_card.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/core/storage/storage_service.dart';

void main() {
  testWidgets(
    'QuickPlayCarousel routes correctly and does NOT mutate state on tap',
    (tester) async {
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

      // Tap Brain Arena (should go to /play, should NOT trigger completion)
      await tester.tap(find.text('Brain Arena'));
      await tester.pumpAndSettle();

      expect(lastRoute, '/play');
      expect(mockNotifier.brainCompletedCalls, 0);

      // Go back
      router.go('/');
      await tester.pumpAndSettle();

      // Tap Twenty Nine (should go to /play/solo/twenty_nine)
      await tester.tap(find.text('29 (Twenty-Nine)'));
      await tester.pumpAndSettle();

      expect(lastRoute, '/play/solo/twenty_nine');
    },
  );
}

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
