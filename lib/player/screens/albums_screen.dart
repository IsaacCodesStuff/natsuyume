import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import '../../core/library_types.dart';
import '../../core/natsuyume_core.dart';
import 'album_detail_screen.dart';
import '../../widgets/sort_dialog.dart';
import 'context_menus/album_tab_context_menu.dart';
import '../../widgets/playlist_picker_sheet.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  List<AlbumData> _albums = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    NatsuyumeCore.instance.scanState.addListener(_onScanStateChanged);
  }

  @override
  void dispose() {
    NatsuyumeCore.instance.scanState.removeListener(_onScanStateChanged);
    super.dispose();
  }

  void _onScanStateChanged() {
    if (!NatsuyumeCore.instance.scanState.isScanning) {
      _loadAlbums();
    }
  }

  void _loadAlbums() {
    final albums = NatsuyumeCore.instance.getAlbums();
    setState(() => _albums = albums);
  }

  List<AlbumData> get _filteredAlbums {
    if (_searchQuery.isEmpty) return _albums;
    final q = _searchQuery.toLowerCase();
    return _albums.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.artist.toLowerCase().contains(q);
    }).toList();
  }

  void _openAlbum(AlbumData album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album, isAlbumPlaying: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final albums = _filteredAlbums;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            LibraryTopBar(
              searchHint: 'Search an album...',
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              currentLayout: _layout,
              onLayoutChanged: (l) => setState(() => _layout = l),
              onMoreTap: () => showDialog(
                context: context,
                builder: (_) => AlbumSortDialog(
                  selectedField: AlbumSortField.name,
                  direction: SortDirection.ascending,
                  onChanged: (field, direction) {},
                ),
              ),
            ),
            Expanded(
              child: albums.isEmpty
                  ? Center(
                      child: Text(
                        'No albums found',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    )
                  : _layout == LibraryLayout.grid
                  ? _buildGrid(albums, colors)
                  : _buildList(albums, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<AlbumData> albums, NatsuyumeColorScheme colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return AlbumGridItem(
          album: albums[index],
          isPlaying: false,
          onTap: () => _openAlbum(albums[index]),
          onLongPress: () => AlbumTabContextMenu.show(
            context,
            album: albums[index],
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () => _addAlbumToPlaylist(albums[index]),
            onSelectAllSongs: () {},
          ),
        );
      },
    );
  }

  Widget _buildList(List<AlbumData> albums, NatsuyumeColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return AlbumListItem(
          album: albums[index],
          isPlaying: false,
          onTap: () => _openAlbum(albums[index]),
          onMoreTap: () {},
          onLongPress: () => AlbumTabContextMenu.show(
            context,
            album: albums[index],
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () => _addAlbumToPlaylist(albums[index]),
            onSelectAllSongs: () {},
          ),
        );
      },
    );
  }

  void _addAlbumToPlaylist(AlbumData album) {
    final tracks = NatsuyumeCore.instance.getAlbumTracks(album.title);
    final paths = tracks.map((t) => t.path).toList();
    if (paths.isEmpty) return;
    PlaylistPickerSheet.show(context, trackPaths: paths);
  }
}
