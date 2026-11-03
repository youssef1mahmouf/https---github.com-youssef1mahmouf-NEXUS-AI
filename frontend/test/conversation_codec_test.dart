import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_ai/core/models/conversation.dart';

void main() {
  test('encode/decode conversations round-trips', () {
    final now = DateTime(2024, 2, 3, 4, 5, 6);
    final conv = Conversation(
      id: 'c1',
      title: 'Title',
      createdAt: now,
      updatedAt: now,
      messages: [
        Message(
          id: 'm1',
          conversationId: 'c1',
          content: 'hi',
          isUser: false,
          createdAt: now,
          attachments: const [
            Attachment(id: 'a1', name: 'f.png', path: '/tmp/f.png', type: AttachmentType.image, size: 10),
          ],
          sources: const ['src'],
          isEdited: true,
        ),
      ],
    );
    final raw = encodeConversations([conv]);
    final decoded = decodeConversations(raw);
    expect(decoded.length, 1);
    final d = decoded.first;
    expect(d.id, 'c1');
    expect(d.title, 'Title');
    expect(d.messages.length, 1);
    final m = d.messages.first;
    expect(m.content, 'hi');
    expect(m.isUser, false);
    expect(m.attachments.length, 1);
    expect(m.attachments.first.type, AttachmentType.image);
    expect(m.sources, ['src']);
    expect(m.isEdited, true);
  });

  test('decodeConversations skips invalid entries', () {
    final raw = '[{"id":"","title":"x"},{"id":"c2","title":"ok","createdAt":"bad","updatedAt":"bad","messages":null}]';
    final decoded = decodeConversations(raw);
    expect(decoded.length, 1);
    expect(decoded.first.id, 'c2');
  });
}
