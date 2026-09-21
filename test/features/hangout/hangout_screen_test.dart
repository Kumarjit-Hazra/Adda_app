import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';
import 'package:adda/features/hangout/presentation/screens/hangout_screen.dart';

void main() {
  group('HangoutScreen Widget Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
        child: const MaterialApp(home: HangoutScreen()),
      );
    }

    testWidgets('renders Live Now section header when live spaces exist', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      // Use pump() instead of pumpAndSettle() because LiveSpaceCard has
      // a repeating pulse animation that prevents settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Default seed data has 2 live spaces, so "Live Now" header should appear
      expect(find.text('Live Now'), findsOneWidget);
    });

    testWidgets('renders My Spaces section header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Default seed data has favorited spaces
      expect(find.text('My Spaces'), findsOneWidget);
    });

    testWidgets('renders FAB with New Space label', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('New Space'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders live status indicator bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show "2 spaces live right now" from seed data
      expect(find.textContaining('live right now'), findsOneWidget);
    });
  });
}
