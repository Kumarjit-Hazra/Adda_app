import '../domain/models/chat_conversation.dart';
import '../domain/models/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatConversation>> getConversations();
  Future<List<ChatMessage>> getMessages(String conversationId);
  Future<ChatMessage> sendMessage(String conversationId, ChatMessage message);
  Future<void> markAsRead(String conversationId);
  Stream<List<ChatConversation>> watchConversations();
  Stream<List<ChatMessage>> watchMessages(String conversationId);
}
