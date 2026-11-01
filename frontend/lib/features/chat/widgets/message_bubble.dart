import 'package:flutter/material.dart';

import '../../../core/models/conversation.dart';
import 'attachment_preview.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          ],
        ),
      ),
    );
  }
}
