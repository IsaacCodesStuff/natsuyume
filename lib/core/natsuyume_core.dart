import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'natsuyume_bindings.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'library_types.dart';
import 'dart:typed_data';

class NatsuyumeCore {
  NatsuyumeCore._();
  static final NatsuyumeCore instance = NatsuyumeCore._();

  late final NatsuyumeBindings _bindings;
  late final Pointer<Void> _core;
  bool _initialized = false;

  final CorePlayerState playerState = CorePlayerState();
  final CoreScanState scanState = CoreScanState();
  String _lastTrackPath = '';
  Timer? _pollTimer;

  // Phase 2A — load the library only, no core init yet
  void init() {
    if (_initialized) return;
    _bindings = NatsuyumeBindings();
    _initialized = true;
  }

  // Phase 2B — create core instance and initialize with data dir
  Future<void> initCore() async {
    await Permission.audio.request();
    final dataDir = await getApplicationSupportDirectory();
    final dataDirPath = dataDir.path;
    _core = _bindings.ncoreCreate();
    final pathPtr = dataDirPath.toNativeUtf8();
    try {
      _bindings.ncoreSetDataDir(_core, pathPtr);
      _bindings.ncoreInit(_core);
      startPolling();
    } finally {
      calloc.free(pathPtr);
    }
    print('NatsuyumeCore initCore OK — dataDir: $dataDirPath');
  }

  void shutdown() {
    if (!_initialized) return;
    _bindings.ncoreShutdown(_core);
  }

  String get version {
    final ptr = _bindings.ncoreGetVersion();
    final str = ptr.toDartString();
    _bindings.ncoreFreeString(ptr);
    return str;
  }

  Future<void> openFile(String path) async {
    final pathPtr = path.toNativeUtf8();
    try {
      _bindings.ncoreOpenFile(_core, pathPtr);
    } finally {
      calloc.free(pathPtr);
    }
  }

  bool get isPlaying => _bindings.ncoreIsPlaying(_core) == 1;

  int get positionMs => _bindings.ncoreGetPosition(_core);
  int get durationMs => _bindings.ncoreGetDuration(_core);

  Duration get position => Duration(milliseconds: positionMs);
  Duration get duration => Duration(milliseconds: durationMs);

