import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/playlist_track_list.dart';

class PlaylistOrganizerScreen extends StatefulWidget {
  final String playlistName;
  final List<PlaylistTrack> tracks;

  const PlaylistOrganizerScreen({
    super.key,
    required this.playlistName,
    required this.tracks,
  });

  @override
  State<PlaylistOrganizerScreen> createState() =>
      _PlaylistOrganizerScreenState();
}

class _PlaylistOrganizerScreenState extends State<PlaylistOrganizerScreen> {
  late List<PlaylistTrack> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = List.from(widget.tracks);
  }

  void _save() {
    // Wired to UserDataManager in 0.8.x
    Navigator.of(context).pop(_tracks);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _tracks.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _tracks.removeAt(oldIndex);
                    _tracks.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  return _OrganizerTrackRow(
                    key: ValueKey('${track.title}_$index'),
                    index: index,
                    track: track,
                    colors: colors,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organize songs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  widget.playlistName,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: colors.accent,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizerTrackRow extends StatelessWidget {
  final int index;
  final PlaylistTrack track;
  final NatsuyumeColorScheme colors;

  const _OrganizerTrackRow({
    super.key,
    required this.index,
    required this.track,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: track.albumArt != null
                ? Image(
                    image: track.albumArt!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: colors.surfaceVariant,
                    child: Icon(
                      Icons.music_note,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.album,
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
          // Drag handle
          Icon(Icons.drag_handle, color: colors.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }
}
