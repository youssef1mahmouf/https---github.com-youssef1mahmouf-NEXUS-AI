import 'package:flutter/material.dart';
import 'package:nexus_ai/core/models/conversation.dart';
import 'package:nexus_ai/core/services/storage_service.dart';

/// Provider managing chat conversations and message state.
/// Extends ChangeNotifier so widget trees can listen for changes via Provider.
class ChatProvider extends ChangeNotifier {
  /// Creates a [ChatProvider] with the given [storage] for persistence.
  ChatProvider({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  /// Internal list of conversations loaded from storage.
  List<Conversation> _conversations = [];

  /// The currently active conversation, if any.
  Conversation? _activeConversation;

  /// The ID of the currently active conversation, or null.
  String? _activeId;

  /// Error message from the last failed operation, or null if none.
  String? _error;

  /// Load conversations and active ID from storage.
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

  /// All conversations persisted for the user.
  List<Conversation> get conversations => _conversations;

  /// The currently active conversation, or null if none.
  Conversation? get activeConversation => _activeConversation;

  /// Error message from the last failed operation, or null if none.
  String? get error => _error;

  /// Creates a new conversation with a generated title and makes it active.
  Conversation createConversation() {
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
    _storage.saveConversations(_conversations);
    _storage.saveActiveConversationId(_activeId);
    notifyListeners();
    return conversation;
  }

  /// Renames the conversation with the given [id] to [newTitle].
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

  /// Deletes the conversation with the given [id].
  Future<void> deleteConversation(String id) async {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _conversations.removeAt(idx);
      if (_activeConversation?.id == id) {
        _activeConversation = _conversations.firstOrNull;
        _activeId = _activeConversation?.id;
      }
      await _storage.saveConversations(_conversations);
      await _storage.saveActiveConversationId(_activeId);
      notifyListeners();
    }
  }

  /// Selects the conversation with the given [id] as the active one.
  Future<void> selectConversation(String id) async {
    if (_conversations.isNotEmpty) {
      final conv = _conversations.firstWhere(
        (conversation) => conversation.id == id,
        orElse: () => _conversations.first,
      );
      _activeConversation = conv;
      _activeId = conv.id;
    } else {
      _activeConversation = null;
      _activeId = null;
    }
    await _storage.saveActiveConversationId(_activeId);
    notifyListeners();
  }

  /// Sends a [text] message with optional [attachments] to the active conversation.
  Future<void> sendMessage(
    String text, {
    List<Attachment> attachments = const [],
  }) async {
    if (_activeConversation == null ||
        (text.trim().isEmpty && attachments.isEmpty)) {
      // Only set error if we don't already have a meaningful error; this prevents
      // a stale error from blocking subsequent sends when the user later creates
      // a new conversation.
      _error ??= _activeConversation == null
          ? 'No active conversation'
          : 'Message is empty';
      notifyListeners();
      return;
    }
    // Clear any previous error once we confirm there's an active conversation
    // and the text/attachments are valid.
    _error = null;
    final msg = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: _activeConversation!.id,
      content: text,
      isUser: true,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    _activeConversation = _activeConversation!.copyWith(
      messages: [..._activeConversation!.messages, msg],
      updatedAt: DateTime.now(),
    );
    await _persistActiveConversation();
    notifyListeners();
  }

  /// Resends the given [message] as a new message in the active conversation.
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

  /// Edits the [message] content to [newText] and resends it as a new message.
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
