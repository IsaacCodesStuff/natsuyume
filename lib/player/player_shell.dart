import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../theme/natsuyume_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_player.dart';
import '../core/natsuyume_core.dart';
import '../core/cover_service.dart';
import 'screens/queue_screen.dart';
import 'screens/albums_screen.dart';
import 'screens/artists_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/now_playing_screen.dart';
import 'screens/more_screen.dart';

class PlayerShell extends StatefulWidget {
  const PlayerShell({super.key});

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  PlayerTab _currentTab = PlayerTab.queues;

  Widget _buildCurrentScreen() {
    switch (_currentTab) {
      case PlayerTab.queues:
        return const QueueScreen();
      case PlayerTab.albums:
        return const AlbumsScreen();
      case PlayerTab.artists:
        return const ArtistsScreen();
      case PlayerTab.playlists:
        return const PlaylistsScreen();
      case PlayerTab.settings:
        return const MoreScreen();
    }
  }

  void _openNowPlaying() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 1.0,
        child: NowPlayingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final core = NatsuyumeCore.instance;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Expanded(child: _buildCurrentScreen()),
          ListenableBuilder(
            listenable: core.playerState,
            builder: (context, _) {
              final track = core.playerState.currentTrack;
              final isPlaying = core.playerState.isPlaying;

              ImageProvider? albumArt;
              if (!track.isEmpty) {
                final bytes = CoverService.instance.getCoverForTrack(
                  track.path,
                );
                if (bytes != null) albumArt = MemoryImage(bytes);
              }

              return MiniPlayer(
                data: MiniPlayerData(
                  title: track.isEmpty ? 'Not playing' : track.title,
                  artist: track.isEmpty ? '' : track.artist,
                  album: track.isEmpty ? '' : track.album,
                  albumArt: albumArt,
                  isPlaying: isPlaying,
                  isFavorite: track.isFavorite,
                ),
                onTap: _openNowPlaying,
                onPlayPause: () {
                  if (isPlaying) {
                    core.pause();
                  } else {
                    core.play();
                  }
                },
                onPrevious: core.previous,
                onNext: core.next,
                onFavorite: () {},
              );
            },
          ),
          NatsuyumeBottomNavBar(
            currentTab: _currentTab,
            onTabSelected: (tab) => setState(() => _currentTab = tab),
          ),
        ],
      ),
    );
  }
}
