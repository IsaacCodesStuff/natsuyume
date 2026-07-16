import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class CollectionDetailBar extends StatelessWidget {
  final String? title;
  final bool showTitle;
  final VoidCallback onBack;
  final VoidCallback onMoreTap;
  final List<Widget>? extraActions;

  const CollectionDetailBar({
    super.key,
    this.title,
    required this.showTitle,
    required this.onBack,
    required this.onMoreTap,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Back button
          _BarButton(icon: Icons.arrow_back, colors: colors, onTap: onBack),
          const SizedBox(width: 8),
          // Title — fades in when cover scrolls away
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showTitle ? 1.0 : 0.0,
              child: title != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          // Extra actions (for artists/playlists)
          if (extraActions != null) ...[
            ...extraActions!,
            const SizedBox(width: 6),
          ],
          // More button
          _BarButton(icon: Icons.more_vert, colors: colors, onTap: onMoreTap),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: colors.onSurface),
      ),
    );
  }
}
