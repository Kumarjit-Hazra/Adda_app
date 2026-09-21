import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/enums/message_status.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AddaColors.surfaceVariantDark
                : AddaColors.surfaceVariantLight,
            borderRadius: AddaRadius.radiusSm,
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AddaColors.textMutedDark : AddaColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final timeStr = DateFormat('h:mm a').format(message.timestamp);
    final isFailed = message.status == MessageStatus.failed;
    final isSending = message.status == MessageStatus.sending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AppAvatar(
              name: message.senderName,
              size: 28,
              isOnline: false, // Could integrate presence later
            ),
            const SizedBox(width: 6),
          ],
          if (isMe && isFailed)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AddaColors.coral, size: 20),
              onPressed: onRetry,
              tooltip: 'Retry',
            ),
          Flexible(
            child: Opacity(
              opacity: isSending ? 0.7 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isFailed 
                      ? AddaColors.coral.withValues(alpha: 0.2 * 255)
                      : isMe
                          ? AddaColors.coral
                          : (isDark
                              ? AddaColors.surfaceVariantDark
                              : AddaColors.surfaceVariantLight),
                  border: isFailed ? Border.all(color: AddaColors.coral) : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AddaRadius.lg),
                    topRight: const Radius.circular(AddaRadius.lg),
                    bottomLeft: Radius.circular(
                      isMe ? AddaRadius.lg : AddaRadius.xs,
                    ),
                    bottomRight: Radius.circular(
                      isMe ? AddaRadius.xs : AddaRadius.lg,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AddaColors.amber,
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe && !isFailed
                            ? Colors.white
                            : (isDark
                                ? AddaColors.textPrimaryDark
                                : AddaColors.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe && !isFailed
                                ? Colors.white70
                                : (isDark
                                    ? AddaColors.textMutedDark
                                    : AddaColors.textMutedLight),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isFailed ? Icons.error_outline :
                            isSending ? Icons.access_time : Icons.check,
                            size: 10,
                            color: isFailed ? AddaColors.coral : (isMe ? Colors.white70 : Colors.black54),
                          )
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
