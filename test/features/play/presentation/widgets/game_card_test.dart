import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adda/features/activities/engine/activity_definition.dart';
import 'package:adda/features/games/domain/game_registry.dart';
import 'package:adda/features/play/presentation/widgets/game_card.dart';

void main() {
  setUp(() {
    GameRegistry.initialize();
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('GameCard Tests', () {
    testWidgets('renders game title and metadata correctly', (tester) async {
      final game = GameDefinition(
        id: 'test_game',
        activityId: 'test_game',
        title: 'Test Game Title',
        category: ActivityCategory.party,
        minPlayers: 3,
        maxPlayers: 5,
        estimatedDuration: const Duration(minutes: 15),
      );

      await tester.pumpWidget(
        buildTestApp(GameCard(game: game, isDark: true, onTap: () {})),
      );

      expect(find.text('Test Game Title'), findsOneWidget);
      expect(find.text('3-5 Players'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      final game = GameDefinition(
        id: 'test_game',
        activityId: 'test_game',
        title: 'Test Game Title',
        category: ActivityCategory.party,
        minPlayers: 2,
        maxPlayers: 4,
        estimatedDuration: const Duration(minutes: 10),
      );

      bool tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          GameCard(
            game: game,
            isDark: false,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(GameCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows solo badge if game is twenty_nine', (tester) async {
      final game = GameDefinition(
        id: 'twenty_nine',
        activityId: 'twenty_nine',
        title: 'Twenty Nine',
        category: ActivityCategory.cards,
        minPlayers: 4,
        maxPlayers: 4,
        estimatedDuration: const Duration(minutes: 15),
      );

      await tester.pumpWidget(
        buildTestApp(GameCard(game: game, isDark: false, onTap: () {})),
      );

      expect(find.text('SOLO'), findsOneWidget);
    });
  });
}
