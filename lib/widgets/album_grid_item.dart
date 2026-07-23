import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../theme/natsuyume_theme.dart';
import '../core/library_types.dart';
import '../core/cover_service.dart';

class AlbumGridItem extends StatefulWidget {
  final AlbumData album;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AlbumGridItem({
    super.key,
    required this.album,
    required this.isPlaying,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AlbumGridItem> createState() => _AlbumGridItemState();
}

class _AlbumGridItemState extends State<AlbumGridItem> {
  late Future<Uint8List?> _coverFuture;

  @override
  void initState() {
    super.initState();
    _coverFuture = CoverService.instance.getCoverForAlbumAsync(
      widget.album.title,
    );
  }

  @override
  void didUpdateWidget(AlbumGridItem old) {
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
        decoration: BoxDecoration(
          color: widget.isPlaying
              ? colors.accent.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: widget.isPlaying
              ? Border.all(
                  color: colors.accent.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: FutureBuilder<Uint8List?>(
                  future: _coverFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image(
                        image: MemoryImage(snapshot.data!),
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.album,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
