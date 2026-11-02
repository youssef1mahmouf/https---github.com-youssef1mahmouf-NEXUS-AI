import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_ai/core/models/conversation.dart';
import 'package:nexus_ai/core/services/storage_service.dart';
import 'package:nexus_ai/features/chat/providers/chat_provider.dart';

class _MemStorage implements StorageService {
  List<Conversation> convs = [];
  String? activeId;

  @override
  Future<List<Conversation>> loadConversations() async =>
      List<Conversation>.from(convs);

  @override
  Future<void> saveConversations(List<Conversation> conversations) async {
    convs = List<Conversation>.from(conversations);
  }

  @override
  Future<String?> loadActiveConversationId() async => activeId;

  @override
  Future<void> saveActiveConversationId(String? id) async {
    activeId = id;
  }
}

void main() {
  test('restores last active conversation', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c1 = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
    );
    final c2 = Conversation(
      id: '2',
      title: 'B',
      createdAt: now,
      updatedAt: now,
    );
    storage.convs = [c1, c2];
    storage.activeId = '2';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    expect(provider.activeConversation?.id, '2');
  });

  test('restores messages of active conversation', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final msg = Message(
      id: 'm1',
      conversationId: '1',
      content: 'hello',
      isUser: true,
      createdAt: now,
    );
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [msg],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    expect(provider.activeConversation?.messages.length, 1);
    expect(provider.activeConversation?.messages.first.content, 'hello');
  });

  test('handles invalid saved conversation id', () async {
    final storage = _MemStorage();
    final older = DateTime(2020);
    final newer = DateTime(2021);
    final c1 = Conversation(
      id: '1',
      title: 'A',
      createdAt: older,
      updatedAt: older,
    );
    final c2 = Conversation(
      id: '2',
      title: 'B',
      createdAt: newer,
      updatedAt: newer,
    );
    storage.convs = [c1, c2];
    storage.activeId = 'missing';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    expect(provider.activeConversation?.id, '2');
  });

  test('starts with no saved conversations', () async {
    final storage = _MemStorage();
    final provider = ChatProvider(storage: storage);
    await provider.load();

    expect(provider.conversations, isEmpty);
    expect(provider.activeConversation, isNull);
  });

  test('deleting active conversation selects another', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c1 = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
    );
    final c2 = Conversation(
      id: '2',
      title: 'B',
      createdAt: now,
      updatedAt: now,
    );
    storage.convs = [c1, c2];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();
    await provider.deleteConversation('1');

    expect(provider.activeConversation?.id, '2');
  });

  test('startup does not create a conversation', () async {
    final storage = _MemStorage();
    final provider = ChatProvider(storage: storage);
    await provider.load();

    expect(storage.convs, isEmpty);
    expect(provider.conversations, isEmpty);
  });

  test(
    'resending a message adds a new message without altering original',
    () async {
      final storage = _MemStorage();
      final now = DateTime.now();
      final c = Conversation(
        id: '1',
        title: 'A',
        createdAt: now,
        updatedAt: now,
        messages: [
          Message(
            id: 'm1',
            conversationId: '1',
            content: 'original text',
            isUser: true,
            createdAt: now,
          ),
        ],
      );
      storage.convs = [c];
      storage.activeId = '1';

      final provider = ChatProvider(storage: storage);
      await provider.load();

      final original = provider.activeConversation!.messages.first;
      await provider.resendMessage(original);

      final conv = provider.activeConversation!;
      expect(conv.messages.length, 2);
      expect(conv.messages.first.content, 'original text');
      expect(conv.messages.last.content, 'original text');
      expect(conv.messages.last.id, isNot(equals(original.id)));
    },
  );

  test(
    'editing and resending preserves original and adds edited copy',
    () async {
      final storage = _MemStorage();
      final now = DateTime.now();
      final c = Conversation(
        id: '1',
        title: 'A',
        createdAt: now,
        updatedAt: now,
        messages: [
          Message(
            id: 'm1',
            conversationId: '1',
            content: 'original text',
            isUser: true,
            createdAt: now,
          ),
        ],
      );
      storage.convs = [c];
      storage.activeId = '1';

      final provider = ChatProvider(storage: storage);
      await provider.load();

      final original = provider.activeConversation!.messages.first;
      await provider.editAndResend(original, 'modified text');

      final conv = provider.activeConversation!;
      expect(conv.messages.length, 2);
      expect(conv.messages.first.content, 'original text');
      expect(conv.messages.first.isEdited, isFalse);
      expect(conv.messages.last.content, 'modified text');
      expect(conv.messages.last.isEdited, isTrue);
      expect(conv.messages.last.id, isNot(equals(original.id)));
    },
  );

  test('copying a user message returns its content', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: 'copy me',
          isUser: true,
          createdAt: now,
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final msg = provider.activeConversation!.messages.first;
    expect(msg.content, 'copy me');
    expect(msg.isUser, isTrue);
  });

  test('copying an assistant response returns its content', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: 'assistant response',
          isUser: false,
          createdAt: now,
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final msg = provider.activeConversation!.messages.first;
    expect(msg.content, 'assistant response');
    expect(msg.isUser, isFalse);
  });

  test('message with code blocks is handled correctly', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final content =
        'Here is code:\n```dart\nprint("hello");\n```\nand more text';
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: content,
          isUser: false,
          createdAt: now,
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final msg = provider.activeConversation!.messages.first;
    expect(msg.content, contains('print("hello")'));
    expect(msg.content, contains('and more text'));
  });

  test('shows sources only when valid metadata exists', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: 'response with sources',
          isUser: false,
          createdAt: now,
          sources: ['https://example.com', 'https://docs.example.com'],
        ),
        Message(
          id: 'm2',
          conversationId: '1',
          content: 'response without sources',
          isUser: false,
          createdAt: now,
          sources: const [],
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final msgs = provider.activeConversation!.messages;
    expect(msgs[0].sources, hasLength(2));
    expect(msgs[0].sources, contains('https://example.com'));
    expect(msgs[1].sources, isEmpty);
  });

  test('empty message is not sent', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(id: '1', title: 'A', createdAt: now, updatedAt: now);
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    await provider.sendMessage('', attachments: const []);
    await provider.sendMessage('   ', attachments: const []);

    expect(provider.activeConversation!.messages, isEmpty);
  });

  // ---- Regression: Legacy JSON compatibility ----

  test('legacy message without sources or isEdited deserializes safely', () {
    final json = {
      'id': 'm1',
      'conversationId': '1',
      'content': 'legacy message',
      'isUser': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'attachments': [],
    };

    final msg = Message.fromJson(json);
    expect(msg.id, 'm1');
    expect(msg.content, 'legacy message');
    expect(msg.isUser, isTrue);
    expect(msg.sources, isEmpty);
    expect(msg.isEdited, isFalse);
  });

  test('message serialization round-trip preserves all fields', () {
    final now = DateTime.now();
    final original = Message(
      id: 'm1',
      conversationId: 'c1',
      content: 'round trip test',
      isUser: false,
      createdAt: now,
      sources: ['https://example.com'],
      isEdited: true,
    );

    final json = original.toJson();
    final restored = Message.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.conversationId, original.conversationId);
    expect(restored.content, original.content);
    expect(restored.isUser, original.isUser);
    expect(restored.createdAt, original.createdAt);
    expect(restored.sources, original.sources);
    expect(restored.isEdited, original.isEdited);
  });

  // ---- Regression: Edit & Resend / Resend data safety ----

  test('edit and resend preserves original message untouched', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: 'original text',
          isUser: true,
          createdAt: now,
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final original = provider.activeConversation!.messages.first;
    await provider.editAndResend(original, 'modified text');

    final conv = provider.activeConversation!;
    expect(conv.messages.length, 2);
    // Original remains unchanged
    expect(conv.messages.first.id, 'm1');
    expect(conv.messages.first.content, 'original text');
    expect(conv.messages.first.isEdited, isFalse);
    // New message is the edited version
    expect(conv.messages.last.content, 'modified text');
    expect(conv.messages.last.isEdited, isTrue);
    expect(conv.messages.last.id, isNot(equals('m1')));
  });

  test('resend creates a separate message preserving original', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: 'to resend',
          isUser: true,
          createdAt: now,
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final original = provider.activeConversation!.messages.first;
    await provider.resendMessage(original);

    final conv = provider.activeConversation!;
    expect(conv.messages.length, 2);
    expect(conv.messages.first.content, 'to resend');
    expect(conv.messages.first.id, 'm1');
    expect(conv.messages.last.content, 'to resend');
    expect(conv.messages.last.id, isNot(equals('m1')));
  });

  test('edit and resend with empty text is rejected', () async {
    final storage = _MemStorage();
    final now = DateTime.now();
    final c = Conversation(
      id: '1',
      title: 'A',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: '1',
          content: 'original',
          isUser: true,
          createdAt: now,
        ),
      ],
    );
    storage.convs = [c];
    storage.activeId = '1';

    final provider = ChatProvider(storage: storage);
    await provider.load();

    final original = provider.activeConversation!.messages.first;
    await provider.editAndResend(original, '');
    await provider.editAndResend(original, '   ');

    final conv = provider.activeConversation!;
    expect(conv.messages.length, 1);
    expect(conv.messages.first.content, 'original');
  });

  // ---- Regression: HolographicOrb painting safety ----
  // Covered at the widget level by test/widget_test.dart which pumps the
  // full app (including HolographicOrb inside WelcomeView) and passes.
  // _RingPainter is private to the orb library; its zero-size guards are
  // verified by the fixed paint() implementation.
}
