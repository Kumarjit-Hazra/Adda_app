import 'dart:async';
import '../domain/models/chat_conversation.dart';
import '../domain/models/chat_message.dart';
import '../domain/enums/message_status.dart';
import 'chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  final Map<String, ChatConversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};

  final _conversationsController =
      StreamController<List<ChatConversation>>.broadcast();
  final Map<String, StreamController<List<ChatMessage>>> _messagesControllers =
      {};

  InMemoryChatRepository() {
    // Seed initial data for testing/preview
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _conversations['thread_1'] = ChatConversation(
      id: 'thread_1',
      title: 'Chai Pe Charcha',
      isGroup: true,
      updatedAt: now.subtract(const Duration(minutes: 2)),
      unreadCount: 2,
    );
    _messages['thread_1'] = [
      ChatMessage(
        id: 'msg_1',
        senderId: 'user_2',
        senderName: 'Rahul',
        content: 'Anyone up for 29 Cards tonight?',
        timestamp: now.subtract(const Duration(minutes: 2)),
        status: MessageStatus.sent,
      ),
    ];
    _emitConversations();
  }

  void _emitConversations() {
    _conversationsController.add(
      _conversations.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  void _emitMessages(String conversationId) {
    _messagesControllers[conversationId]?.add(_messages[conversationId] ?? []);
  }

  @override
  Future<List<ChatConversation>> getConversations() async {
    return _conversations.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return _messages[conversationId] ?? [];
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // simulate network delay

    final sentMessage = message.copyWith(status: MessageStatus.sent);
    final msgs = _messages[conversationId] ?? [];

    // Replace the optimistic "sending" message if it exists, otherwise add it
    final index = msgs.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      msgs[index] = sentMessage;
    } else {
      msgs.add(sentMessage);
    }
    _messages[conversationId] = msgs;

    final conv = _conversations[conversationId];
    if (conv != null) {
      _conversations[conversationId] = conv.copyWith(
        lastMessage: sentMessage,
        updatedAt: sentMessage.timestamp,
      );
      _emitConversations();
    }

    _emitMessages(conversationId);
    return sentMessage;
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    final conv = _conversations[conversationId];
    if (conv != null && conv.unreadCount > 0) {
      _conversations[conversationId] = conv.copyWith(unreadCount: 0);
      _emitConversations();
    }
  }

  @override
  Stream<List<ChatConversation>> watchConversations() {
    return _conversationsController.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (!_messagesControllers.containsKey(conversationId)) {
      _messagesControllers[conversationId] =
          StreamController<List<ChatMessage>>.broadcast();
    }
    return _messagesControllers[conversationId]!.stream;
  }

  void dispose() {
    _conversationsController.close();
    for (var controller in _messagesControllers.values) {
      controller.close();
    }
  }
}