  CoreTrack get currentTrack {
    final pathPtr = calloc<Pointer<Utf8>>();
    final titlePtr = calloc<Pointer<Utf8>>();
    final artistPtr = calloc<Pointer<Utf8>>();
    final albumPtr = calloc<Pointer<Utf8>>();
    final aaPtr = calloc<Pointer<Utf8>>();
    final genrePtr = calloc<Pointer<Utf8>>();
    final tnPtr = calloc<Int32>();
    final yearPtr = calloc<Int32>();
    final durPtr = calloc<Int64>();
    final pcPtr = calloc<Int32>();
    final favPtr = calloc<Int32>();

    try {
      _bindings.ncoreGetCurrentTrack(
        _core,
        pathPtr,
        titlePtr,
        artistPtr,
        albumPtr,
        aaPtr,
        genrePtr,
        tnPtr,
        yearPtr,
        durPtr,
        pcPtr,
        favPtr,
      );

      final track = CoreTrack(
        path: pathPtr.value.toDartString(),
        title: titlePtr.value.toDartString(),
        artist: artistPtr.value.toDartString(),
        album: albumPtr.value.toDartString(),
        albumArtist: aaPtr.value.toDartString(),
        genre: genrePtr.value.toDartString(),
        trackNumber: tnPtr.value,
        year: yearPtr.value,
        durationMs: durPtr.value,
        playCount: pcPtr.value,
        isFavorite: favPtr.value == 1,
      );

      // Free the C strings
      _bindings.ncoreFreeString(pathPtr.value);
      _bindings.ncoreFreeString(titlePtr.value);
      _bindings.ncoreFreeString(artistPtr.value);
      _bindings.ncoreFreeString(albumPtr.value);
      _bindings.ncoreFreeString(aaPtr.value);
      _bindings.ncoreFreeString(genrePtr.value);

      return track;
    } finally {
      calloc.free(pathPtr);
      calloc.free(titlePtr);
      calloc.free(artistPtr);
      calloc.free(albumPtr);
      calloc.free(aaPtr);
      calloc.free(genrePtr);
      calloc.free(tnPtr);
      calloc.free(yearPtr);
      calloc.free(durPtr);
      calloc.free(pcPtr);
      calloc.free(favPtr);
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Drain LibraryManager's callback queue first
      _bindings.ncoreDrainLibraryCallbacks(_core);

      // Playback state
      final isPlaying = _bindings.ncoreIsPlaying(_core) == 1;
      final posMs = _bindings.ncoreGetPosition(_core);
      final durMs = _bindings.ncoreGetDuration(_core);

      playerState.updatePlaybackState(isPlaying);
      playerState.updatePosition(posMs);
      playerState.updateDuration(durMs);

      // Track change detection
      final track = currentTrack;
      if (track.path != _lastTrackPath) {
        _lastTrackPath = track.path;
        playerState.updateTrack(track);
      }

      // Scan state
      final scanning = _bindings.ncoreIsScanning(_core) == 1;
      final progress = _bindings.ncoreScanProgress(_core);
      final total = _bindings.ncoreScanTotal(_core);
      scanState.update(scanning, progress, total);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void play() => _bindings.ncorePlay(_core);
  void pause() => _bindings.ncorePause(_core);
  void next() => _bindings.ncoreNext(_core);
  void previous() => _bindings.ncorePrevious(_core);

  void seekTo(int positionMs) {
    _bindings.ncoreSeek(_core, positionMs / 1000.0);
  }

  void addScanFolder(String path) {
    final ptr = path.toNativeUtf8();
    try {
      _bindings.ncoreAddScanFolder(_core, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  void removeScanFolder(String path) {
    final ptr = path.toNativeUtf8();
    try {
      _bindings.ncoreRemoveScanFolder(_core, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  void rescanAllFolders() => _bindings.ncoreScanLibrary(_core);
  void cancelScan() => _bindings.ncoreCancelScan(_core);

  List<CoreTrack> getQueueTracks() {
    final ptr = _bindings.ncoreGetQueueJson(_core);
    try {
      final jsonStr = ptr.toDartString();
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return CoreTrack(
          path: m['path'] as String,
          title: m['title'] as String,
          artist: m['artist'] as String,
          album: m['album'] as String,
          albumArtist: m['albumArtist'] as String,
          genre: '',
          trackNumber: m['trackNumber'] as int,
          year: 0,
          durationMs: m['durationMs'] as int,
          playCount: 0,
          isFavorite: m['isFavorite'] as bool,
        );
      }).toList();
    } finally {
      _bindings.ncoreFreeString(ptr);
    }
  }

  List<AlbumData> getAlbums() {
    final ptr = _bindings.ncoreGetAlbumsJson(_core);
    try {
      final list = jsonDecode(ptr.toDartString()) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return AlbumData(
          title: m['title'] as String,
          artist: m['artist'] as String,
          year: m['year'] as int,
          songCount: m['songCount'] as int,
        );
      }).toList();
    } finally {
      _bindings.ncoreFreeString(ptr);
    }
  }

  List<ArtistData> getArtists() {
    final ptr = _bindings.ncoreGetArtistsJson(_core);
    try {
      final list = jsonDecode(ptr.toDartString()) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return ArtistData(
          name: m['name'] as String,
          albumCount: m['albumCount'] as int,
        );
      }).toList();
    } finally {
      _bindings.ncoreFreeString(ptr);
    }
  }

  List<CollectionTrack> getAlbumTracks(String albumName) {
    final namePtr = albumName.toNativeUtf8();
    try {
      final ptr = _bindings.ncoreGetAlbumTracksJson(_core, namePtr);
      try {
        final list = jsonDecode(ptr.toDartString()) as List<dynamic>;
        return list.map((e) {
          final m = e as Map<String, dynamic>;
          final ms = m['durationMs'] as int;
          final totalSec = ms ~/ 1000;
          final min = totalSec ~/ 60;
          final sec = totalSec % 60;
          return CollectionTrack(
            path: m['path'] as String,
            title: m['title'] as String,
            artist: m['artist'] as String,
            duration: '$min:${sec.toString().padLeft(2, '0')}',
          );
        }).toList();
      } finally {
        _bindings.ncoreFreeString(ptr);
      }
    } finally {
      calloc.free(namePtr);
    }
  }

  List<ArtistAlbumEntry> getArtistAlbums(String artistName) {
    final namePtr = artistName.toNativeUtf8();
    try {
      final ptr = _bindings.ncoreGetArtistAlbumsJson(_core, namePtr);
      try {
        final list = jsonDecode(ptr.toDartString()) as List<dynamic>;
        return list.map((e) {
          final m = e as Map<String, dynamic>;
          return ArtistAlbumEntry(
            title: m['title'] as String,
            year: m['year'] as int,
            songCount: m['songCount'] as int,
          );
        }).toList();
      } finally {
        _bindings.ncoreFreeString(ptr);
      }
    } finally {
      calloc.free(namePtr);
    }
  }

  void openPathsInNewQueue(List<String> paths, {int startIndex = 0}) {
    final jsonStr =
        '[${paths.map((p) => '"${p.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"').join(',')}]';
    final ptr = jsonStr.toNativeUtf8();
    try {
      _bindings.ncoreOpenPathsInNewQueue(_core, ptr, startIndex);
    } finally {
      calloc.free(ptr);
    }
  }

  Uint8List? getCoverBytes(String path) {
    final pathPtr = path.toNativeUtf8();
    final sizePtr = calloc<Int32>();
    final mimePtr = calloc<Pointer<Utf8>>();
    try {
      final result = _bindings.ncoreGetCoverBytes(
        _core,
        pathPtr,
        sizePtr,
        mimePtr,
      );
      if (result == nullptr || sizePtr.value == 0) return null;
      final bytes = Uint8List.fromList(result.asTypedList(sizePtr.value));
      _bindings.ncoreFreeCoverBytes(result);
      if (mimePtr.value != nullptr) {
        _bindings.ncoreFreeString(mimePtr.value);
      }
      return bytes;
    } finally {
      calloc.free(pathPtr);
      calloc.free(sizePtr);
      calloc.free(mimePtr);
    }
  }

  Uint8List? getCoverBytesForAlbum(String albumName) {
    final namePtr = albumName.toNativeUtf8();
    final sizePtr = calloc<Int32>();
    final mimePtr = calloc<Pointer<Utf8>>();
    try {
      final result = _bindings.ncoreGetCoverBytesForAlbum(
        _core,
        namePtr,
        sizePtr,
        mimePtr,
      );
      if (result == nullptr || sizePtr.value == 0) return null;
      final bytes = Uint8List.fromList(result.asTypedList(sizePtr.value));
      _bindings.ncoreFreeCoverBytes(result);
      if (mimePtr.value != nullptr) {
        _bindings.ncoreFreeString(mimePtr.value);
      }
      return bytes;
    } finally {
      calloc.free(namePtr);
      calloc.free(sizePtr);
      calloc.free(mimePtr);
    }
  }

  String getLyrics(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final ptr = _bindings.ncoreGetLyrics(_core, pathPtr);
      final lyrics = ptr.toDartString();
      _bindings.ncoreFreeString(ptr);
      return lyrics;
    } finally {
      calloc.free(pathPtr);
    }
  }

  void jumpToTrack(int index) {
    _bindings.ncoreJumpToTrack(_core, index);
  }
}

class CoreTrack {
  final String path;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final int trackNumber;
  final int year;
  final int durationMs;
  final int playCount;
  final bool isFavorite;

