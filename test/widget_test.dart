import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/app/app.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('ADDA app boots and displays 4-branch navigation shell', (
    WidgetTester tester,
  ) async {
    final storage = StorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const AddaApp(),
      ),
    );

    // Initial frame
    await tester.pumpAndSettle();

    // Verify presence of 4 primary bottom navigation labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Hangout'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);

    // Verify Profile and Discover are NOT in the bottom navigation bar
    final bottomNavFinder = find.byType(BottomNavigationBar);
    expect(bottomNavFinder, findsOneWidget);
    expect(
      find.descendant(of: bottomNavFinder, matching: find.text('Profile')),
      findsNothing,
    );
    expect(
      find.descendant(of: bottomNavFinder, matching: find.text('Discover')),
      findsNothing,
    );

    // Verify main action buttons on Home screen
    expect(find.textContaining('TODAY\'S ADDA'), findsOneWidget);
  });
}
