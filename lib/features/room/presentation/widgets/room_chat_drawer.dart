import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';
import '../../../chat/domain/models/chat_message.dart';

class RoomChatDrawer extends StatefulWidget {
  final List<ChatMessage> messages;
  final String localUserId;
  final ValueChanged<String> onSendMessage;

  const RoomChatDrawer({
    super.key,
    required this.messages,
    required this.localUserId,
    required this.onSendMessage,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ChatMessage> messages,
    required String localUserId,
    required ValueChanged<String> onSendMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoomChatDrawer(
        messages: messages,
        localUserId: localUserId,
        onSendMessage: onSendMessage,
      ),
    );
  }

  @override
  State<RoomChatDrawer> createState() => _RoomChatDrawerState();
}

class _RoomChatDrawerState extends State<RoomChatDrawer> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: bottomInset),
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
        children: [
          const SizedBox(height: AddaSpacing.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AddaColors.borderLuminousDark
                  : AddaColors.borderLuminousLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AddaSpacing.lg,
              vertical: AddaSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: AddaColors.coral,
                ),
                const SizedBox(width: 8),
                Text(
                  'In-Room Chat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AddaSpacing.md),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.messages[index];
                final isMe = msg.senderId == widget.localUserId;

                if (msg.isSystem) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AddaColors.surfaceVariantDark
                            : AddaColors.surfaceVariantLight,
                        borderRadius: AddaRadius.radiusSm,
                      ),
                      child: Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AddaColors.textMutedDark
                              : AddaColors.textMutedLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final timeStr = DateFormat('h:mm a').format(msg.timestamp);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        AppAvatar(
                          name: msg.senderName,
                          size: 28,
                          isOnline: false,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AddaColors.coral
                                : (isDark
                                      ? AddaColors.surfaceVariantDark
                                      : AddaColors.surfaceVariantLight),
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
                                  msg.senderName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AddaColors.amber,
                                  ),
                                ),
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe
                                      ? Colors.white
                                      : (isDark
                                            ? AddaColors.textPrimaryDark
                                            : AddaColors.textPrimaryLight),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70
                                      : (isDark
                                            ? AddaColors.textMutedDark
                                            : AddaColors.textMutedLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AddaSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AddaColors.borderDark
                      : AddaColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: isDark
                          ? AddaColors.surfaceVariantDark
                          : AddaColors.surfaceVariantLight,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: AddaRadius.radiusFull,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AddaColors.coral,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
