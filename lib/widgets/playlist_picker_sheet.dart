import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';
import '../core/natsuyume_core.dart';

/// Shows a bottom sheet listing all playlists.
/// On selection, calls [onTracksAdded] with the number of tracks added.
/// Handles "New playlist" creation inline.
class PlaylistPickerSheet {
  static Future<void> show(
    BuildContext context, {
    required List<String> trackPaths,
  }) async {
    final colors = NatsuyumeTheme.of(context).colors;
    final playlists = NatsuyumeCore.instance.getPlaylists();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlaylistPickerContent(
        trackPaths: trackPaths,
        playlists: playlists,
        colors: colors,
      ),
    );
  }
}

class _PlaylistPickerContent extends StatefulWidget {
  final List<String> trackPaths;
  final List<CorePlaylistData> playlists;
  final NatsuyumeColorScheme colors;

  const _PlaylistPickerContent({
    required this.trackPaths,
    required this.playlists,
    required this.colors,
  });

  @override
  State<_PlaylistPickerContent> createState() => _PlaylistPickerContentState();
}

class _PlaylistPickerContentState extends State<_PlaylistPickerContent> {
  late List<CorePlaylistData> _playlists;

  @override
  void initState() {
    super.initState();
    _playlists = widget.playlists;
  }

  void _addToPlaylist(BuildContext context, CorePlaylistData playlist) {
    int added = 0;
    for (final path in widget.trackPaths) {
      NatsuyumeCore.instance.addTrackToPlaylist(playlist.id, path);
      added++;
    }
    Navigator.of(context).pop();
    _showSnackbar(context, added, playlist.name);
  }

  void _showSnackbar(BuildContext context, int count, String playlistName) {
    final colors = widget.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Added 1 track to "$playlistName"'
              : 'Added $count tracks to "$playlistName"',
          style: TextStyle(color: colors.onSurface),
        ),
        backgroundColor: colors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final colors = widget.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('New playlist', style: TextStyle(color: colors.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.onSurfaceVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
          onSubmitted: (_) => _createAndAdd(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => _createAndAdd(context, controller.text),
            child: Text('Create', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  void _createAndAdd(BuildContext context, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context); // close dialog
    final id = NatsuyumeCore.instance.createPlaylist(trimmed);
    int added = 0;
    for (final path in widget.trackPaths) {
      NatsuyumeCore.instance.addTrackToPlaylist(id, path);
      added++;
    }
    Navigator.of(context).pop(); // close picker sheet
    _showSnackbar(context, added, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Add to playlist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.trackPaths.length} track${widget.trackPaths.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),
              // New playlist option
              GestureDetector(
                onTap: () => _showCreateDialog(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20, color: colors.accent),
                      const SizedBox(width: 14),
                      Text(
                        'New playlist',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_playlists.isNotEmpty)
                Divider(height: 1, color: colors.divider),
              // Existing playlists
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return GestureDetector(
                      onTap: () => _addToPlaylist(context, playlist),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.queue_music,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                playlist.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${playlist.songCount} songs',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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
