import 'package:flutter/material.dart';
import 'collection_editor_screen.dart';

class ArtistEditorScreen extends StatelessWidget {
  final String initialName;
  final String initialDescription;
  final ImageProvider? initialImage;

  const ArtistEditorScreen({
    super.key,
    this.initialName = '',
    this.initialDescription = '',
    this.initialImage,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionEditorScreen(
      title: 'Artist Editor',
      nameLabel: 'Artist Name',
      themeColorLabel: 'Theme Color for Profile',
      initialName: initialName,
      initialDescription: initialDescription,
      initialImage: initialImage,
    );
  }
}
