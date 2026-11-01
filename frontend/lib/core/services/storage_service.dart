import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation.dart';

abstract class StorageService {
  Future<List<Conversation>> loadConversations();
  Future<void> saveConversations(List<Conversation> conversations);
}

class SharedPreferencesStorageService implements StorageService {
  SharedPreferencesStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'nexus_conversations_v1';

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
}
