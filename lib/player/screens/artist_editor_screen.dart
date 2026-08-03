import 'dart:io';
import 'package:flutter/material.dart';
import 'collection_editor_screen.dart';
import '../../core/natsuyume_core.dart';
import '../../core/image_picker_service.dart';
import '../../core/collection_image_service.dart';

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
      onSave: (name, description) async {
        // Name field is read-only for artists — artists are identified
        // by their library name, we only store the image.
        // Description storage deferred to 0.9.5 metadata infrastructure.
      },
      onPickImage: () async {
        final file = await ImagePickerService.instance.pickAndCropSquare(
          context,
        );
        if (file == null) return null;
        final path = await CollectionImageService.instance.saveArtistImage(
          file,
          initialName,
        );
        if (path == null) return null;
        NatsuyumeCore.instance.setArtistImage(initialName, path);
        return FileImage(File(path));
      },
      onDeleteImage: () async {
        await CollectionImageService.instance.deleteArtistImage(initialName);
        NatsuyumeCore.instance.setArtistImage(initialName, '');
      },
    );
  }
}
