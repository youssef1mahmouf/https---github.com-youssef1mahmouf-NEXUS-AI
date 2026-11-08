import 'package:flutter/material.dart';

/// Pages Sidebar — far left sidebar supporting page navigation.
/// Supports: Homepage / Chat, Dashboard, Tasks, Settings.
/// Can be shown/hidden independently of the Conversations Sidebar.
class PagesSidebar extends StatelessWidget {
  const PagesSidebar({
    super.key,
  });

  // Page definitions
  static final List<_Page> _pages = [
    _Page(
      id: 'chat',
      label: 'Chat',
      icon: Icons.chat,
      // Route to ChatHomeScreen
    ),
    _Page(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard,
      // Placeholder page
    ),
    _Page(
      id: 'tasks',
      label: 'Tasks',
      icon: Icons.task,
      // Placeholder page
    ),
    _Page(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings,
      // Placeholder page
    ),
  ];

  /// Find a page by its ID.
  static _Page? findPage(String id) {
    for (final page in _pages) {
      if (page.id == id) return page;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 200,
      color: scheme.surface,
      child: Column(
        children: [
          _buildProfileHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return _buildNavigationTile(
                  context,
                  page,
                  isSelected: page.id == findPage('chat')?.id,
                  onSelect: () {
                    // Handle page selection
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Page {
  final String id;
  final String label;
  final IconData icon;
  // The route/navigation target would be defined per implementation
  _Page({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Builds a list of navigation tiles for the Pages Sidebar.
ListTile _buildNavigationTile(
  BuildContext context,
  _Page page, {
  required bool isSelected,
  required VoidCallback onSelect,
}) {
  final scheme = Theme.of(context).colorScheme;

  return ListTile(
    leading: Icon(
      page.icon,
      color: isSelected ? scheme.primary : scheme.onSurface,
    ),
    title: Text(
      page.label,
      style: TextStyle(
        color: isSelected ? scheme.primary : scheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
    tileColor: isSelected
        ? scheme.primary.withValues(alpha: 0.1)
        : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    selected: isSelected,
    onTap: onSelect,
  );
}

/// Expanded header with profile/app info (placeholder).
Widget _buildProfileHeader(BuildContext context) {
  return ListTile(
    title: const Text('Nexus AI'),
    subtitle: const Text('AI Assistant'),
    leading: const CircleAvatar(
      child: Icon(Icons.auto_awesome),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  );
}