import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import '../../core/library_types.dart';
import '../../core/natsuyume_core.dart';
import 'artist_detail_screen.dart';
import '../../widgets/sort_dialog.dart';
import 'context_menus/artist_tab_context_menu.dart';
import '../../widgets/playlist_picker_sheet.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  List<ArtistData> _artists = [];

  @override
  void initState() {
    super.initState();
    _loadArtists();
    NatsuyumeCore.instance.scanState.addListener(_onScanStateChanged);
  }

  @override
  void dispose() {
    NatsuyumeCore.instance.scanState.removeListener(_onScanStateChanged);
    super.dispose();
  }

  void _onScanStateChanged() {
    if (!NatsuyumeCore.instance.scanState.isScanning) {
      _loadArtists();
    }
  }

  void _loadArtists() {
    final artists = NatsuyumeCore.instance.getArtists();
    setState(() => _artists = artists);
  }

  List<ArtistData> get _filteredArtists {
    if (_searchQuery.isEmpty) return _artists;
    final q = _searchQuery.toLowerCase();
    return _artists.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  void _openArtist(ArtistData artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ArtistDetailScreen(artist: artist, isArtistPlaying: false),
      ),
    );
  }

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
              onMoreTap: () => showDialog(
                context: context,
                builder: (_) => ArtistSortDialog(
                  selectedField: ArtistSortField.name,
                  direction: SortDirection.ascending,
                  onChanged: (field, direction) {},
                ),
              ),
            ),
            Expanded(
              child: artists.isEmpty
                  ? Center(
                      child: Text(
                        'No artists found',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    )
                  : _layout == LibraryLayout.grid
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
          isPlaying: false,
          onTap: () => _openArtist(artists[index]),
          onLongPress: () => ArtistTabContextMenu.show(
            context,
            artist: artists[index],
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () => _addArtistToPlaylist(artists[index]),
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
          isPlaying: false,
          onTap: () => _openArtist(artists[index]),
          onMoreTap: () {},
          onLongPress: () => ArtistTabContextMenu.show(
            context,
            artist: artists[index],
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () => _addArtistToPlaylist(artists[index]),
            onSelectAllSongs: () {},
          ),
        );
      },
    );
  }

  void _addArtistToPlaylist(ArtistData artist) {
    final albums = NatsuyumeCore.instance.getArtistAlbums(artist.name);
    final paths = <String>[];
    for (final album in albums) {
      final tracks = NatsuyumeCore.instance.getAlbumTracks(album.title);
      paths.addAll(tracks.map((t) => t.path));
    }
    if (paths.isEmpty) return;
    PlaylistPickerSheet.show(context, trackPaths: paths);
  }
}
