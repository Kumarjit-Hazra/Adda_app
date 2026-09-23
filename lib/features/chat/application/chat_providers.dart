import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../data/in_memory_chat_repository.dart';
import '../domain/models/chat_conversation.dart';
import '../domain/models/chat_message.dart';
import '../domain/enums/message_status.dart';
import 'package:uuid/uuid.dart';
import '../../auth/presentation/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repo = InMemoryChatRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final conversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  // Fetch initial immediately
  repo.getConversations();
  return repo.watchConversations();
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) {
  final repo = ref.watch(chatRepositoryProvider);
  repo.getMessages(conversationId);
  return repo.watchMessages(conversationId);
});

class ChatService {
  final Ref ref;
  final ChatRepository repository;
  final Uuid _uuid = const Uuid();

  ChatService(this.ref, this.repository);

  Future<void> sendMessage(String conversationId, String content) async {
    final userValue = ref.read(authProvider).value;
    if (userValue == null) return;

    final tempMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: userValue.id,
      senderName: userValue.name,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    try {
      await repository.sendMessage(conversationId, tempMessage);
    } catch (e) {
      // Handle failure (not fully implemented in InMemoryChatRepository, but mockable)
      // The repository would ideally keep it in `failed` state.
    }
  }

  Future<void> retryMessage(String conversationId, ChatMessage message) async {
    final retryMsg = message.copyWith(
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    await repository.sendMessage(conversationId, retryMsg);
  }

  Future<void> markAsRead(String conversationId) async {
    await repository.markAsRead(conversationId);
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref, ref.watch(chatRepositoryProvider));
});
