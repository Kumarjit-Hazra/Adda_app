import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';

class RoomControlsBar extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
  final int unreadChatCount;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenReactions;
  final VoidCallback onLeaveRoom;

  const RoomControlsBar({
    super.key,
    required this.isMuted,
    required this.isVideoEnabled,
    this.unreadChatCount = 0,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onOpenChat,
    required this.onOpenActivities,
    required this.onOpenReactions,
    required this.onLeaveRoom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
        borderRadius: AddaRadius.radiusFull,
        border: Border.all(
          color: isDark
              ? AddaColors.borderLuminousDark
              : AddaColors.borderLuminousLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mic Toggle
          AppIconButton(
            icon: Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: isMuted ? Colors.white : AddaColors.emerald,
              size: 20,
            ),
            backgroundColor: isMuted
                ? AddaColors.rose
                : (isDark
                      ? AddaColors.surfaceVariantDark
                      : AddaColors.surfaceVariantLight),
            onPressed: onToggleMic,
            tooltip: isMuted ? 'Unmute Mic' : 'Mute Mic',
          ),
          const SizedBox(width: 8),

          // Camera Toggle
          AppIconButton(
            icon: Icon(
              isVideoEnabled
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              color: isVideoEnabled
                  ? AddaColors.cyan
                  : (isDark
                        ? AddaColors.textMutedDark
                        : AddaColors.textMutedLight),
              size: 20,
            ),
            onPressed: onToggleCamera,
            tooltip: isVideoEnabled ? 'Turn Off Camera' : 'Turn On Camera',
          ),
          const SizedBox(width: 8),

          // Activity Launcher Button (Primary Highlight)
          AppButton(
            text: 'Play',
            icon: const Icon(
              Icons.sports_esports_rounded,
              size: 18,
              color: Colors.white,
            ),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onOpenActivities,
          ),
          const SizedBox(width: 8),

          // Reactions
          AppIconButton(
            icon: const Text('🎉', style: TextStyle(fontSize: 18)),
            onPressed: onOpenReactions,
            tooltip: 'Send Reaction',
          ),
          const SizedBox(width: 8),

          // Chat Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppIconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                onPressed: onOpenChat,
                tooltip: 'Open Chat',
              ),
              if (unreadChatCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AddaColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Leave Room
          AppIconButton(
            icon: const Icon(
              Icons.call_end_rounded,
              color: AddaColors.rose,
              size: 20,
            ),
            backgroundColor: AddaColors.rose.withAlpha(25),
            onPressed: onLeaveRoom,
            tooltip: 'Leave Room',
          ),
        ],
      ),
    );
  }
}
