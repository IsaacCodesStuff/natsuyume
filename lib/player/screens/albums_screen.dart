import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import 'album_detail_screen.dart';
import '../../widgets/sort_dialog.dart';

// Placeholder albums — will be wired to LibraryManager in 0.8.x
final _placeholderAlbums = [
  AlbumData(
    title: 'Summer Challenger',
    artist: '水瀬いのり',
    year: 2026,
    songCount: 3,
  ),
  AlbumData(title: 'Turquoise', artist: '水瀬いのり', year: 2025, songCount: 8),
  AlbumData(title: 'Travel Record', artist: '水瀬いのり', year: 2025, songCount: 23),
  AlbumData(title: 'heart bookmark', artist: '水瀬いのり', year: 2024, songCount: 7),
  AlbumData(title: 'スクラップアート', artist: '水瀬いのり', year: 2023, songCount: 3),
  AlbumData(title: 'アイオライト', artist: '水瀬いのり', year: 2023, songCount: 3),
  AlbumData(title: 'glow', artist: '水瀬いのり', year: 2022, songCount: 14),
  AlbumData(title: 'HELLO HORIZON', artist: '水瀬いのり', year: 2021, songCount: 3),
];

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  int _playingAlbumIndex = 0;

  List<AlbumData> get _filteredAlbums {
    if (_searchQuery.isEmpty) return _placeholderAlbums;
    final q = _searchQuery.toLowerCase();
    return _placeholderAlbums.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.artist.toLowerCase().contains(q);
    }).toList();
  }

  void _openAlbum(AlbumData album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          album: album,
          isAlbumPlaying:
              _placeholderAlbums.indexOf(album) == _playingAlbumIndex,
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, NatsuyumeColorScheme colors) {
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
            leading: Icon(Icons.sort, color: colors.onSurface),
            title: Text('Sort', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlbumSortDialog(
                  selectedField: AlbumSortField.name,
                  direction: SortDirection.ascending,
                  onChanged: (field, direction) {},
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.filter_list, color: colors.onSurface),
            title: Text('Filter', style: TextStyle(color: colors.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
        ],
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
              onMoreTap: () => _showMoreSheet(context, colors),
            ),
            Expanded(
              child: _layout == LibraryLayout.grid
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
          isPlaying:
              _placeholderAlbums.indexOf(albums[index]) == _playingAlbumIndex,
          onTap: () => _openAlbum(albums[index]),
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
          isPlaying:
              _placeholderAlbums.indexOf(albums[index]) == _playingAlbumIndex,
          onTap: () => _openAlbum(albums[index]),
          onMoreTap: () {},
        );
      },
    );
  }
}
