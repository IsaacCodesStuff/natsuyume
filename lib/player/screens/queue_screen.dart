import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/queue_fab.dart';
import '../../widgets/sort_dialog.dart';

class QueueTrack {
  final String title;
  final String artist;
  final String album;
  final String duration;
  final ImageProvider? albumArt;

  const QueueTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.albumArt,
  });
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _currentTrackIndex = 1;
  int _currentQueueIndex = 0;

  final List<String> _queueNames = ['Queue A', 'Queue B', 'Queue C'];

  // Placeholder tracks
  final List<QueueTrack> _tracks = const [
    QueueTrack(
      title: 'Calling Blue (overture)',
      artist: 'Turquoise',
      album: '水瀬いのり',
      duration: '1:11',
    ),
    QueueTrack(
      title: 'Turquoise',
      artist: 'Turquoise',
      album: '水瀬いのり',
      duration: '3:32',
    ),
    QueueTrack(
      title: '八月のスーベニア',
      artist: 'glow',
      album: '水瀬いのり',
      duration: '5:11',
    ),
    QueueTrack(title: '夏夢', artist: 'アイマイモコ', album: '水瀬いのり', duration: '4:59'),
  ];

  String get _totalDuration {
    // Placeholder — will be computed from real track data in 0.8.x
    return '14:55';
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
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  _buildTrackList(colors),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: QueueFab(
                      actions: [
                        QueueFabAction(
                          icon: Icons.checklist,
                          label: 'Select multiple',
                          onTap: () {},
                        ),
                        QueueFabAction(
                          icon: Icons.file_upload_outlined,
                          label: 'Export as .M3U',
                          onTap: () {},
                        ),
                        QueueFabAction(
                          icon: Icons.share_outlined,
                          label: 'Share songs',
                          onTap: () {},
                        ),
                        QueueFabAction(
                          icon: Icons.save_outlined,
                          label: 'Save as playlist',
                          onTap: () {},
                        ),
                        QueueFabAction(
                          icon: Icons.sort,
                          label: 'Sort',
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => TrackSortDialog(
                              selectedField: TrackSortField.title,
                              direction: SortDirection.ascending,
                              specialOptions: [
                                SpecialTrackSort.randomize,
                                SpecialTrackSort.reverse,
                                SpecialTrackSort.mostPlayedFirst,
                                SpecialTrackSort.leastPlayedFirst,
                              ],
                              onNormalChanged: (field, direction) {},
                              onSpecialChanged: (special) {},
                            ),
                          ),
                        ),
                        QueueFabAction(
                          icon: Icons.add,
                          label: 'Add song',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildQueueInfoBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Queue selector dropdown
          Expanded(
            child: GestureDetector(
              onTap: _showQueueSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_currentQueueIndex + 1}. ${_queueNames[_currentQueueIndex]}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Play button
          _TopBarButton(icon: Icons.play_arrow, colors: colors, onTap: () {}),
          const SizedBox(width: 8),
          // Close/delete button
          _TopBarButton(icon: Icons.close, colors: colors, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildTrackList(NatsuyumeColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        final isPlaying = index == _currentTrackIndex;

        return GestureDetector(
          onTap: () => setState(() => _currentTrackIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isPlaying
                  ? colors.accent.withOpacity(0.15)
                  : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isPlaying
                  ? Border.all(color: colors.accent.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Drag handle + index
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: colors.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: track.albumArt != null
                      ? Image(
                          image: track.albumArt!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: colors.surfaceVariant,
                          child: isPlaying
                              ? _EqualizerIcon(color: colors.accent)
                              : Icon(
                                  Icons.music_note,
                                  color: colors.onSurfaceVariant,
                                  size: 24,
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
                          color: isPlaying ? colors.accent : colors.onSurface,
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
                // Duration
                Text(
                  track.duration,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                // More menu
                GestureDetector(
                  onTap: () => _showTrackMenu(context, index, colors),
                  child: Icon(
                    Icons.more_vert,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueInfoBar(NatsuyumeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: colors.surface,
      child: Text(
        '${_currentTrackIndex + 1} / ${_tracks.length}    $_totalDuration',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
      ),
    );
  }

  void _showQueueSelector() {
    final colors = NatsuyumeTheme.of(context).colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount: _queueNames.length,
        itemBuilder: (_, index) => ListTile(
          title: Text(
            '${index + 1}. ${_queueNames[index]}',
            style: TextStyle(color: colors.onSurface),
          ),
          trailing: index == _currentQueueIndex
              ? Icon(Icons.check, color: colors.accent)
              : null,
          onTap: () {
            setState(() => _currentQueueIndex = index);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showTrackMenu(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.play_arrow, color: colors.onSurface),
            title: Text('Play next', style: TextStyle(color: colors.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colors.onSurface),
            title: Text(
              'Remove from queue',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () {
              setState(
                () => _tracks.length > 1
                    ? (_tracks as List).removeAt(index)
                    : null,
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.save_outlined, color: colors.onSurface),
            title: Text(
              'Save to playlist',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: colors.onSurface),
            title: Text(
              'Track info',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.onSurface, size: 22),
      ),
    );
  }
}

class _EqualizerIcon extends StatelessWidget {
  final Color color;

  const _EqualizerIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(height: 10, color: color),
        const SizedBox(width: 2),
        _Bar(height: 18, color: color),
        const SizedBox(width: 2),
        _Bar(height: 14, color: color),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;

  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
