import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/conversation.dart';
import '../../../core/services/tts_service.dart';
import '../providers/chat_provider.dart';
import 'attachment_preview.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.tts});
  final Message message;
  final TextToSpeechService? tts;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // State for hover reveal of action buttons
    final hover = ValueNotifier<bool>(false);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 720),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: isDark ? 0.85 : 0.9),
                    scheme.tertiary.withValues(alpha: isDark ? 0.75 : 0.85),
                  ],
                )
              : null,
          color: isUser
              ? null
              : (isDark ? Colors.white : Colors.white).withValues(
                  alpha: isDark ? 0.08 : 0.65,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUser
                ? Colors.white.withValues(alpha: 0.18)
                : scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? scheme.primary : Colors.black).withValues(
                alpha: isUser ? 0.35 : 0.06,
              ),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : scheme.onSurface,
                  height: 1.4,
                ),
              ),
            if (message.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '(edited)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isUser ? Colors.white70 : scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.attachments
                    .map((a) => AttachmentPreview(attachment: a))
                    .toList(),
              ),
            ],
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sources: ${message.sources.join(', ')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isUser ? Colors.white70 : scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _ActionBar(message: message, tts: tts),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.message, this.tts});
  final Message message;
  final TextToSpeechService? tts;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatProvider>();
    final isUser = message.isUser;
    if (isUser) {
      return HoverDetector(
        onHover: (bool isHovering) {
          hover.value = isHovering;
        },
        onLongPress: () {
          // Toggle hover state on long-press for touch devices
          hover.value = !hover.value;
        },
        child: ValueListenableBuilder(
          valueListenable: hover,
          builder: (context, isHovering, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Copy',
                iconSize: 16,
                icon: const Icon(Icons.copy),
                onPressed: () => _copy(context, message.content),
                color: isHovering ? null : Colors.white38,
              ),
              IconButton(
                tooltip: 'Resend',
                iconSize: 16,
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<ChatProvider>().resendMessage(message),
                color: isHovering ? null : Colors.white38,
              ),
              IconButton(
                tooltip: 'Edit & Resend',
                iconSize: 16,
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final controller =
                      TextEditingController(text: message.content);
                  final newText = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Edit message'),
                      content: TextField(
                        controller: controller,
                        maxLines: 5,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, controller.text),
                          child: const Text('Resend'),
                        ),
                      ],
                    ),
                  );
                  if (newText != null && newText.trim().isNotEmpty) {
                    await context.read<ChatProvider>().editAndResend(message, newText);
                  }
                },
                color: isHovering ? null : Colors.white38,
              ),
            ],
          );
        },
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Copy',
          iconSize: 16,
          icon: const Icon(Icons.copy),
          onPressed: () => _copy(context, message.content),
        ),
        IconButton(
          tooltip: 'Copy code',
          iconSize: 16,
          icon: const Icon(Icons.code),
          onPressed: () {
            final code = _extractCode(message.content);
            if (code.isNotEmpty) _copy(context, code);
          },
        ),
        IconButton(
          tooltip: 'Read aloud',
          iconSize: 16,
          icon: const Icon(Icons.volume_up),
          onPressed: () async {
            final ok =
                await (tts?.speak(message.content) ?? Future.value(false));
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Text-to-speech not available')),
              );
            }
          },
        ),
      ],
    );
  }

  String _extractCode(String text) {
    final regex = RegExp(r'```(?:\w*\n)?([\s\S]*?)```');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)?.trim() ?? '').join('\n\n');
  }
}
