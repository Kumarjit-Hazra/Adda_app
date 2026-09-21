import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../domain/models/chat_conversation.dart';
import 'package:go_router/go_router.dart';

class ConversationTile extends StatelessWidget {
  final ChatConversation conversation;

  const ConversationTile({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = conversation.unreadCount;
    final hasInvite = conversation.gameInviteId != null;

    // Formatting timestamp - simplified for now
    final timeStr =
        "${conversation.updatedAt.hour}:${conversation.updatedAt.minute.toString().padLeft(2, '0')}";

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        context.push('/chat/${conversation.id}');
      },
      child: Row(
        children: [
          AppAvatar(
            name: conversation.title,
            size: 46,
            isOnline:
                false, // Could integrate presence later based on participants
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AddaColors.textMutedDark
                            : AddaColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hasInvite) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AddaColors.amber.withAlpha(40),
                          borderRadius: AddaRadius.radiusXs,
                        ),
                        child: Text(
                          '🎮 Invite',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AddaColors.amber,
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        conversation.lastMessage?.content ?? 'No messages yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: unread > 0
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                    ? AddaColors.textSecondaryDark
                                    : AddaColors.textSecondaryLight),
                          fontWeight: unread > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AddaColors.coral,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
