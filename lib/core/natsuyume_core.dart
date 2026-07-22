import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'natsuyume_bindings.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NatsuyumeCore {
  NatsuyumeCore._();
  static final NatsuyumeCore instance = NatsuyumeCore._();

  late final NatsuyumeBindings _bindings;
  late final Pointer<Void> _core;
  bool _initialized = false;

  final CorePlayerState playerState = CorePlayerState();
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
      final isPlaying = _bindings.ncoreIsPlaying(_core) == 1;
      final posMs = _bindings.ncoreGetPosition(_core);
      final durMs = _bindings.ncoreGetDuration(_core);

      playerState.updatePlaybackState(isPlaying);
      playerState.updatePosition(posMs);
      playerState.updateDuration(durMs);

      // Only fetch full track info when track changes
      final track = currentTrack;
      if (track.path != _lastTrackPath) {
        _lastTrackPath = track.path;
        playerState.updateTrack(track);
      }
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
