import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import 'artist_detail_screen.dart';
import '../../widgets/sort_dialog.dart';
import 'context_menus/artist_tab_context_menu.dart';

class ArtistData {
  final String name;
  final int albumCount;
  final ImageProvider? photo;

  const ArtistData({required this.name, required this.albumCount, this.photo});

  String get subtitle => '$albumCount albums';
}

final _placeholderArtists = [
  ArtistData(name: '水瀬いのり', albumCount: 20),
  ArtistData(name: '鬼頭明里', albumCount: 16),
  ArtistData(name: '幾田りら', albumCount: 12),
  ArtistData(name: '高橋李依', albumCount: 2),
  ArtistData(name: 'YOASOBI', albumCount: 8),
  ArtistData(name: 'Michael Jackson', albumCount: 9),
  ArtistData(name: 'Unknown Artist', albumCount: 1),
];

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  int _playingArtistIndex = 0;

  List<ArtistData> get _filteredArtists {
    if (_searchQuery.isEmpty) return _placeholderArtists;
    final q = _searchQuery.toLowerCase();
    return _placeholderArtists
        .where((a) => a.name.toLowerCase().contains(q))
        .toList();
  }

  void _openArtist(ArtistData artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(
          artist: artist,
          isArtistPlaying:
              _placeholderArtists.indexOf(artist) == _playingArtistIndex,
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
                builder: (_) => ArtistSortDialog(
                  selectedField: ArtistSortField.name,
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

  // We reuse AlbumData shape for the grid/list widgets
  // mapping artist fields to the expected fields
  AlbumData _toAlbumData(ArtistData artist) => AlbumData(
    title: artist.name,
    artist: '${artist.albumCount} albums',
    year: 0,
    songCount: artist.albumCount,
    coverArt: artist.photo,
  );

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final artists = _filteredArtists;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            LibraryTopBar(
              searchHint: 'Search for artist...',
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              currentLayout: _layout,
              onLayoutChanged: (l) => setState(() => _layout = l),
              onMoreTap: () => _showMoreSheet(context, colors),
            ),
            Expanded(
              child: _layout == LibraryLayout.grid
                  ? _buildGrid(artists, colors)
                  : _buildList(artists, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<ArtistData> artists, NatsuyumeColorScheme colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return AlbumGridItem(
          album: _toAlbumData(artists[index]),
          isPlaying:
              _placeholderArtists.indexOf(artists[index]) ==
              _playingArtistIndex,
          onTap: () => _openArtist(artists[index]),
          onLongPress: () => ArtistTabContextMenu.show(
            context,
            artist: artists[index],
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () {},
            onSelectAllSongs: () {},
          ),
        );
      },
    );
  }

  Widget _buildList(List<ArtistData> artists, NatsuyumeColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return AlbumListItem(
          album: _toAlbumData(artists[index]),
          isPlaying:
              _placeholderArtists.indexOf(artists[index]) ==
              _playingArtistIndex,
          onTap: () => _openArtist(artists[index]),
          onMoreTap: () {},
          onLongPress: () => ArtistTabContextMenu.show(
            context,
            artist: artists[index],
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () {},
            onSelectAllSongs: () {},
          ),
        );
      },
    );
  }
}
