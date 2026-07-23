import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../core/library_types.dart';
import '../../core/natsuyume_core.dart';
import '../../widgets/collection_detail_bar.dart';
import '../../widgets/artist_album_list.dart';
import 'album_detail_screen.dart';
import 'artist_info_overlay.dart';
import 'artist_editor_screen.dart';
import 'context_menus/artist_detail_context_menu.dart';
import 'context_menus/artist_track_context_menu.dart';
import 'context_menus/artist_track_multiselect_menu.dart';
import 'metadata_editor_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final ArtistData artist;
  final bool isArtistPlaying;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
    required this.isArtistPlaying,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInBar = false;
  final int _currentAlbumIndex = 0;
  bool _isSelecting = false;
  final Set<int> _selectedIndices = {};
  List<ArtistAlbumEntry> _albums = [];

  static const double _coverThreshold = 260.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAlbums();
  }

  void _loadAlbums() {
    final albums = NatsuyumeCore.instance.getArtistAlbums(widget.artist.name);
    setState(() => _albums = albums);
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
            title: _albums[i].title,
            artist: widget.artist.name,
            year: '${_albums[i].year}',
          ),
        )
        .toList();

    ArtistTrackMultiselectMenu.show(
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

  void _openAlbum(int index) {
    final entry = _albums[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          album: AlbumData(
            title: entry.title,
            artist: widget.artist.name,
            year: entry.year,
            songCount: entry.songCount,
            coverArt: entry.coverArt,
          ),
          isAlbumPlaying: false,
        ),
      ),
    );
  }

  int get _totalTrackCount => _albums.fold(0, (sum, a) => sum + a.songCount);

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
                SliverToBoxAdapter(child: _buildPhotoHero(colors)),
                SliverToBoxAdapter(child: _buildArtistInfo(colors)),
                _buildAlbumList(colors),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CollectionDetailBar(
                title: widget.artist.name,
                showTitle: _showTitleInBar,
                onBack: () => Navigator.of(context).pop(),
                onMoreTap: () => _showArtistMenu(context, colors),
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
                          child: ArtistEditorScreen(
                            initialName: widget.artist.name,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoHero(NatsuyumeColorScheme colors) {
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
              child: ArtistInfoOverlay(
                artist: widget.artist,
                totalAlbums: _albums.length,
                totalTracks: _totalTrackCount,
                totalDuration: '—',
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
              child: widget.artist.photo != null
                  ? Image(image: widget.artist.photo!, fit: BoxFit.cover)
                  : Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.person,
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

  Widget _buildArtistInfo(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.artist.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_albums.length} albums',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
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
        _ActionButton(icon: Icons.play_arrow, colors: colors, onTap: () {}),
      ],
    );
  }

  ArtistAlbumList _buildAlbumList(NatsuyumeColorScheme colors) {
    return ArtistAlbumList(
      allSongsLabel: 'All songs',
      allSongsCount: _totalTrackCount,
      albums: _albums,
      currentAlbumIndex: _isSelecting ? null : _currentAlbumIndex,
      onAllSongsTap: () {},
      onAlbumTap: (i) {
        if (_isSelecting) {
          _toggleSelection(i);
        } else {
          _openAlbum(i);
        }
      },
      onAlbumMoreTap: (i) => _showAlbumMenu(context, i, colors),
      onAllSongsMoreTap: () {},
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

  void _showArtistMenu(BuildContext context, NatsuyumeColorScheme colors) {
    ArtistDetailContextMenu.show(
      context,
      artist: widget.artist,
      onPlayAfterCurrent: () {},
      onAddToCurrentQueue: () {},
      onAddToQueue: () {},
      onAddToPlaylists: () {},
      onSelectMultiple: () => setState(() => _isSelecting = true),
    );
  }

  void _showAlbumMenu(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    ArtistTrackContextMenu.show(
      context,
      album: _albums[index],
      artistName: widget.artist.name,
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