  const CoreTrack({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    required this.genre,
    required this.trackNumber,
    required this.year,
    required this.durationMs,
    required this.playCount,
    required this.isFavorite,
  });

  bool get isEmpty => path.isEmpty;
  Duration get duration => Duration(milliseconds: durationMs);
}

class CorePlayerState extends ChangeNotifier {
  bool _isPlaying = false;
  int _positionMs = 0;
  int _durationMs = 0;
  CoreTrack _currentTrack = const CoreTrack(
    path: '',
    title: '',
    artist: '',
    album: '',
    albumArtist: '',
    genre: '',
    trackNumber: 0,
    year: 0,
    durationMs: 0,
    playCount: 0,
    isFavorite: false,
  );

  bool get isPlaying => _isPlaying;
  int get positionMs => _positionMs;
  int get durationMs => _durationMs;
  CoreTrack get currentTrack => _currentTrack;

  Duration get position => Duration(milliseconds: _positionMs);
  Duration get duration => Duration(milliseconds: _durationMs);

  void updatePlaybackState(bool isPlaying) {
    _isPlaying = isPlaying;
    notifyListeners();
  }

  void updatePosition(int positionMs) {
    _positionMs = positionMs;
    notifyListeners();
  }

  void updateDuration(int durationMs) {
    _durationMs = durationMs;
    notifyListeners();
  }

  void updateTrack(CoreTrack track) {
    _currentTrack = track;
    notifyListeners();
  }
}

class CoreScanState extends ChangeNotifier {
  bool _isScanning = false;
  int _progress = 0;
  int _total = 0;

  bool get isScanning => _isScanning;
  int get progress => _progress;
  int get total => _total;

  void update(bool isScanning, int progress, int total) {
    _isScanning = isScanning;
    _progress = progress;
    _total = total;
    notifyListeners();
  }
}
