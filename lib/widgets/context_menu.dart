import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class ContextMenuOption {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const ContextMenuOption({
    this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

class ContextMenuSheet extends StatelessWidget {
  final Widget header;
  final List<ContextMenuOption> options;

  const ContextMenuSheet({
    super.key,
    required this.header,
    required this.options,
  });

  static Future<void> show(
    BuildContext context, {
    required Widget header,
    required List<ContextMenuOption> options,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ContextMenuSheet(header: header, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: header,
              ),
              Divider(height: 1, color: colors.divider),
              // Options
              ...options.map(
                (option) => _ContextMenuTile(
                  option: option,
                  colors: colors,
                  onTap: () {
                    Navigator.of(context).pop();
                    option.onTap();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextMenuTile extends StatelessWidget {
  final ContextMenuOption option;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ContextMenuTile({
    required this.option,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = option.isDestructive ? Colors.red : colors.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, size: 20, color: color),
              const SizedBox(width: 14),
            ],
            Text(option.label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}

// Shared header widgets used across context menus
class TrackContextHeader extends StatelessWidget {
  final String trackName;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const TrackContextHeader({
    super.key,
    required this.trackName,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Row(
      children: [
        Expanded(
          child: Text(
            trackName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onFavoriteTap,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? colors.accent : colors.onSurfaceVariant,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class MultiSelectContextHeader extends StatelessWidget {
  final int count;

  const MultiSelectContextHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Text(
      'Options for $count song${count == 1 ? '' : 's'}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
  }
}

class CollectionContextHeader extends StatelessWidget {
  final String name;
  final String? subtitle;

  const CollectionContextHeader({super.key, required this.name, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
