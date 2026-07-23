import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/queue_fab.dart';
import '../../widgets/sort_dialog.dart';
import '../../widgets/queue_dialog.dart';
import '../../core/natsuyume_core.dart';
import 'context_menus/queue_context_menu.dart';
import 'context_menus/queue_multiselect_menu.dart';
import 'metadata_editor_screen.dart';

class QueueTrack {
  final String path;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final ImageProvider? albumArt;

  const QueueTrack({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.albumArt,
  });

  static QueueTrack fromCoreTrack(CoreTrack t) {
    final ms = t.durationMs;
    final totalSec = ms ~/ 1000;
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    final duration = '$minutes:${seconds.toString().padLeft(2, '0')}';
    return QueueTrack(
      path: t.path,
      title: t.title.isEmpty ? 'Unknown Title' : t.title,
      artist: t.artist.isEmpty ? 'Unknown Artist' : t.artist,
      album: t.album.isEmpty ? 'Unknown Album' : t.album,
      duration: duration,
    );
  }
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _currentTrackIndex = -1;
  int _currentQueueIndex = 0;
  bool _isSelecting = false;
  final Set<int> _selectedIndices = {};

  List<String> _queueNames = ['Queue A'];
  List<QueueTrack> _tracks = [];

  @override
  void initState() {
    super.initState();
    _refreshTracks();
    NatsuyumeCore.instance.playerState.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    NatsuyumeCore.instance.playerState.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    _refreshTracks();
  }

  void _refreshTracks() {
    final core = NatsuyumeCore.instance;
    final coreTracks = core.getQueueTracks();
    final currentPath = core.playerState.currentTrack.path;

    setState(() {
      _tracks = coreTracks.map(QueueTrack.fromCoreTrack).toList();
      _currentTrackIndex = coreTracks.indexWhere((t) => t.path == currentPath);
    });
  }

  String get _totalDuration {
    final totalMs = _tracks.fold<int>(0, (sum, t) {
      final parts = t.duration.split(':');
      if (parts.length != 2) return sum;
      final min = int.tryParse(parts[0]) ?? 0;
      final sec = int.tryParse(parts[1]) ?? 0;
      return sum + min * 60000 + sec * 1000;
    });
    final totalSec = totalMs ~/ 1000;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _enterSelectMode(int index) {
    setState(() {
      _isSelecting = true;
      _selectedIndices.add(index);
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _isSelecting = false;
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelecting = false;
      _selectedIndices.clear();
    });
  }

  void _showMultiSelectMenu() {
    final selected = _selectedIndices
        .map(
          (i) => TrackMetadata(
            title: _tracks[i].title,
            artist: _tracks[i].artist,
            album: _tracks[i].album,
          ),
        )
        .toList();

    QueueMultiselectMenu.show(
      context,
      count: _selectedIndices.length,
      tracks: selected,
      onRemoveFromQueue: () {
        setState(() {
          final sorted = _selectedIndices.toList()
            ..sort((a, b) => b.compareTo(a));
          for (final i in sorted) {
            _tracks.removeAt(i);
          }
          _exitSelectMode();
        });
      },
      onPlayAfterCurrent: () => _exitSelectMode(),
      onAddToQueue: () => _exitSelectMode(),
      onAddToPlaylists: () => _exitSelectMode(),
      onAddToFavorites: () => _exitSelectMode(),
      onRemoveFromFavorites: () => _exitSelectMode(),
    );
  }

  void _showQueueSelector() {
    QueueDialog.show(
      context,
      queues: _queueNames
          .asMap()
          .entries
          .map(
            (e) => QueueItem(
              name: e.value,
              isPlaying: e.key == _currentQueueIndex,
            ),
          )
          .toList(),
      onQueueSelected: (index) => setState(() => _currentQueueIndex = index),
      onQueueRenamed: (index) {},
      onQueueDeleted: (index) {
        setState(() {
          _queueNames.removeAt(index);
          if (_currentQueueIndex >= _queueNames.length) {
            _currentQueueIndex = _queueNames.length - 1;
          }
        });
      },
      onReordered: (reordered) {
        setState(() => _queueNames = reordered.map((q) => q.name).toList());
      },
    );
  }

  void _showTrackMenu(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    QueueContextMenu.show(
      context,
      trackName: _tracks[index].title,
      isFavorite: false,
      onFavoriteTap: () {},
      onSongInfo: () {},
      onRemoveFromQueue: () {
        setState(() {
          if (_tracks.length > 1) {
            _tracks.removeAt(index);
          }
        });
      },
      onPlayAfterCurrent: () {},
      onAddToQueue: () {},
      onAddToPlaylists: () {},
      onStopAfterThis: () {},
    );
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
              child: _tracks.isEmpty
                  ? _buildEmptyState(colors)
                  : Stack(
                      children: [
                        _buildTrackList(colors),
                        if (!_isSelecting)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: QueueFab(
                              actions: [
                                QueueFabAction(
                                  icon: Icons.checklist,
                                  label: 'Select multiple',
                                  onTap: () =>
                                      setState(() => _isSelecting = true),
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
            if (_isSelecting) _buildMultiSelectBar(colors),
            _buildQueueInfoBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(NatsuyumeColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_music, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No tracks in queue',
            style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
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
          _TopBarButton(icon: Icons.play_arrow, colors: colors, onTap: () {}),
          const SizedBox(width: 8),
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
        final isSelected = _selectedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            if (_isSelecting) {
              _toggleSelection(index);
            } else {
              setState(() => _currentTrackIndex = index);
            }
          },
          onLongPress: () => _enterSelectMode(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.2)
                  : isPlaying
                  ? colors.accent.withValues(alpha: 0.15)
                  : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: colors.accent, width: 1.5)
                  : isPlaying
                  ? Border.all(
                      color: colors.accent.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (_isSelecting)
                  SizedBox(
                    width: 32,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(index),
                      activeColor: colors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                else
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
                          child: isPlaying && !_isSelecting
                              ? _EqualizerIcon(color: colors.accent)
                              : Icon(
                                  Icons.music_note,
                                  color: colors.onSurfaceVariant,
                                  size: 24,
                                ),
                        ),
                ),
                const SizedBox(width: 12),
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
                if (!_isSelecting) ...[
                  Text(
                    track.duration,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showTrackMenu(context, index, colors),
                    child: Icon(
                      Icons.more_vert,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectBar(NatsuyumeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colors.surface,
      child: Row(
        children: [
          GestureDetector(
            onTap: _exitSelectMode,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, color: colors.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_selectedIndices.length} selected',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showMultiSelectMenu,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.more_vert, color: colors.background, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueInfoBar(NatsuyumeColorScheme colors) {
    final trackDisplay = _tracks.isEmpty
        ? '0 / 0'
        : '${(_currentTrackIndex + 1).clamp(1, _tracks.length)} / ${_tracks.length}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: colors.surface,
      child: Text(
        '$trackDisplay    $_totalDuration',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
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
