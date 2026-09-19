import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import 'game_mode_sheet.dart';

class ActivityLaunchChoice {
  final String activityId;
  final GamePlayMode mode;
  final bool autoJoinVoice;

  const ActivityLaunchChoice({
    required this.activityId,
    required this.mode,
    required this.autoJoinVoice,
  });
}

class ActivityItem {
  final String id;
  final String title;
  final String description;
  final String playerRange;
  final String duration;
  final IconData icon;
  final Color accentColor;
  final String tag;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.playerRange,
    required this.duration,
    required this.icon,
    required this.accentColor,
    required this.tag,
  });
}

class ActivityLauncherSheet extends StatelessWidget {
  final ValueChanged<ActivityLaunchChoice> onSelectActivity;

  const ActivityLauncherSheet({super.key, required this.onSelectActivity});

  static const List<ActivityItem> activities = [
    ActivityItem(
      id: 'twenty_nine',
      title: '29 (Twenty-Nine)',
      description:
          'Classic Indian trick-taking card game. Bidding, hidden trump, and intense 2v2 teamwork.',
      playerRange: '4 Players (2v2)',
      duration: '15-20 min',
      icon: Icons.style_rounded,
      accentColor: AddaColors.coral,
      tag: 'POPULAR',
    ),
    ActivityItem(
      id: 'teen_patti',
      title: 'Teen Patti Royale',
      description:
          'Traditional Indian 3-card poker. Chaal, Blind bets, and high stakes psychological showdowns.',
      playerRange: '2-6 Players',
      duration: '10 min',
      icon: Icons.diamond_rounded,
      accentColor: AddaColors.amber,
      tag: 'CARDS',
    ),
    ActivityItem(
      id: 'rummy',
      title: 'Indian Rummy (13 Cards)',
      description:
          'Classic 13-card rummy. Pure sequences, sets, wild jokers, and smart declarations.',
      playerRange: '2-6 Players',
      duration: '12 min',
      icon: Icons.view_carousel_rounded,
      accentColor: AddaColors.cyan,
      tag: 'CARDS',
    ),
    ActivityItem(
      id: 'uno',
      title: 'UNO Clash',
      description:
          'Fast-paced color and number matching. Skip, reverse, draw 4, and shout UNO!',
      playerRange: '2-6 Players',
      duration: '10 min',
      icon: Icons.filter_none_rounded,
      accentColor: AddaColors.amber,
      tag: 'PARTY',
    ),
    ActivityItem(
      id: 'bluff',
      title: 'Bluff Masters',
      description:
          'Original deception game. Play cards face down, declare rank, and call bluffs.',
      playerRange: '3-6 Players',
      duration: '10-15 min',
      icon: Icons.psychology_alt_rounded,
      accentColor: AddaColors.rose,
      tag: 'BLUFF',
    ),
    ActivityItem(
      id: 'mafia',
      title: 'Mafia / Werewolf',
      description:
          'Social deduction thriller. Night killings, doctor heals, detective clues, and heated town hall trials.',
      playerRange: '4-12 Players',
      duration: '15 min',
      icon: Icons.masks_rounded,
      accentColor: AddaColors.rose,
      tag: 'DEDUCTION',
    ),
    ActivityItem(
      id: 'draw_guess',
      title: 'Draw & Guess',
      description:
          'Real-time collaborative whiteboard. One sketches secret prompts, others race to guess.',
      playerRange: '2-8 Players',
      duration: '8 min',
      icon: Icons.palette_rounded,
      accentColor: AddaColors.emerald,
      tag: 'CREATIVE',
    ),
    ActivityItem(
      id: 'quiz_clash',
      title: 'Quiz Clash',
      description:
          'Trivia showdown covering Cinema, Cricket, and Culture with rapid speed bonuses.',
      playerRange: '1-8 Players',
      duration: '6 min',
      icon: Icons.quiz_rounded,
      accentColor: AddaColors.violet,
      tag: 'TRIVIA',
    ),
    ActivityItem(
      id: 'couple_mode',
      title: 'Couple Sanctuary',
      description:
          'Intimate questions, memory sync, and compatibility meter designed for two.',
      playerRange: '2 Players',
      duration: '10 min',
      icon: Icons.favorite_rounded,
      accentColor: AddaColors.rose,
      tag: 'COUPLE',
    ),
    ActivityItem(
      id: 'watch_together',
      title: 'Watch & Listen Together',
      description:
          'Sub-second synchronized music and video jukebox. Party playlists and shared vibes.',
      playerRange: '1-16 Players',
      duration: 'Ongoing',
      icon: Icons.headset_rounded,
      accentColor: AddaColors.cyan,
      tag: 'MEDIA',
    ),
    ActivityItem(
      id: 'brain_arena',
      title: 'Brain Arena',
      description:
          'Speed math, memory matrix, pattern recognition, and rapid deduction rounds.',
      playerRange: '1-8 Players',
      duration: '5 min',
      icon: Icons.bolt_rounded,
      accentColor: AddaColors.violet,
      tag: 'BRAIN',
    ),
    ActivityItem(
      id: 'coop_puzzle',
      title: 'Mystery Case: The Safe',
      description:
          'Asymmetric co-op puzzle. Different clues on every screen — talk over voice to crack the code.',
      playerRange: '2-4 Players',
      duration: '8 min',
      icon: Icons.lock_open_rounded,
      accentColor: AddaColors.cyan,
      tag: 'CO-OP',
    ),
  ];

  static Future<ActivityLaunchChoice?> show(BuildContext context) {
    return showModalBottomSheet<ActivityLaunchChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActivityLauncherSheet(
        onSelectActivity: (choice) => Navigator.of(ctx).pop(choice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(AddaSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddaRadius.xl),
        ),
        border: Border.all(
          color: isDark
              ? AddaColors.borderLuminousDark
              : AddaColors.borderLuminousLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AddaColors.borderLuminousDark
                    : AddaColors.borderLuminousLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AddaSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.sports_esports_rounded,
                color: AddaColors.coral,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Room Activities',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an activity to play together. Voice stays live uninterrupted.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AddaSpacing.lg),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return SurfaceCard(
                  onTap: () async {
                    final modeResult = await GameModeSheet.show(context, item);
                    if (modeResult != null) {
                      onSelectActivity(
                        ActivityLaunchChoice(
                          activityId: item.id,
                          mode: modeResult.mode,
                          autoJoinVoice: modeResult.autoJoinVoice,
                        ),
                      );
                    }
                  },
                  margin: const EdgeInsets.only(bottom: AddaSpacing.md),
                  padding: const EdgeInsets.all(AddaSpacing.md),
                  borderColor: item.accentColor.withAlpha(50),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: item.accentColor.withAlpha(25),
                          borderRadius: AddaRadius.radiusMd,
                          border: Border.all(
                            color: item.accentColor.withAlpha(80),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.accentColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AddaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withAlpha(30),
                                    borderRadius: AddaRadius.radiusXs,
                                  ),
                                  child: Text(
                                    item.tag,
                                    style: TextStyle(
                                      color: item.accentColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AddaColors.textSecondaryDark
                                    : AddaColors.textSecondaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_alt_outlined,
                                  size: 12,
                                  color: isDark
                                      ? AddaColors.textMutedDark
                                      : AddaColors.textMutedLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.playerRange,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AddaColors.textMutedDark
                                        : AddaColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: isDark
                                      ? AddaColors.textMutedDark
                                      : AddaColors.textMutedLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.duration,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AddaColors.textMutedDark
                                        : AddaColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AddaColors.coral,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
