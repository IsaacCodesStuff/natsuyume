import 'dart:io';
import 'package:flutter/material.dart';
import 'collection_editor_screen.dart';
import '../../core/natsuyume_core.dart';
import '../../core/image_picker_service.dart';
import '../../core/collection_image_service.dart';

class PlaylistEditorScreen extends StatelessWidget {
  final int playlistId;
  final String initialName;
  final String initialDescription;
  final ImageProvider? initialImage;

  const PlaylistEditorScreen({
    super.key,
    required this.playlistId,
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
      onSave: (name, description) async {
        if (name.isNotEmpty && name != initialName) {
          NatsuyumeCore.instance.renamePlaylist(playlistId, name);
        }
        if (description != initialDescription) {
          NatsuyumeCore.instance.setPlaylistDescription(
            playlistId,
            description,
          );
        }
      },
      onPickImage: () async {
        final file = await ImagePickerService.instance.pickAndCropSquare(
          context,
        );
        if (file == null) return null;
        final path = await CollectionImageService.instance.savePlaylistImage(
          file,
          playlistId,
        );
        if (path == null) return null;
        NatsuyumeCore.instance.setPlaylistImage(playlistId, path);
        return FileImage(File(path));
      },
      onDeleteImage: () async {
        await CollectionImageService.instance.deletePlaylistImage(playlistId);
        NatsuyumeCore.instance.setPlaylistImage(playlistId, '');
      },
    );
  }
}
