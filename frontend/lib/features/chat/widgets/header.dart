import 'package:flutter/material.dart';

import '../../../core/theme/theme_provider.dart';

/// Standalone application header with branding and sidebar toggle buttons.
/// Placed above the workspace, visually separate from the main content.
class NexusHeader extends StatelessWidget {
  const NexusHeader({
    super.key,
    required this.onPagesSidebarToggle,
    required this.onConversationsSidebarToggle,
  });

  final VoidCallback onPagesSidebarToggle;
  final VoidCallback onConversationsSidebarToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: isDark
          ? const Color(0xFF1a1a2e)
          : const Color(0xFFf8f9fa),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Branding
          const Text(
            'Nexus AI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),

          const Spacer(),

          // Pages Sidebar toggle
          Tooltip(
            message: 'Toggle pages sidebar',
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
              onPressed: onPagesSidebarToggle,
            ),
          ),

          // Conversations Sidebar toggle
          Tooltip(
            message: 'Toggle conversations sidebar',
            child: IconButton(
              icon: Icon(
                Icons.chat,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
              onPressed: onConversationsSidebarToggle,
            ),
          ),
        ],
      ),
    );
  }
}