import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'natsuyume_core.dart';

class CoverService {
  CoverService._();
  static final CoverService instance = CoverService._();

  final Map<String, Uint8List> _cache = {};
  final Map<String, Color> _paletteCache = {};

  Uint8List? getCoverForTrack(String path) {
    if (path.isEmpty) return null;
    if (_cache.containsKey(path)) return _cache[path];
    final bytes = NatsuyumeCore.instance.getCoverBytes(path);
    if (bytes != null) _cache[path] = bytes;
    return bytes;
  }

  Future<Uint8List?> getCoverForTrackAsync(String path) async {
    if (path.isEmpty) return null;
    if (_cache.containsKey(path)) return _cache[path];
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

  // Extracts the dominant vibrant color from cover art bytes.
  // Returns null if extraction fails or bytes are null.
  Future<Color?> extractDominantColor(Uint8List bytes) async {
    // Check palette cache by bytes identity hash
    final cacheKey = 'palette:${bytes.hashCode}';
    if (_paletteCache.containsKey(cacheKey)) return _paletteCache[cacheKey];

    try {
      final image = MemoryImage(bytes);
      final generator = await PaletteGenerator.fromImageProvider(
        image,
        maximumColorCount: 16,
      );

      // Prefer vibrant → dominant → first swatch
      final color =
          generator.vibrantColor?.color ??
          generator.dominantColor?.color ??
          generator.paletteColors.firstOrNull?.color;

      if (color != null) _paletteCache[cacheKey] = color;
      return color;
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _cache.clear();
    _paletteCache.clear();
  }
}
