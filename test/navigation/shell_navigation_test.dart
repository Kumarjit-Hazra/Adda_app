import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/app/app.dart';
import 'package:adda/app/router.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';

void main() {
  Widget createTestWidget() {
    final storage = StorageService();
    return ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const AddaApp(),
    );
  }

  setUp(() {
    // Reset router to root
    appRouter.go('/');
  });

  testWidgets(
    '4-branch navigation switches between Home, Play, Hangout, and Chat',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Initial tab is Home
      expect(find.text('Create Space'), findsOneWidget);
      expect(find.text('Join with Code'), findsOneWidget);

      // 2. Switch to Play tab
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(find.text('Play Arena'), findsOneWidget);
      expect(find.text('29 Cards Championship'), findsOneWidget);

      // 3. Switch to Hangout tab
      await tester.tap(find.text('Hangout'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Hangout'), findsOneWidget);
      expect(find.text('All Spaces'), findsOneWidget);

      // 4. Switch to Chat tab
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Chat'), findsOneWidget);
      expect(find.text('All Chats'), findsOneWidget);

      // 5. Switch back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Create Space'), findsOneWidget);
    },
  );

  testWidgets('StatefulShellRoute preserves branch navigation and widget state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Go to Play tab
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // In Play tab, tap 'Card Classics' filter chip
    await tester.tap(find.text('Card Classics'));
    await tester.pumpAndSettle();

    // Verify '29 Cards' is visible and 'Brain Arena' is filtered out
    expect(find.text('29 Cards'), findsOneWidget);
    expect(find.text('Brain Arena'), findsNothing);

    // Switch to Chat tab
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('All Chats'), findsOneWidget);

    // Switch to Hangout tab
    await tester.tap(find.text('Hangout'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Hangout'), findsOneWidget);

    // Switch back to Play tab
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // Verify state was PRESERVED: '29 Cards' is still displayed and 'Brain Arena' is still filtered out!
    expect(find.text('29 Cards'), findsOneWidget);
    expect(find.text('Brain Arena'), findsNothing);
  });

  testWidgets('Compatibility route /profile remains accessible via router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    appRouter.push('/profile');
    await tester.pumpAndSettle();

    expect(find.text('Profile & Settings'), findsOneWidget);
  });

  testWidgets('Compatibility route /discover remains accessible via router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    appRouter.push('/discover');
    await tester.pumpAndSettle();

    expect(find.text('Discover Activities'), findsOneWidget);
  });

  testWidgets('Compatibility route /spaces redirects to /hangout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    appRouter.go('/spaces');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Hangout'), findsOneWidget);
  });
}
