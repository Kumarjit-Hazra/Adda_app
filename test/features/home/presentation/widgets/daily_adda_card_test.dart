import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/features/home/presentation/widgets/daily_adda_card.dart';
import 'package:adda/features/home/application/daily_providers.dart';
import 'package:adda/features/home/domain/models/daily_state.dart';
import 'package:adda/shared/design_system/widgets/app_button.dart';
import 'package:adda/features/home/data/daily_repository.dart';
import 'package:adda/core/storage/storage_service.dart';

void main() {
  testWidgets('DailyAddaCard enables share button when text is entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyStateProvider.overrideWith((ref) => MockDailyNotifier(ref.watch(dailyRepositoryProvider))),
          storageServiceProvider.overrideWithValue(MockStorage()),
        ],
        child: const MaterialApp(home: Scaffold(body: DailyAddaCard())),
      ),
    );

    await tester.pumpAndSettle();

    // Check if TextField exists
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Initial state: Share button is disabled
    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);

    // Enter text
    await tester.enterText(textField, 'My answer');
    await tester.pump();

    // Share button is now enabled
    final enabledButton = tester.widget<AppButton>(find.byType(AppButton));
    expect(enabledButton.onPressed, isNotNull);
  });
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
      DailyState(dateId: '2026-09-20', dailyPrompt: 'Test Prompt'),
    );
  }

  @override
  Future<void> markAddaAnswered() async {
    state = AsyncValue.data(state.value!.copyWith(isAddaAnswered: true));
  }
}
