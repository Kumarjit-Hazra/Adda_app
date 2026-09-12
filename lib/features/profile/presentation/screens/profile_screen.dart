import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditNicknameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AddaColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: AddaRadius.radiusXl),
        title: const Text(
          'Change Nickname',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: AppTextField(
          controller: controller,
          labelText: 'Your Handle',
          autofocus: true,
        ),
        actions: [
          AppButton.ghost(
            text: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton(
            text: 'Save',
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(authProvider.notifier).updateProfile(name: newName);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          return ListView(
            padding: const EdgeInsets.all(AddaSpacing.lg),
            children: [
              // User Card
              SurfaceCard(
                padding: const EdgeInsets.all(AddaSpacing.lg),
                child: Row(
                  children: [
                    AppAvatar(name: user.name, size: 60, isOnline: true),
                    const SizedBox(width: AddaSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AddaColors.amber.withAlpha(30),
                                  borderRadius: AddaRadius.radiusXs,
                                ),
                                child: const Text(
                                  'GUEST',
                                  style: TextStyle(
                                    color: AddaColors.amber,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.statusMessage ?? 'Chilling at Adda ☕️',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AddaColors.textSecondaryDark
                                  : AddaColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${user.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: AddaColors.coral,
                      ),
                      tooltip: 'Edit Nickname',
                      onPressed: () =>
                          _showEditNicknameDialog(context, ref, user.name),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AddaSpacing.xl),
              Text(
                'Preferences & Feedback',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AddaSpacing.sm),

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
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Deep night UI optimized for gaming sessions',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: const Icon(
                        Icons.dark_mode_rounded,
                        color: AddaColors.violet,
                      ),
                      value: ref.watch(themeModeProvider) == ThemeMode.dark,
                      activeTrackColor: AddaColors.coral,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state = val
                            ? ThemeMode.dark
                            : ThemeMode.light;
                        HapticsService.selectionClick();
                      },
                    ),
                    const Divider(),
                    // Haptics Switch
                    SwitchListTile(
                      title: const Text(
                        'Haptic Feedback',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Tactile vibration on card play and trick wins',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: const Icon(
                        Icons.vibration_rounded,
                        color: AddaColors.emerald,
                      ),
                      value: HapticsService.enabled,
                      activeTrackColor: AddaColors.coral,
                      onChanged: (val) {
                        HapticsService.enabled = val;
                        if (val) HapticsService.lightTap();
                        ref.read(authProvider.notifier).loadUser();
                      },
                    ),
                    const Divider(),
                    // Audio SFX Switch
                    SwitchListTile(
                      title: const Text(
                        'Sound Effects (SFX)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Card deals, countdown ticks, and reaction pops',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: const Icon(
                        Icons.volume_up_rounded,
                        color: AddaColors.amber,
                      ),
                      value: AudioService.sfxEnabled,
                      activeTrackColor: AddaColors.coral,
                      onChanged: (val) {
                        AudioService.sfxEnabled = val;
                        if (val) AudioService.playUiTap();
                        ref.read(authProvider.notifier).loadUser();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AddaSpacing.xl),
              Text(
                'Account & Privacy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AddaSpacing.sm),

              SurfaceCard(
                padding: const EdgeInsets.all(AddaSpacing.md),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.refresh_rounded,
                        color: AddaColors.cyan,
                      ),
                      title: const Text(
                        'Regenerate Guest Identity',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Generate a new random handle & guest token',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                      onTap: () async {
                        await ref.read(authProvider.notifier).regenerateGuest();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('New guest identity generated!'),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.shield_outlined,
                        color: AddaColors.emerald,
                      ),
                      title: const Text(
                        'Private by Default',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Rooms are invitation-only. WebRTC media is never logged.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AddaSpacing.xxl),
              Center(
                child: Column(
                  children: [
                    Text(
                      'ADDA • v1.0.0 (Build 1)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AddaColors.textMutedDark
                            : AddaColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Built with Google Antigravity & Flutter 3.41',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AddaColors.textMutedDark
                            : AddaColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
