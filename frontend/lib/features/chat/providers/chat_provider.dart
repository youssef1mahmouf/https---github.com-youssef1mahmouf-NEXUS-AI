import 'package:flutter/material.dart';

import '../../../core/models/conversation.dart';
import '../../../core/services/storage_service.dart';

// lightweight id gen without uuid dep
String _id() => DateTime.now().microsecondsSinceEpoch.toString();

class ChatProvider extends ChangeNotifier {
  ChatProvider({required StorageService storage}) : _storage = storage;

  final StorageService _storage;
  List<Conversation> _conversations = [];
  String? _activeId;
  bool _loading = false;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _loading;
  Conversation? get activeConversation {
    if (_activeId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _conversations = await _storage.loadConversations();
    if (_conversations.isNotEmpty) _activeId = _conversations.first.id;
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveConversations(_conversations);

  void selectConversation(String id) {
    _activeId = id;
    notifyListeners();
  }

  Future<void> createConversation({String? title}) async {
    final now = DateTime.now();
    final c = Conversation(
      id: _id(),
      title: title ?? 'New Chat',
      createdAt: now,
      updatedAt: now,
    );
    _conversations.insert(0, c);
    _activeId = c.id;
    await _persist();
    notifyListeners();
  }

  String _titleFrom(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'New Chat';
    final first = trimmed.split('\n').first;
    if (first.length <= 40) return first;
    return '${first.substring(0, 40)}…';
  }

  Future<void> sendMessage(
    String text, {
    List<Attachment> attachments = const [],
  }) async {
    if (text.trim().isEmpty && attachments.isEmpty) return;
    if (activeConversation == null) {
      await createConversation(
        title: _titleFrom(
          text.isEmpty
              ? (attachments.isNotEmpty ? attachments.first.name : '')
              : text,
        ),
      );
    }
    final conv = activeConversation!;
    final msg = Message(
      id: _id(),
      conversationId: conv.id,
      content: text,
      isUser: true,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    final updated = conv.copyWith(
      messages: [...conv.messages, msg],
      updatedAt: DateTime.now(),
    );
    _replace(updated);
    await _persist();
    notifyListeners();
  }

  void _replace(Conversation c) {
    final idx = _conversations.indexWhere((x) => x.id == c.id);
    if (idx != -1) _conversations[idx] = c;
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _conversations[idx] = _conversations[idx].copyWith(title: newTitle);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    if (_activeId == id) {
      _activeId = _conversations.isEmpty ? null : _conversations.first.id;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> newChat() async {
    _activeId = null;
    notifyListeners();
  }
}
