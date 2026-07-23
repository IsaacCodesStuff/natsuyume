import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../core/library_types.dart';
import '../../core/natsuyume_core.dart';
import '../../widgets/collection_detail_bar.dart';
import 'album_info_overlay.dart';
import 'context_menus/album_detail_context_menu.dart';
import 'context_menus/album_track_context_menu.dart';
import 'context_menus/album_track_multiselect_menu.dart';
import 'metadata_editor_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final AlbumData album;
  final bool isAlbumPlaying;

  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.isAlbumPlaying,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInBar = false;
  int _currentTrackIndex = -1;
  bool _isSelecting = false;
  final Set<int> _selectedIndices = {};
  List<CollectionTrack> _tracks = [];

  static const double _coverThreshold = 260.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTracks();
  }

  void _loadTracks() {
    final tracks = NatsuyumeCore.instance.getAlbumTracks(widget.album.title);
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

  void _showMultiSelectMenu() {
    final selected = _selectedIndices
        .map(
          (i) =>
              TrackMetadata(title: _tracks[i].title, artist: _tracks[i].artist),
        )
        .toList();

    AlbumTrackMultiselectMenu.show(
      context,
      count: _selectedIndices.length,
      tracks: selected,
      onPlayAfterCurrent: () => _exitSelectMode(),
      onAddToCurrentQueue: () => _exitSelectMode(),
      onAddToQueue: () => _exitSelectMode(),
      onAddToPlaylists: () => _exitSelectMode(),
      onAddToFavorites: () => _exitSelectMode(),
      onRemoveFromFavorites: () => _exitSelectMode(),
      onClearPlaybackHistory: () => _exitSelectMode(),
    );
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

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
                SliverToBoxAdapter(child: _buildCoverHero(colors)),
                SliverToBoxAdapter(child: _buildAlbumInfo(colors)),
                _buildTrackList(colors),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CollectionDetailBar(
                title: widget.album.title,
                showTitle: _showTitleInBar,
                onBack: () => Navigator.of(context).pop(),
                onMoreTap: () => _showAlbumMenu(context, colors),
              ),
            ),
            if (_showTitleInBar && !_isSelecting)
              Positioned(
                right: 16,
                bottom: 16,
                child: _buildActionButtons(colors, small: true),
              ),
            if (_isSelecting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildMultiSelectBar(colors),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverHero(NatsuyumeColorScheme colors) {
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
              child: AlbumInfoOverlay(
                album: widget.album,
                artistName: widget.album.artist,
                albumArtist: widget.album.artist,
                duration: _totalDuration,
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
              child: widget.album.coverArt != null
                  ? Image(image: widget.album.coverArt!, fit: BoxFit.cover)
                  : Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.album,
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

  Widget _buildAlbumInfo(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.album.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.album.artist,
            style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(label: '${widget.album.year}', colors: colors),
              const SizedBox(width: 8),
              _InfoChip(label: '${_tracks.length} songs', colors: colors),
              const SizedBox(width: 8),
              _InfoChip(label: _totalDuration, colors: colors),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(colors, small: false),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    NatsuyumeColorScheme colors, {
    required bool small,
  }) {
    final size = small ? 48.0 : 56.0;
    final iconSize = small ? 20.0 : 24.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.shuffle,
          colors: colors,
          size: size,
          iconSize: iconSize,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.play_arrow,
          colors: colors,
          size: size,
          iconSize: iconSize,
          onTap: () {},
        ),
      ],
    );
  }

  SliverList _buildTrackList(NatsuyumeColorScheme colors) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
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

  void _showAlbumMenu(BuildContext context, NatsuyumeColorScheme colors) {
    AlbumDetailContextMenu.show(
      context,
      album: widget.album,
      onPlayAfterCurrent: () {},
      onAddToCurrentQueue: () {},
      onAddToQueue: () {},
      onAddToPlaylists: () {},
      onSelectMultiple: () => setState(() => _isSelecting = true),
    );
  }

  void _showTrackMenu(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    AlbumTrackContextMenu.show(
      context,
      track: _tracks[index],
      isFavorite: false,
      onFavoriteTap: () {},
      onSongInfo: () {},
      onPlayAfterCurrent: () {},
      onAddToCurrentQueue: () {},
      onAddToQueue: () {},
      onAddToPlaylists: () {},
    );
  }
}

// Local widget classes — unchanged from original
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.colors,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: iconSize, color: colors.onSurface),
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
