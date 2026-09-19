import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import 'activity_launcher_sheet.dart';

enum GamePlayMode { soloWithBots, customWithFriends }

class GameModeResult {
  final GamePlayMode mode;
  final bool autoJoinVoice;

  const GameModeResult({required this.mode, required this.autoJoinVoice});
}

class GameModeSheet extends StatefulWidget {
  final ActivityItem activity;

  const GameModeSheet({super.key, required this.activity});

  static Future<GameModeResult?> show(
    BuildContext context,
    ActivityItem activity,
  ) {
    return showModalBottomSheet<GameModeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GameModeSheet(activity: activity),
    );
  }

  @override
  State<GameModeSheet> createState() => _GameModeSheetState();
}

class _GameModeSheetState extends State<GameModeSheet> {
  GamePlayMode _selectedMode = GamePlayMode.soloWithBots;
  bool _autoJoinVoice = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.activity;

    return Container(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131726) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddaRadius.xxl),
        ),
        border: Border.all(color: item.accentColor.withAlpha(100), width: 1.5),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AddaSpacing.md),

            // Game Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.accentColor.withAlpha(30),
                    borderRadius: AddaRadius.radiusMd,
                    border: Border.all(
                      color: item.accentColor.withAlpha(120),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(item.icon, color: item.accentColor, size: 28),
                ),
                const SizedBox(width: AddaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.playerRange} • ${item.duration}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AddaColors.textSecondaryDark
                              : AddaColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AddaSpacing.lg),

            const Text(
              'CHOOSE HOW TO PLAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: AddaSpacing.sm),

            // Option 1: Solo with Bots
            _buildModeOption(
              mode: GamePlayMode.soloWithBots,
              title: 'Solo Practice with Bots 🤖',
              subtitle:
                  'Instant gameplay against smart bots. No waiting, no voice chat, play in peace.',
              accentColor: AddaColors.violet,
              isSelected: _selectedMode == GamePlayMode.soloWithBots,
              badge: 'OFFLINE FRIENDLY',
            ),
            const SizedBox(height: AddaSpacing.sm),

            // Option 2: Custom with Friends
            _buildModeOption(
              mode: GamePlayMode.customWithFriends,
              title: 'Custom with Friends 👥',
              subtitle:
                  'Create a private room with a 6-letter code to play with friends in real time.',
              accentColor: AddaColors.coral,
              isSelected: _selectedMode == GamePlayMode.customWithFriends,
              badge: 'MULTIPLAYER',
            ),

            // If Custom with Friends selected, show optional Voice Chat switch
            if (_selectedMode == GamePlayMode.customWithFriends) ...[
              const SizedBox(height: AddaSpacing.md),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AddaSpacing.md,
                  vertical: AddaSpacing.sm,
                ),
                backgroundColor: AddaColors.emerald.withAlpha(15),
                borderColor: AddaColors.emerald.withAlpha(50),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mic_none_rounded,
                      color: AddaColors.emerald,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Voice Chat on Entry',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Optional. You can also join voice later while playing.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _autoJoinVoice,
                      activeTrackColor: AddaColors.emerald,
                      onChanged: (val) => setState(() => _autoJoinVoice = val),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AddaSpacing.xl),

            // Start Button
            AppButton(
              text: _selectedMode == GamePlayMode.soloWithBots
                  ? 'Start Solo Game 🚀'
                  : 'Create Friend Room 🎉',
              onPressed: () {
                Navigator.of(context).pop(
                  GameModeResult(
                    mode: _selectedMode,
                    autoJoinVoice:
                        _selectedMode == GamePlayMode.customWithFriends &&
                        _autoJoinVoice,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required GamePlayMode mode,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isSelected,
    required String badge,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AddaSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withAlpha(25)
              : Colors.white.withAlpha(5),
          borderRadius: AddaRadius.radiusLg,
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          borderRadius: AddaRadius.radiusXs,
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? accentColor : Colors.white24,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
