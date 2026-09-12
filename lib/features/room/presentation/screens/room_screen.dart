import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/reaction.dart';
import '../providers/room_provider.dart';
import '../widgets/activity_launcher_sheet.dart';
import '../widgets/participant_strip.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/room_chat_drawer.dart';
import '../widgets/room_controls_bar.dart';
import '../../../games/twenty_nine/twenty_nine_view.dart';
import '../../../games/uno/uno_view.dart';
import '../../../games/bluff/bluff_view.dart';
import '../../../games/brain_arena/brain_arena_view.dart';
import '../../../games/coop_puzzle/coop_puzzle_view.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String spaceName;

  const RoomScreen({super.key, required this.spaceId, required this.spaceName});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  bool _showReactions = false;
  final List<RoomReaction> _floatingReactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final room = ref.read(roomProvider);
      if (room == null || room.spaceId != widget.spaceId) {
        ref
            .read(roomProvider.notifier)
            .joinRoom(spaceId: widget.spaceId, spaceName: widget.spaceName);
      }
    });
  }

  void _triggerFloatingReaction(RoomReaction reaction) {
    setState(() => _floatingReactions.add(reaction));
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _floatingReactions.remove(reaction));
      }
    });
  }

  void _handleCopyInvite(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticsService.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Space code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AddaColors.surfaceElevatedDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (room == null) {
      return AppScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AddaColors.coral),
              const SizedBox(height: AddaSpacing.md),
              Text(
                'Connecting to ${widget.spaceName}...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final localUserId = user?.id ?? '';
    final localParticipant = room.participants.firstWhere(
      (p) => p.id == localUserId,
      orElse: () => room.participants.first,
    );

    return AppScaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Top Room Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AddaSpacing.lg,
                  vertical: AddaSpacing.sm,
                ),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24,
                      ),
                      size: 38,
                      onPressed: () => context.pop(),
                      tooltip: 'Minimize Room',
                    ),
                    const SizedBox(width: AddaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                room.spaceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AddaColors.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${room.participants.length} connected in voice',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AddaColors.textMutedDark
                                  : AddaColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton.ghost(
                      text: 'Invite',
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 16,
                        color: AddaColors.coral,
                      ),
                      onPressed: () =>
                          _handleCopyInvite(widget.spaceId.toUpperCase()),
                    ),
                  ],
                ),
              ),

              // Persistent Participant Strip
              Padding(
                padding: const EdgeInsets.only(
                  left: AddaSpacing.lg,
                  right: AddaSpacing.lg,
                  bottom: AddaSpacing.sm,
                ),
                child: ParticipantStrip(
                  participants: room.participants,
                  localUserId: localUserId,
                ),
              ),

              const Divider(),

              // Main Activity Area or Lounge
              Expanded(
                child: room.activeActivityId != null
                    ? _buildActiveActivityView(room.activeActivityId!)
                    : _buildLoungeView(context, room, isDark),
              ),

              // Bottom Spacer so content isn't obstructed by the floating controls
              const SizedBox(height: 74),
            ],
          ),

          // Floating Reactions Overlay
          ..._floatingReactions.map(
            (r) => Positioned(
              bottom: 120,
              right: 40,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: (1.0 - value).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -value * 220),
                      child: Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Reaction Picker Popup
          if (_showReactions)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: ReactionPicker(
                  onSelectEmoji: (emoji) {
                    setState(() => _showReactions = false);
                    ref.read(roomProvider.notifier).sendReaction(emoji);
                    _triggerFloatingReaction(
                      RoomReaction(
                        id: UniqueKey().toString(),
                        senderId: localUserId,
                        senderName: user?.name ?? '',
                        emoji: emoji,
                        timestamp: DateTime.now(),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Floating Controls Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Center(
              child: RoomControlsBar(
                isMuted: localParticipant.isMuted,
                isVideoEnabled: localParticipant.isVideoEnabled,
                unreadChatCount: 0,
                onToggleMic: () => ref.read(roomProvider.notifier).toggleMic(),
                onToggleCamera: () =>
                    ref.read(roomProvider.notifier).toggleCamera(),
                onOpenChat: () {
                  RoomChatDrawer.show(
                    context,
                    messages: room.chatMessages,
                    localUserId: localUserId,
                    onSendMessage: (msg) =>
                        ref.read(roomProvider.notifier).sendChatMessage(msg),
                  );
                },
                onOpenActivities: () async {
                  final chosen = await ActivityLauncherSheet.show(context);
                  if (chosen != null) {
                    ref.read(roomProvider.notifier).setActiveActivity(chosen);
                  }
                },
                onOpenReactions: () {
                  setState(() => _showReactions = !_showReactions);
                },
                onLeaveRoom: () async {
                  await ref.read(roomProvider.notifier).leaveRoom();
                  if (context.mounted) {
                    context.pop();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoungeView(BuildContext context, dynamic room, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(AddaSpacing.xl),
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1E2638), Color(0xFF141926)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFEFF3FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AddaColors.coral.withAlpha(30),
                        borderRadius: AddaRadius.radiusMd,
                      ),
                      child: const Text('☕️', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: AddaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room is Live & Connected',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'High-fidelity WebRTC voice channel is open. Everyone can hear you clearly.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AddaColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AddaSpacing.lg),
                const Divider(),
                const SizedBox(height: AddaSpacing.md),
                Text(
                  'What would you like to do?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AddaSpacing.md),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickActivityChip(
                      label: 'Play 29 🃏',
                      color: AddaColors.coral,
                      onTap: () => ref
                          .read(roomProvider.notifier)
                          .setActiveActivity('twenty_nine'),
                    ),
                    _QuickActivityChip(
                      label: 'Play UNO 🌈',
                      color: AddaColors.amber,
                      onTap: () => ref
                          .read(roomProvider.notifier)
                          .setActiveActivity('uno'),
                    ),
                    _QuickActivityChip(
                      label: 'Play Bluff 🎭',
                      color: AddaColors.rose,
                      onTap: () => ref
                          .read(roomProvider.notifier)
                          .setActiveActivity('bluff'),
                    ),
                    _QuickActivityChip(
                      label: 'Brain Arena ⚡️',
                      color: AddaColors.violet,
                      onTap: () => ref
                          .read(roomProvider.notifier)
                          .setActiveActivity('brain_arena'),
                    ),
                    _QuickActivityChip(
                      label: 'Co-op Mystery 🧩',
                      color: AddaColors.cyan,
                      onTap: () => ref
                          .read(roomProvider.notifier)
                          .setActiveActivity('coop_puzzle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveActivityView(String activityId) {
    return Stack(
      children: [
        Positioned.fill(
          child: switch (activityId) {
            'twenty_nine' => const TwentyNineView(),
            'uno' => const UnoView(),
            'bluff' => const BluffView(),
            'brain_arena' => const BrainArenaView(),
            'coop_puzzle' => const CoopPuzzleView(),
            _ => Center(child: Text('Unknown Activity: $activityId')),
          },
        ),
        Positioned(
          top: 8,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: AddaRadius.radiusFull,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Close Activity to Lounge',
              onPressed: () =>
                  ref.read(roomProvider.notifier).setActiveActivity(null),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActivityChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActivityChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticsService.lightTap();
        onTap();
      },
      borderRadius: AddaRadius.radiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: AddaRadius.radiusMd,
          border: Border.all(color: color.withAlpha(80), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
