import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adda/app/app.dart';
import 'package:adda/features/auth/domain/models/user_profile.dart';
import 'package:adda/features/auth/domain/repositories/auth_repository.dart';
import 'package:adda/features/auth/presentation/providers/auth_provider.dart';

import 'package:adda/features/profile/presentation/widgets/adda_identity_sheet.dart';
import 'package:adda/shared/design_system/widgets/adda_top_bar.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile user;

  MockAuthRepository({
    String id = 'usr_guest_42',
    String name = 'TestGamer',
    String avatarSeed = 'seed_chai',
    UserPreferences preferences = const UserPreferences(),
  }) : user = UserProfile(
         id: id,
         name: name,
         avatarSeed: avatarSeed,
         preferences: preferences,
         createdAt: DateTime.now(),
       );

  @override
  Future<UserProfile> getCurrentUser() async => user;

  @override
  Future<UserProfile> createGuestUser({
    String? name,
    String? avatarSeed,
  }) async {
    user = UserProfile(
      id: 'usr_new_99',
      name: name ?? 'NewGamer',
      avatarSeed: avatarSeed ?? 'seed_tiger',
      createdAt: DateTime.now(),
    );
    return user;
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarSeed,
    String? statusMessage,
    UserPreferences? preferences,
  }) async {
    user = user.copyWith(
      name: name ?? user.name,
      avatarUrl: avatarUrl ?? user.avatarUrl,
      avatarSeed: avatarSeed ?? user.avatarSeed,
      statusMessage: statusMessage ?? user.statusMessage,
      preferences: preferences ?? user.preferences,
    );
    return user;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository(
      id: 'usr_guest_42',
      name: 'StarlightRider',
      avatarSeed: 'seed_chai',
    );
  });

  Widget buildTestWidget({Widget? child}) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(
        home:
            child ??
            const Scaffold(
              appBar: AddaTopBar(),
              body: Center(child: Text('Body')),
            ),
      ),
    );
  }

  group('AddaTopBar & AddaIdentitySheet Widget Tests', () {
    testWidgets('AddaTopBar renders guest name and GUEST badge', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('StarlightRider'), findsOneWidget);
      expect(find.text('GUEST'), findsOneWidget);
      expect(find.text('ADDA'), findsOneWidget);
    });

    testWidgets('Tapping identity pill opens AddaIdentitySheet', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap identity pill
      await tester.tap(find.text('StarlightRider'));
      await tester.pumpAndSettle();

      // Verify identity sheet is open
      expect(find.byType(AddaIdentitySheet), findsOneWidget);
      expect(find.text('Identity & Vibes'), findsOneWidget);
      expect(find.text('Dark Mode Lounge'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.text('Sound Effects (SFX)'), findsOneWidget);
    });

    testWidgets('AddaIdentitySheet allows editing and saving display name', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('StarlightRider'));
      await tester.pumpAndSettle();

      // Tap edit name button (pen icon)
      final editButton = find.byTooltip('Edit name');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Enter new name
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'QuantumKnight');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert state updated
      expect(mockRepo.user.name, equals('QuantumKnight'));
      expect(find.text('QuantumKnight'), findsWidgets);
    });

    testWidgets('AddaIdentitySheet allows selecting avatar character preset', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('StarlightRider'));
      await tester.pumpAndSettle();

      // Tap Tiger preset
      final tigerPreset = find.text('Tiger');
      expect(tigerPreset, findsOneWidget);
      await tester.tap(tigerPreset);
      await tester.pumpAndSettle();

      // Assert avatarSeed updated
      expect(mockRepo.user.avatarSeed, equals('seed_tiger'));
    });

    testWidgets('AddaIdentitySheet toggles preferences reactively', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('StarlightRider'));
      await tester.pumpAndSettle();

      // Find switches
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));

      // Scroll to ensure switches are visible
      await tester.ensureVisible(switches.at(1));
      await tester.pumpAndSettle();

      // Toggle Haptics (second switch)
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();
      expect(mockRepo.user.preferences.hapticsEnabled, isFalse);

      // Toggle Sound Effects (third switch)
      await tester.tap(switches.at(2));
      await tester.pumpAndSettle();
      expect(mockRepo.user.preferences.soundEnabled, isFalse);
    });

    testWidgets(
      'Full app shell boots and navigates to compatibility /profile',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
            child: const AddaApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Top bar appears on Home
        expect(find.byType(AddaTopBar), findsOneWidget);
        expect(find.text('StarlightRider'), findsOneWidget);

        // Open identity sheet
        await tester.tap(find.text('StarlightRider'));
        await tester.pumpAndSettle();

        // Scroll until 'Full Settings' button is visible
        final fullSettingsBtn = find.text('Full Settings');
        await tester.ensureVisible(fullSettingsBtn);
        await tester.pumpAndSettle();

        // Tap 'Full Settings' button to navigate to /profile
        await tester.tap(fullSettingsBtn);
        await tester.pumpAndSettle();

        // Verify we are on ProfileScreen
        expect(find.text('Profile & Settings'), findsOneWidget);
        expect(find.text('ID: usr_guest_42'), findsOneWidget);
      },
    );
  });
}
