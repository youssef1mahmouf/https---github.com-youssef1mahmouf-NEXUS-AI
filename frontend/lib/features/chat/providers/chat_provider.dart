import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus_ai/core/models/conversation.dart';
import 'package:nexus_ai/core/services/api_service.dart';
import 'package:nexus_ai/core/services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({required StorageService storage, ChatApiService? apiService})
      : _storage = storage,
        _api = apiService;

  final StorageService _storage;
  final ChatApiService? _api;
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  String? _activeId;
  String? _error;
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _streamingMessageId;
  bool _streamCancelled = false;

  Future<void> load() async {
    final convs = await _storage.loadConversations();
    final id = await _storage.loadActiveConversationId();
    _conversations = List<Conversation>.from(convs);
    if (_conversations.isNotEmpty) {
      final matched = _conversations.firstWhere(
        (conversation) => conversation.id == id,
        orElse: () => _conversations.reduce(
          (latest, conversation) =>
              conversation.updatedAt.isAfter(latest.updatedAt)
              ? conversation
              : latest,
        ),
      );
      _activeConversation = matched;
      _activeId = matched.id;
    } else {
      _activeConversation = null;
      _activeId = null;
    }
    notifyListeners();
  }

  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String? get streamingMessageId => _streamingMessageId;

  Future<Conversation> createConversation() async {
    final now = DateTime.now();
    final title = 'New Conversation ${_conversations.length + 1}';
    final conversation = Conversation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    _conversations.add(conversation);
    _activeConversation = conversation;
    _activeId = conversation.id;
    await _storage.saveConversations(_conversations);
    await _storage.saveActiveConversationId(_activeId);
    notifyListeners();
    return conversation;
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final updated = _conversations[idx].copyWith(title: newTitle);
      _conversations[idx] = updated;
      await _storage.saveConversations(_conversations);
      if (_activeConversation?.id == id) {
        _activeConversation = updated;
      }
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String id) async {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _conversations.removeAt(idx);
      if (_activeConversation?.id == id) {
        if (_conversations.isNotEmpty) {
          final next = _conversations.last;
          _activeConversation = next;
          _activeId = next.id;
        } else {
          _activeConversation = null;
          _activeId = null;
        }
      }
      await _storage.saveActiveConversationId(_activeId);
      await _storage.saveConversations(_conversations);
      notifyListeners();
    }
  }

  void selectConversation(String id) {
    if (!_conversations.any((c) => c.id == id)) return;
    _activeConversation = _conversations.firstWhere((c) => c.id == id);
    _activeId = id;
    _storage.saveActiveConversationId(_activeId);
    notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    List<Attachment> attachments = const [],
    bool stream = true,
  }) async {
    // Block concurrent operations: never start a new send while loading or
    // streaming. This prevents duplicate/overlapping assistant messages.
    if (_isLoading || _isStreaming) return;
    final conv = _activeConversation;
    if (conv == null || (text.trim().isEmpty && attachments.isEmpty)) {
      _error = conv == null ? 'No active conversation' : 'Message is empty';
      notifyListeners();
      return;
    }
    _error = null;
    final conversationId = conv.id;
    final msg = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: conversationId,
      content: text,
      isUser: true,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    final previousMessages = List<Message>.from(conv.messages);
    final updatedConv = conv.copyWith(
      messages: [...conv.messages, msg],
      updatedAt: DateTime.now(),
    );
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx >= 0) _conversations[idx] = updatedConv;
    if (_activeConversation?.id == conversationId) {
      _activeConversation = updatedConv;
    }
    await _storage.saveConversations(_conversations);
    notifyListeners();

    if (_api == null) return;

    if (stream) {
      return _sendMessageStream(
        text: text,
        conversationId: conversationId,
        previousMessages: previousMessages,
      );
    }

    _isLoading = true;
    notifyListeners();
    try {
      final history = previousMessages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();
      final reply = await _api.chat(
        message: text,
        conversationId: conversationId,
        history: history,
      );
      final targetIdx = _conversations.indexWhere((c) => c.id == conversationId);
      if (targetIdx < 0) return;
      final target = _conversations[targetIdx];
      final assistantMsg = Message(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: conversationId,
        content: reply,
        isUser: false,
        createdAt: DateTime.now(),
      );
      final withReply = target.copyWith(
        messages: [...target.messages, assistantMsg],
        updatedAt: DateTime.now(),
      );
      _conversations[targetIdx] = withReply;
      if (_activeConversation?.id == conversationId) {
        _activeConversation = withReply;
      }
      await _storage.saveConversations(_conversations);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Streams the assistant reply progressively into an assistant message
  /// placeholder, updating the UI chunk by chunk. On completion the message is
  /// persisted; on error the partial content is retained and [_error] is set.
  /// Cancellation is honored via [_streamCancelled], set by [cancelStream].
  Future<void> _sendMessageStream({
    required String text,
    required String conversationId,
    required List<Message> previousMessages,
  }) async {
    // Nullable API service: tests instantiate ChatProvider without one.
    // Fail closed with a controlled error instead of a runtime crash.
    if (_api == null) {
      _error = 'No API service available';
      _isStreaming = false;
      _streamingMessageId = null;
      notifyListeners();
      return;
    }

    _isStreaming = true;
    _streamCancelled = false;
    notifyListeners();

    // Create a placeholder assistant message so the UI can show progressive
    // streaming content immediately.
    final placeholderId = DateTime.now().microsecondsSinceEpoch.toString();
    _streamingMessageId = placeholderId;
    final placeholder = Message(
      id: placeholderId,
      conversationId: conversationId,
      content: '',
      isUser: false,
      createdAt: DateTime.now(),
    );
    final targetIdx = _conversations.indexWhere((c) => c.id == conversationId);
    if (targetIdx < 0) {
      _isStreaming = false;
      _streamingMessageId = null;
      notifyListeners();
      return;
    }
    final target = _conversations[targetIdx];
    final withPlaceholder = target.copyWith(
      messages: [...target.messages, placeholder],
      updatedAt: DateTime.now(),
    );
    _conversations[targetIdx] = withPlaceholder;
    if (_activeConversation?.id == conversationId) {
      _activeConversation = withPlaceholder;
    }
    await _storage.saveConversations(_conversations);
    notifyListeners();

    try {
      final history = previousMessages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();
      await for (final chunk in _api.chatStream(
        message: text,
        conversationId: conversationId,
        history: history,
      )) {
        if (_streamCancelled) break;
        final curIdx = _conversations.indexWhere((c) => c.id == conversationId);
        if (curIdx < 0) break;
        final cur = _conversations[curIdx];
        final msgIdx = cur.messages.indexWhere((m) => m.id == placeholderId);
        if (msgIdx < 0) break;
        final streamingMsg = cur.messages[msgIdx];
        final updated = streamingMsg.copyWith(
          content: streamingMsg.content + chunk,
          createdAt: DateTime.now(),
        );
        final updatedMsgs = List<Message>.from(cur.messages)
          ..[msgIdx] = updated;
        final updatedConv = cur.copyWith(
          messages: updatedMsgs,
          updatedAt: DateTime.now(),
        );
        _conversations[curIdx] = updatedConv;
        if (_activeConversation?.id == conversationId) {
          _activeConversation = updatedConv;
        }
        notifyListeners();
      }
    } catch (e) {
      // Retain partial content; surface the error so the UI can show it.
      _error = e.toString();
    } finally {
      _isStreaming = false;
      _streamingMessageId = null;
      _streamCancelled = false;
      await _storage.saveConversations(_conversations);
      notifyListeners();
    }
  }

  /// Cancels an in-progress stream. The next loop iteration stops and the
  /// partial assistant message is retained.
  Future<void> cancelStream() async {
    _streamCancelled = true;
  }

  Future<void> resendMessage(Message message) async {
    if (_activeConversation == null) return;
    final msg = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: _activeConversation!.id,
      content: message.content,
      isUser: message.isUser,
      createdAt: DateTime.now(),
      attachments: message.attachments,
    );
    _activeConversation = _activeConversation!.copyWith(
      messages: [..._activeConversation!.messages, msg],
      updatedAt: DateTime.now(),
    );
    await _persistActiveConversation();
    notifyListeners();
  }

  Future<void> editAndResend(Message message, String newText) async {
    if (_activeConversation == null || newText.trim().isEmpty) return;
    final idx = _activeConversation!.messages.indexWhere(
      (m) => m.id == message.id,
    );
    if (idx >= 0) {
      final updatedMsg = Message(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: _activeConversation!.id,
        content: newText,
        isUser: message.isUser,
        createdAt: DateTime.now(),
        attachments: message.attachments,
        sources: message.sources,
        isEdited: true,
      );
      _activeConversation = _activeConversation!.copyWith(
        messages: List<Message>.from(_activeConversation!.messages)
          ..add(updatedMsg),
        updatedAt: DateTime.now(),
      );
      await _persistActiveConversation();
      notifyListeners();
    }
  }

  Future<void> _persistActiveConversation() async {
    final conversation = _activeConversation;
    if (conversation != null) {
      final index = _conversations.indexWhere(
        (item) => item.id == conversation.id,
      );
      if (index >= 0) _conversations[index] = conversation;
    }
    await _storage.saveConversations(_conversations);
  }
}
