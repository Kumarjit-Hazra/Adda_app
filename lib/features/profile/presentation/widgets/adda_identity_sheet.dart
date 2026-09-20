import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../screens/profile_screen.dart';

/// Interactive modal sheet allowing users to customize their guest identity,
/// avatar character seed, and tactile/audio/theme preferences.
class AddaIdentitySheet extends ConsumerStatefulWidget {
  const AddaIdentitySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddaIdentitySheet(),
    );
  }

  @override
  ConsumerState<AddaIdentitySheet> createState() => _AddaIdentitySheetState();
}

class _AddaIdentitySheetState extends ConsumerState<AddaIdentitySheet> {
  late final TextEditingController _nameController;
  bool _isEditingName = false;

  static const List<Map<String, String>> _characterPresets = [
    {'seed': 'seed_chai', 'label': 'Kulhad Chai', 'emoji': '☕️'},
    {'seed': 'seed_tiger', 'label': 'Cosmic Tiger', 'emoji': '🐯'},
    {'seed': 'seed_phoenix', 'label': 'Golden Phoenix', 'emoji': '🦅'},
    {'seed': 'seed_bluff', 'label': 'Bluff King', 'emoji': '🎭'},
    {'seed': 'seed_cosmic', 'label': 'Cosmic Surfer', 'emoji': '🚀'},
    {'seed': 'seed_neon', 'label': 'Neon Spark', 'emoji': '⚡️'},
    {'seed': 'seed_wizard', 'label': 'Mystic Wizard', 'emoji': '🧙'},
    {'seed': 'seed_joker', 'label': 'Starlight Joker', 'emoji': '🃏'},
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).asData?.value;
    _nameController = TextEditingController(text: user?.name ?? 'Guest');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      ref.read(authProvider.notifier).updateProfile(name: newName);
      setState(() => _isEditingName = false);
      HapticsService.success();
      AudioService.playUiTap();
    }
  }

  void _selectAvatarSeed(String seed) {
    ref.read(authProvider.notifier).updateAvatarSeed(seed);
    HapticsService.selectionClick();
    AudioService.playUiTap();
  }

  void _randomizeSeed() {
    final randomSeed = 'seed_${Random().nextInt(999999)}';
    ref.read(authProvider.notifier).updateAvatarSeed(randomSeed);
    HapticsService.lightTap();
    AudioService.playUiTap();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return userAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Error loading profile: $err')),
      ),
      data: (user) {
        final currentSeed = user.avatarSeed ?? 'seed_chai';
        final prefs = user.preferences;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? AddaColors.borderDark : AddaColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AddaSpacing.lg,
                    vertical: AddaSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AddaSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: AddaRadius.radiusFull,
                          ),
                        ),
                      ),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AddaColors.amber.withAlpha(35),
                                  borderRadius: AddaRadius.radiusSm,
                                ),
                                child: const Text(
                                  'GUEST IDENTITY',
                                  style: TextStyle(
                                    color: AddaColors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Identity & Vibes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AddaSpacing.md),

                      // Character Preview Card
                      SurfaceCard(
                        padding: const EdgeInsets.all(AddaSpacing.lg),
                        child: Column(
                          children: [
                            AppAvatar(
                              name: user.name,
                              avatarSeed: currentSeed,
                              size: 72,
                              isOnline: true,
                            ),
                            const SizedBox(height: AddaSpacing.md),

                            // Name Editing row
                            if (_isEditingName)
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _nameController,
                                      labelText: 'Display Name',
                                      autofocus: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppButton(text: 'Save', onPressed: _saveName),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: AddaColors.coral,
                                    ),
                                    tooltip: 'Edit name',
                                    onPressed: () {
                                      _nameController.text = user.name;
                                      setState(() => _isEditingName = true);
                                    },
                                  ),
                                ],
                              ),

                            const SizedBox(height: 4),
                            Text(
                              user.statusMessage ?? 'Chilling at Adda ☕️',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AddaColors.textSecondaryDark
                                    : AddaColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ID pill
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: user.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Guest UUID copied to clipboard!',
                                    ),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: AddaRadius.radiusSm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(15),
                                  borderRadius: AddaRadius.radiusSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ID: ${user.id}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 12,
                                      color: Colors.white38,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AddaSpacing.lg),

                      // Avatar Character Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Avatar Character',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _randomizeSeed,
                            icon: const Icon(
                              Icons.casino_outlined,
                              size: 16,
                              color: AddaColors.coral,
                            ),
                            label: const Text(
                              'Surprise Me',
                              style: TextStyle(
                                color: AddaColors.coral,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AddaSpacing.xs),

                      // Character Carousel / Grid
                      SizedBox(
                        height: 74,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _characterPresets.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final preset = _characterPresets[index];
                            final isSelected = currentSeed == preset['seed'];

                            return GestureDetector(
                              onTap: () => _selectAvatarSeed(preset['seed']!),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 64,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AddaColors.coral.withAlpha(40)
                                      : (isDark
                                            ? AddaColors.surfaceElevatedDark
                                            : AddaColors.surfaceLight),
                                  borderRadius: AddaRadius.radiusMd,
                                  border: Border.all(
                                    color: isSelected
                                        ? AddaColors.coral
                                        : Colors.white.withAlpha(20),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      preset['emoji']!,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      preset['label']!.split(' ').last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AddaColors.coral
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: AddaSpacing.xl),

                      // Preferences Section
                      const Text(
                        'Vibes & Preferences',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AddaSpacing.xs),

                      SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            // Theme Switch
                            SwitchListTile(
                              title: const Text(
                                'Dark Mode Lounge',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: const Text(
                                'Midnight palette for card gaming sessions',
                                style: TextStyle(fontSize: 11),
                              ),
                              secondary: const Icon(
                                Icons.dark_mode_rounded,
                                color: AddaColors.violet,
                                size: 22,
                              ),
                              value: prefs.themeMode == 'dark',
                              activeTrackColor: AddaColors.coral,
                              onChanged: (val) {
                                final newTheme = val ? 'dark' : 'light';
                                ref.read(themeModeProvider.notifier).state = val
                                    ? ThemeMode.dark
                                    : ThemeMode.light;
                                ref
                                    .read(authProvider.notifier)
                                    .updatePreferences(
                                      prefs.copyWith(themeMode: newTheme),
                                    );
                                HapticsService.selectionClick();
                              },
                            ),
                            const Divider(height: 1),

                            // Haptics Switch
                            SwitchListTile(
                              title: const Text(
                                'Haptic Feedback',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: const Text(
                                'Tactile vibrations on card deals and wins',
                                style: TextStyle(fontSize: 11),
                              ),
                              secondary: const Icon(
                                Icons.vibration_rounded,
                                color: AddaColors.emerald,
                                size: 22,
                              ),
                              value: prefs.hapticsEnabled,
                              activeTrackColor: AddaColors.coral,
                              onChanged: (val) {
                                ref
                                    .read(authProvider.notifier)
                                    .updatePreferences(
                                      prefs.copyWith(hapticsEnabled: val),
                                    );
                                if (val) HapticsService.lightTap();
                              },
                            ),
                            const Divider(height: 1),

                            // Audio Switch
                            SwitchListTile(
                              title: const Text(
                                'Sound Effects (SFX)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: const Text(
                                'Interactive audio cues for plays and reactions',
                                style: TextStyle(fontSize: 11),
                              ),
                              secondary: const Icon(
                                Icons.volume_up_rounded,
                                color: AddaColors.amber,
                                size: 22,
                              ),
                              value: prefs.soundEnabled,
                              activeTrackColor: AddaColors.coral,
                              onChanged: (val) {
                                ref
                                    .read(authProvider.notifier)
                                    .updatePreferences(
                                      prefs.copyWith(soundEnabled: val),
                                    );
                                if (val) AudioService.playUiTap();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AddaSpacing.lg),

                      // Quick Actions: Regenerate & Legacy Profile
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              text: 'New Guest ID',
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              onPressed: () async {
                                await ref
                                    .read(authProvider.notifier)
                                    .regenerateGuest();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'New guest identity generated!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AddaSpacing.md),
                          Expanded(
                            child: AppButton.ghost(
                              text: 'Full Settings',
                              icon: const Icon(
                                Icons.settings_outlined,
                                size: 16,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push('/profile');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AddaSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
