import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../theme/natsuyume_theme.dart';
import '../core/library_types.dart';
import '../core/cover_service.dart';

class AlbumListItem extends StatefulWidget {
  final AlbumData album;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final VoidCallback? onLongPress;

  const AlbumListItem({
    super.key,
    required this.album,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTap,
    this.onLongPress,
  });

  @override
  State<AlbumListItem> createState() => _AlbumListItemState();
}

class _AlbumListItemState extends State<AlbumListItem> {
  late Future<Uint8List?> _coverFuture;

  @override
  void initState() {
    super.initState();
    _coverFuture = CoverService.instance.getCoverForAlbumAsync(
      widget.album.title,
    );
  }

  @override
  void didUpdateWidget(AlbumListItem old) {
    super.didUpdateWidget(old);
    if (old.album.title != widget.album.title) {
      _coverFuture = CoverService.instance.getCoverForAlbumAsync(
        widget.album.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isPlaying
              ? colors.accent.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: widget.isPlaying
              ? Border.all(
                  color: colors.accent.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<Uint8List?>(
                future: _coverFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image(
                      image: MemoryImage(snapshot.data!),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    width: 52,
                    height: 52,
                    color: colors.surfaceVariant,
                    child: Icon(
                      Icons.album,
                      size: 28,
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.album.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isPlaying
                          ? colors.accent
                          : colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.album.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onMoreTap,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
