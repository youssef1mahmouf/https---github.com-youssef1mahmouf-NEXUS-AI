import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexus_ai/core/models/conversation.dart';
import 'package:nexus_ai/core/services/storage_service.dart';

void main() {
  test('SharedPreferences storage round-trips conversations and active id', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPreferencesStorageService(prefs: prefs);

    final now = DateTime(2024, 1, 1);
    final msg = Message(
      id: 'm1',
      conversationId: 'c1',
      content: 'hello',
      isUser: true,
      createdAt: now,
    );
    final conv = Conversation(
      id: 'c1',
      title: 'Chat',
      createdAt: now,
      updatedAt: now,
      messages: [msg],
    );

    await storage.saveConversations([conv]);
    await storage.saveActiveConversationId('c1');

    final loaded = await storage.loadConversations();
    final active = await storage.loadActiveConversationId();

    expect(loaded.length, 1);
    expect(loaded.first.id, 'c1');
    expect(loaded.first.messages.length, 1);
    expect(loaded.first.messages.first.content, 'hello');
    expect(active, 'c1');
  });

  test('loadConversations returns empty on missing data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPreferencesStorageService(prefs: prefs);
    expect(await storage.loadConversations(), isEmpty);
    expect(await storage.loadActiveConversationId(), isNull);
  });

  test('saveActiveConversationId null removes key', () async {
    SharedPreferences.setMockInitialValues({'nexus_active_conversation_id_v1': 'x'});
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPreferencesStorageService(prefs: prefs);
    await storage.saveActiveConversationId(null);
    expect(await storage.loadActiveConversationId(), isNull);
  });
}
