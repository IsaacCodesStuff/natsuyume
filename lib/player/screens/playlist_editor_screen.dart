import 'package:flutter/material.dart';
import 'collection_editor_screen.dart';

class PlaylistEditorScreen extends StatelessWidget {
  final String initialName;
  final String initialDescription;
  final ImageProvider? initialImage;

  const PlaylistEditorScreen({
    super.key,
    this.initialName = '',
    this.initialDescription = '',
    this.initialImage,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionEditorScreen(
      title: 'Playlist Editor',
      nameLabel: 'Playlist Name',
      themeColorLabel: 'Theme Color for Playlist',
      initialName: initialName,
      initialDescription: initialDescription,
      initialImage: initialImage,
    );
  }
}
