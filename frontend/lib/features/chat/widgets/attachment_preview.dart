import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/models/conversation.dart';

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({super.key, required this.attachment});
  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    if (a.isImage) {
      Widget img;
      if (kIsWeb || a.path.startsWith('http') || a.path.startsWith('blob:')) {
        img = Image.network(
          a.path,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } else {
        img = Image.file(
          File(a.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: img);
    }
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(a.isVideo ? Icons.videocam : Icons.insert_drive_file, size: 32),
          const SizedBox(height: 4),
          Text(
            a.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    width: 120,
    height: 120,
    color: Colors.grey.shade300,
    child: const Icon(Icons.broken_image),
  );
}
