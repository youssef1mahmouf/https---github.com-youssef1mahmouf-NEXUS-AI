import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation.dart';

abstract class StorageService {
  Future<List<Conversation>> loadConversations();
  Future<void> saveConversations(List<Conversation> conversations);
  Future<String?> loadActiveConversationId();
  Future<void> saveActiveConversationId(String? id);
}

class SharedPreferencesStorageService implements StorageService {
  SharedPreferencesStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'nexus_conversations_v1';
  static const _activeKey = 'nexus_active_conversation_id_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<List<Conversation>> loadConversations() async {
    final prefs = await _instance;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return decodeConversations(raw);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await _instance;
    await prefs.setString(_key, encodeConversations(conversations));
  }

  @override
  Future<String?> loadActiveConversationId() async {
    final prefs = await _instance;
    try {
      return prefs.getString(_activeKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveConversationId(String? id) async {
    final prefs = await _instance;
    if (id == null || id.isEmpty) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
  }
}
