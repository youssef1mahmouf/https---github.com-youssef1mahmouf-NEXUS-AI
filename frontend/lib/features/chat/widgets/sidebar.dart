import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/conversation.dart';
import '../providers/chat_provider.dart';

class ConversationSidebar extends StatelessWidget {
  const ConversationSidebar({super.key});
  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF7C3AED), const Color(0xFF4F46E5)]
                      : [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () => chat.newChat(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
      ),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  const _ConversationTile({required this.conversation, required this.active});
  final Conversation conversation;
  final bool active;
  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: widget.active
              ? scheme.primary.withValues(alpha: isDark ? 0.25 : 0.18)
              : _hover
              ? (isDark ? Colors.white : scheme.primary).withValues(
                  alpha: isDark ? 0.06 : 0.06,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.active
                ? scheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
          boxShadow: widget.active
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ListTile(
          dense: true,
          title: Text(
            widget.conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          subtitle: Text(
            '${widget.conversation.messages.length} messages',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          onTap: () => chat.selectConversation(widget.conversation.id),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final ctrl = TextEditingController(
                  text: widget.conversation.title,
                );
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
                  await chat.renameConversation(
                    widget.conversation.id,
                    res.trim(),
                  );
                }
              } else if (v == 'delete') {
                await chat.deleteConversation(widget.conversation.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}
