import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/app/app.dart';
import 'package:adda/core/storage/storage_service.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('ADDA app boots and displays home navigation shell', (
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

    // Verify presence of bottom navigation labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Spaces'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify main action buttons
    expect(find.text('Create Space'), findsOneWidget);
    expect(find.text('Join with Code'), findsOneWidget);
  });
}
