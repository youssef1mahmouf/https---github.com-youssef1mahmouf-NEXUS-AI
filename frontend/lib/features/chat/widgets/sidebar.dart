import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/conversation.dart';
import '../providers/chat_provider.dart';

class ConversationSidebar extends StatelessWidget {
  const ConversationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => chat.newChat(),
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: chat.conversations.length,
              itemBuilder: (context, i) {
                final c = chat.conversations[i];
                final active = c.id == chat.activeConversation?.id;
                return _ConversationTile(conversation: c, active: active);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.active});
  final Conversation conversation;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${conversation.messages.length} messages',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        onTap: () => chat.selectConversation(conversation.id),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'rename') {
              final ctrl = TextEditingController(text: conversation.title);
              final res = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Rename conversation'),
                  content: TextField(controller: ctrl, autofocus: true),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (res != null && res.trim().isNotEmpty) {
                await chat.renameConversation(conversation.id, res.trim());
              }
            } else if (v == 'delete') {
              await chat.deleteConversation(conversation.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
