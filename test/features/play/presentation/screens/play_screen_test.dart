import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/play/presentation/screens/play_screen.dart';
import 'package:adda/features/games/domain/game_registry.dart';
import 'package:adda/shared/design_system/widgets/adda_top_bar.dart';

void main() {
  setUp(() {
    GameRegistry.initialize();
  });

  Widget buildTestApp() {
    return const ProviderScope(
      child: MaterialApp(home: PlayScreen()),
    );
  }

  group('PlayScreen Tests', () {
    testWidgets('renders AppScaffold and top bar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AddaTopBar), findsOneWidget);
      expect(find.text('Play Arena'), findsOneWidget);
    });

    testWidgets('renders featured game (Twenty Nine)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('FEATURED THIS WEEK'), findsOneWidget);
      expect(find.text('29 (Twenty-Nine)'), findsOneWidget);
      expect(find.text('Quick Play Solo'), findsOneWidget);
    });

    testWidgets('renders categories based on GameRegistry', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('All Games'), findsOneWidget);
      expect(find.text('Card Classics'), findsOneWidget);
      expect(find.text('Party & Deception'), findsOneWidget);
    });

    testWidgets('filters games by category', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Ensure UNO is visible if it's rendered further down
      final unoFinder = find.text('UNO Clash');
      if (unoFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(unoFinder.first);
        expect(unoFinder, findsWidgets);
      }
      
      // Tap on Party & Deception
      final partyFinder = find.text('Party & Deception');
      await tester.ensureVisible(partyFinder);
      await tester.tap(partyFinder);
      await tester.pumpAndSettle();

      // UNO Clash (Cards) should no longer be in the grid
      expect(find.text('UNO Clash'), findsNothing);
      
      // Bluff Masters (Party) should be in the grid
      final bluffFinder = find.text('Bluff Masters');
      if (bluffFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(bluffFinder.first);
      }
      expect(bluffFinder, findsWidgets);
    });
  });
}
