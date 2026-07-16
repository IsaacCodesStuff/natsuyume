import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

enum LibraryLayout { grid, list }

class LibraryTopBar extends StatelessWidget {
  final String searchHint;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final LibraryLayout currentLayout;
  final ValueChanged<LibraryLayout> onLayoutChanged;
  final VoidCallback onMoreTap;

  const LibraryTopBar({
    super.key,
    required this.searchHint,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.currentLayout,
    required this.onLayoutChanged,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: TextStyle(fontSize: 14, color: colors.onSurface),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // List toggle
          _ToggleButton(
            icon: Icons.list,
            selected: currentLayout == LibraryLayout.list,
            colors: colors,
            onTap: () => onLayoutChanged(LibraryLayout.list),
          ),
          const SizedBox(width: 6),
          // Grid toggle
          _ToggleButton(
            icon: Icons.grid_view,
            selected: currentLayout == LibraryLayout.grid,
            colors: colors,
            onTap: () => onLayoutChanged(LibraryLayout.grid),
          ),
          const SizedBox(width: 6),
          // More
          _ToggleButton(
            icon: Icons.more_vert,
            selected: false,
            colors: colors,
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? colors.accent.withOpacity(0.2) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: colors.accent.withOpacity(0.4))
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? colors.accent : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
