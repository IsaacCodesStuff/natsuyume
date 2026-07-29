import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/collection_detail_bar.dart';
import '../../widgets/playlist_track_list.dart';
import '../../core/natsuyume_core.dart';
import '../../core/cover_service.dart';
import 'playlists_screen.dart';
import 'playlist_info_overlay.dart';
import 'playlist_editor_screen.dart';
import 'playlist_organizer_screen.dart';
import 'context_menus/playlist_detail_context_menu.dart';
import 'context_menus/playlist_track_context_menu.dart';
import 'context_menus/playlist_track_multiselect_menu.dart';
import 'metadata_editor_screen.dart';
import '../../widgets/floating_mini_player.dart';
import '../../widgets/playlist_picker_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistData playlist;
  final bool isPlaylistPlaying;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.isPlaylistPlaying,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInBar = false;
  int _currentTrackIndex = -1;
  bool _isSelecting = false;
  final Set<int> _selectedIndices = {};
  List<CorePlaylistTrack> _tracks = [];

  static const double _coverThreshold = 260.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTracks();
  }

  void _loadTracks() {
    final tracks = NatsuyumeCore.instance.getPlaylistTracks(widget.playlist.id);
    setState(() => _tracks = tracks);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > _coverThreshold;
    if (shouldShow != _showTitleInBar) {
      setState(() => _showTitleInBar = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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

  void _removeTrackAt(int index) {
    final track = _tracks[index];
    NatsuyumeCore.instance.removeTrackFromPlaylist(
      widget.playlist.id,
      track.path,
    );
    _loadTracks();
  }

  void _removeSelectedTracks() {
    final sorted = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final i in sorted) {
      NatsuyumeCore.instance.removeTrackFromPlaylist(
        widget.playlist.id,
        _tracks[i].path,
      );
    }
    _loadTracks();
    _exitSelectMode();
  }

  void _playPlaylist() {
    if (_tracks.isEmpty) return;
    NatsuyumeCore.instance.openPlaylistInNewQueue(
      widget.playlist.id,
      widget.playlist.name,
    );
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

    PlaylistTrackMultiselectMenu.show(
      context,
      count: _selectedIndices.length,
      tracks: selected,
      onRemoveFromPlaylist: _removeSelectedTracks,
      onPlayAfterCurrent: () => _exitSelectMode(),
      onAddToCurrentQueue: () => _exitSelectMode(),
      onAddToQueue: () => _exitSelectMode(),
      onAddToPlaylists: () {
        final paths = _selectedIndices.map((i) => _tracks[i].path).toList();
        _exitSelectMode();
        PlaylistPickerSheet.show(context, trackPaths: paths);
      },
      onAddToFavorites: () => _exitSelectMode(),
      onRemoveFromFavorites: () => _exitSelectMode(),
      onClearPlaybackHistory: () => _exitSelectMode(),
    );
  }

  String get _totalDuration {
    final totalMs = _tracks.fold(0, (sum, t) => sum + t.durationMs);
    final totalSec = totalMs ~/ 1000;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // Convert CorePlaylistTrack to PlaylistTrack for widgets that expect it
  PlaylistTrack _toWidgetTrack(CorePlaylistTrack t) {
    final coverBytes = CoverService.instance.getCoverForTrack(t.path);
    return PlaylistTrack(
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: t.durationFormatted,
      albumArt: coverBytes != null ? MemoryImage(coverBytes) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
              SliverToBoxAdapter(child: _buildCoverHero(colors)),
              SliverToBoxAdapter(child: _buildPlaylistInfo(colors)),
              _buildTrackList(colors),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CollectionDetailBar(
              title: widget.playlist.name,
              showTitle: _showTitleInBar,
              onBack: () => Navigator.of(context).pop(),
              onMoreTap: () => _showPlaylistMenu(context, colors),
              extraActions: [
                _BarButton(
                  icon: Icons.edit_outlined,
                  colors: colors,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => FractionallySizedBox(
                        heightFactor: 1.0,
                        child: PlaylistEditorScreen(
                          initialName: widget.playlist.name,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_showTitleInBar && !_isSelecting)
            Positioned(
              right: 16,
              bottom: 16,
              child: _buildActionButtons(colors),
            ),
          if (_isSelecting)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMultiSelectBar(colors),
            ),
          const FloatingMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildCoverHero(NatsuyumeColorScheme colors) {
    // Use cover art from first track that has it
    ImageProvider? cover;
    for (final t in _tracks) {
      final bytes = CoverService.instance.getCoverForTrack(t.path);
      if (bytes != null) {
        cover = MemoryImage(bytes);
        break;
      }
    }

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final offset = _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;
        final opacity = (1.0 - (offset / _coverThreshold)).clamp(0.0, 1.0);
        final parallaxOffset = offset * 0.4;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, -parallaxOffset),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => FractionallySizedBox(
              heightFactor: 1.0,
              child: PlaylistInfoOverlay(
                playlist: widget.playlist,
                totalDuration: _totalDuration,
                description: 'No description yet.',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: cover != null
                  ? Image(image: cover, fit: BoxFit.cover)
                  : Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.playlist_play,
                        size: 80,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.playlist.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(label: '${_tracks.length} songs', colors: colors),
              const SizedBox(width: 8),
              _InfoChip(label: _totalDuration, colors: colors),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(colors),
        ],
      ),
    );
  }

  Widget _buildActionButtons(NatsuyumeColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(icon: Icons.shuffle, colors: colors, onTap: () {}),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.play_arrow,
          colors: colors,
          onTap: _playPlaylist,
        ),
      ],
    );
  }

  SliverList _buildTrackList(NatsuyumeColorScheme colors) {
    if (_tracks.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_off, size: 48, color: colors.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'No tracks in this playlist',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = _tracks[index];
        final widgetTrack = _toWidgetTrack(track);
        final isPlaying = index == _currentTrackIndex;
        final isSelected = _selectedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            if (_isSelecting) {
              _toggleSelection(index);
            } else {
              NatsuyumeCore.instance.openPlaylistInNewQueue(
                widget.playlist.id,
                widget.playlist.name,
              );
              // Jump to tapped track after opening
              Future.delayed(const Duration(milliseconds: 100), () {
                NatsuyumeCore.instance.jumpToTrack(index);
              });
              setState(() => _currentTrackIndex = index);
            }
          },
          onLongPress: () => _enterSelectMode(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                  SizedBox(
                    width: 24,
                    child: isPlaying
                        ? _EqualizerIcon(color: colors.accent)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: widgetTrack.albumArt != null
                      ? Image(
                          image: widgetTrack.albumArt!,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widgetTrack.title,
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
                        widgetTrack.artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widgetTrack.album,
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
                    widgetTrack.duration,
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
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }, childCount: _tracks.length),
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

  void _showPlaylistMenu(BuildContext context, NatsuyumeColorScheme colors) {
    PlaylistDetailContextMenu.show(
      context,
      playlist: widget.playlist,
      onExportM3U: () {},
      onRenamePlaylist: () {},
      onRemovePlaylist: () {},
      onPlayAfterCurrent: () {},
      onAddToCurrentQueue: () {},
      onAddToQueue: () {},
      onAddToPlaylists: () => PlaylistPickerSheet.show(
        context,
        trackPaths: _tracks.map((t) => t.path).toList(),
      ),
      onSelectMultiple: () => setState(() => _isSelecting = true),
      onOrganizeSongs: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => PlaylistOrganizerScreen(
                  playlistId: widget.playlist.id,
                  playlistName: widget.playlist.name,
                  tracks: _tracks,
                ),
              ),
            )
            .then((_) => _loadTracks());
      },
    );
  }

  void _showTrackMenu(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    PlaylistTrackContextMenu.show(
      context,
      track: _toWidgetTrack(_tracks[index]),
      isFavorite: false,
      onFavoriteTap: () {},
      onSongInfo: () {},
      onRemoveFromPlaylist: () => _removeTrackAt(index),
      onPlayAfterCurrent: () {},
      onAddToCurrentQueue: () {},
      onAddToQueue: () {},
      onAddToPlaylists: () =>
          PlaylistPickerSheet.show(context, trackPaths: [_tracks[index].path]),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets — unchanged from original
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  final String label;
  final NatsuyumeColorScheme colors;

  const _InfoChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 24, color: colors.onSurface),
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
        _Bar(height: 8, color: color),
        const SizedBox(width: 2),
        _Bar(height: 14, color: color),
        const SizedBox(width: 2),
        _Bar(height: 10, color: color),
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
