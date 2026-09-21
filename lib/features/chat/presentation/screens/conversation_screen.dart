import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../application/chat_providers.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';

class ConversationScreen extends ConsumerWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final chatService = ref.read(chatServiceProvider);

    // Mark as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatService.markAsRead(conversationId);
    });

    return AppScaffold(
      appBar: AddaTopBar(
        contextTitle: 'Chat',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse:
                      true, // Typically chats have newest at bottom, but we are appending.
                  // If we use append, we should NOT reverse unless we reverse the data list.
                  // For now, let's keep it simple: normal order, and jump to bottom.
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final authValue = ref.watch(authProvider).value;
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == authValue?.id,
                      onRetry: () =>
                          chatService.retryMessage(conversationId, message),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Error loading messages: $e')),
            ),
          ),
          ChatComposer(
            onSend: (text) => chatService.sendMessage(conversationId, text),
          ),
        ],
      ),
    );
  }
}
