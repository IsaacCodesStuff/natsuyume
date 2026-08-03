import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class ImagePickerService {
  ImagePickerService._();
  static final ImagePickerService instance = ImagePickerService._();

  /// Opens the gallery, lets the user pick an image, then crops it to a square.
  /// Returns the cropped [File], or null if the user cancelled at any point.
  Future<File?> pickAndCropSquare(BuildContext context) async {
    // Step 1 — pick from gallery
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final pickedPath = result.files.single.path;
    if (pickedPath == null) return null;

    // Step 2 — crop to square
    final cropped = await ImageCropper().cropImage(
      sourcePath: pickedPath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
      ],
    );
    if (cropped == null) return null;

    return File(cropped.path);
  }
}
