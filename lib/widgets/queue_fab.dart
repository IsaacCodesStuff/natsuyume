import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class QueueFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QueueFabAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class QueueFab extends StatefulWidget {
  final List<QueueFabAction> actions;

  const QueueFab({super.key, required this.actions});

  @override
  State<QueueFab> createState() => _QueueFabState();
}

class _QueueFabState extends State<QueueFab> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _collapse() => setState(() => _expanded = false);

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action chips
        if (_expanded) ...[
          ...widget.actions.reversed.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  _collapse();
                  action.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.icon, size: 18, color: colors.onSurface),
                      const SizedBox(width: 10),
                      Text(
                        action.label,
                        style: TextStyle(fontSize: 14, color: colors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
        // Main FAB toggle button
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _expanded ? colors.accent : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _expanded ? Icons.close : Icons.menu,
              color: _expanded ? colors.background : colors.onSurface,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
