import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CollectionImageService {
  CollectionImageService._();
  static final CollectionImageService instance = CollectionImageService._();

  /// Saves [file] to `dataDir/artist_images/<sanitizedName>.jpg`.
  /// Returns the saved file path, or null on failure.
  Future<String?> saveArtistImage(File file, String artistName) async {
    return _save(file, 'artist_images', _sanitize(artistName));
  }

  /// Saves [file] to `dataDir/playlist_images/playlist_<id>.jpg`.
  /// Returns the saved file path, or null on failure.
  Future<String?> savePlaylistImage(File file, int playlistId) async {
    return _save(file, 'playlist_images', 'playlist_$playlistId');
  }

  /// Deletes the stored artist image for [artistName].
  Future<void> deleteArtistImage(String artistName) async {
    await _delete('artist_images', _sanitize(artistName));
  }

  /// Deletes the stored playlist image for [playlistId].
  Future<void> deletePlaylistImage(int playlistId) async {
    await _delete('playlist_images', 'playlist_$playlistId');
  }

  // ---------------------------------------------------------------------------

  Future<String?> _save(File source, String folder, String name) async {
    try {
      final dataDir = await getApplicationSupportDirectory();
      final dir = Directory('${dataDir.path}/$folder');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final dest = File('${dir.path}/$name.jpg');
      await source.copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _delete(String folder, String name) async {
    try {
      final dataDir = await getApplicationSupportDirectory();
      final file = File('${dataDir.path}/$folder/$name.jpg');
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  String _sanitize(String name) {
    // Replace characters that are invalid in file names
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
