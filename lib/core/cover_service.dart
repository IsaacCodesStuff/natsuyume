import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'natsuyume_core.dart';

// Top-level functions required by compute() — must be outside the class.

Uint8List? _fetchCoverForTrack(String path) {
  return NatsuyumeCore.instance.getCoverBytes(path);
}

Uint8List? _fetchCoverForAlbum(String albumName) {
  return NatsuyumeCore.instance.getCoverBytesForAlbum(albumName);
}

class CoverService {
  CoverService._();
  static final CoverService instance = CoverService._();

  final Map<String, Uint8List> _cache = {};

  // Synchronous — only use for single-track cases (MiniPlayer, NowPlaying).
  Uint8List? getCoverForTrack(String path) {
    if (path.isEmpty) return null;
    if (_cache.containsKey(path)) return _cache[path];
    final bytes = NatsuyumeCore.instance.getCoverBytes(path);
    if (bytes != null) _cache[path] = bytes;
    return bytes;
  }

  // Async — use for list/grid items to avoid blocking the main thread.
  Future<Uint8List?> getCoverForTrackAsync(String path) async {
    if (path.isEmpty) return null;
    if (_cache.containsKey(path)) return _cache[path];
    // Defer off the current frame without spawning an isolate.
    // FFI calls are fast enough (~5-20ms) that this avoids jank
    // without the isolate boundary problem.
    final bytes = await Future(
      () => NatsuyumeCore.instance.getCoverBytes(path),
    );
    if (bytes != null) _cache[path] = bytes;
    return bytes;
  }

  Future<Uint8List?> getCoverForAlbumAsync(String albumName) async {
    if (albumName.isEmpty) return null;
    final key = 'album:$albumName';
    if (_cache.containsKey(key)) return _cache[key];
    final bytes = await Future(
      () => NatsuyumeCore.instance.getCoverBytesForAlbum(albumName),
    );
    if (bytes != null) _cache[key] = bytes;
    return bytes;
  }

  void clearCache() => _cache.clear();
}
