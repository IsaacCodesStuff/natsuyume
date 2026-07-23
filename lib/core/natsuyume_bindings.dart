import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Native function typedefs
// ---------------------------------------------------------------------------

// char* ncore_get_version()
typedef _NcoreGetVersionNative = Pointer<Utf8> Function();
typedef NcoreGetVersion = Pointer<Utf8> Function();

// void ncore_free_string(char*)
typedef _NcoreFreeStringNative = Void Function(Pointer<Utf8>);
typedef NcoreFreeString = void Function(Pointer<Utf8>);

// void ncore_set_data_dir(NatsuyumeCore*, const char*)
typedef _NcoreSetDataDirNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef NcoreSetDataDir = void Function(Pointer<Void>, Pointer<Utf8>);

// void* ncore_create()
typedef _NcoreCreateNative = Pointer<Void> Function();
typedef NcoreCreate = Pointer<Void> Function();

// void ncore_init(void*)
typedef _NcoreInitNative = Void Function(Pointer<Void>);
typedef NcoreInit = void Function(Pointer<Void>);

// void ncore_shutdown(void*)
typedef _NcoreShutdownNative = Void Function(Pointer<Void>);
typedef NcoreShutdown = void Function(Pointer<Void>);

// void ncore_open_file(NatsuyumeCore*, const char*)
typedef _NcoreOpenFileNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef NcoreOpenFile = void Function(Pointer<Void>, Pointer<Utf8>);

// void ncore_play(NatsuyumeCore*)
typedef _NcorePlayNative = Void Function(Pointer<Void>);
typedef NcorePlay = void Function(Pointer<Void>);

// void ncore_pause(NatsuyumeCore*)
typedef _NcorePauseNative = Void Function(Pointer<Void>);
typedef NcorePause = void Function(Pointer<Void>);

// void ncore_next(NatsuyumeCore*)
typedef _NcoreNextNative = Void Function(Pointer<Void>);
typedef NcoreNext = void Function(Pointer<Void>);

// void ncore_previous(NatsuyumeCore*)
typedef _NcorePreviousNative = Void Function(Pointer<Void>);
typedef NcorePrevious = void Function(Pointer<Void>);

// int ncore_is_playing(void*)
typedef _NcoreIsPlayingNative = Int32 Function(Pointer<Void>);
typedef NcoreIsPlaying = int Function(Pointer<Void>);

// int64_t ncore_get_position(void*)
typedef _NcoreGetPositionNative = Int64 Function(Pointer<Void>);
typedef NcoreGetPosition = int Function(Pointer<Void>);

// int64_t ncore_get_duration(void*)
typedef _NcoreGetDurationNative = Int64 Function(Pointer<Void>);
typedef NcoreGetDuration = int Function(Pointer<Void>);

// void ncore_get_current_track(void*, char**, char**, ...)
typedef _NcoreGetCurrentTrackNative =
    Void Function(
      Pointer<Void>,
      Pointer<Pointer<Utf8>>, // path
      Pointer<Pointer<Utf8>>, // title
      Pointer<Pointer<Utf8>>, // artist
      Pointer<Pointer<Utf8>>, // album
      Pointer<Pointer<Utf8>>, // album_artist
      Pointer<Pointer<Utf8>>, // genre
      Pointer<Int32>, // track_number
      Pointer<Int32>, // year
      Pointer<Int64>, // duration
      Pointer<Int32>, // play_count
      Pointer<Int32>, // is_favorite
    );
typedef NcoreGetCurrentTrack =
    void Function(
      Pointer<Void>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<Int64>,
      Pointer<Int32>,
      Pointer<Int32>,
    );

// Callback function types (Dart side)
typedef PlaybackStateCallback = void Function(int isPlaying);
typedef PositionCallback = void Function(int positionMs);
typedef DurationCallback = void Function(int durationMs);
typedef TrackChangedCallback = void Function();

// Native registration function typedefs
typedef _NcoreSetPlaybackStateCallbackNative =
    Void Function(Pointer<Void>, Pointer<NativeFunction<Void Function(Int32)>>);
typedef NcoreSetPlaybackStateCallback =
    void Function(Pointer<Void>, Pointer<NativeFunction<Void Function(Int32)>>);

typedef _NcoreSetPositionCallbackNative =
    Void Function(Pointer<Void>, Pointer<NativeFunction<Void Function(Int64)>>);
typedef NcoreSetPositionCallback =
    void Function(Pointer<Void>, Pointer<NativeFunction<Void Function(Int64)>>);

typedef _NcoreSetDurationCallbackNative =
    Void Function(Pointer<Void>, Pointer<NativeFunction<Void Function(Int64)>>);
typedef NcoreSetDurationCallback =
    void Function(Pointer<Void>, Pointer<NativeFunction<Void Function(Int64)>>);

typedef _NcoreSetTrackChangedCallbackNative =
    Void Function(Pointer<Void>, Pointer<NativeFunction<Void Function()>>);
typedef NcoreSetTrackChangedCallback =
    void Function(Pointer<Void>, Pointer<NativeFunction<Void Function()>>);

// void ncore_drain_library_callbacks(NatsuyumeCore*)
typedef _NcoreDrainLibraryCallbacksNative = Void Function(Pointer<Void>);
typedef NcoreDrainLibraryCallbacks = void Function(Pointer<Void>);

// int ncore_is_scanning(NatsuyumeCore*)
typedef _NcoreIsScanningNative = Int32 Function(Pointer<Void>);
typedef NcoreIsScanning = int Function(Pointer<Void>);

// int ncore_scan_progress(NatsuyumeCore*)
typedef _NcoreScanProgressNative = Int32 Function(Pointer<Void>);
typedef NcoreScanProgress = int Function(Pointer<Void>);

// int ncore_scan_total(NatsuyumeCore*)
typedef _NcoreScanTotalNative = Int32 Function(Pointer<Void>);
typedef NcoreScanTotal = int Function(Pointer<Void>);

// void ncore_add_scan_folder(NatsuyumeCore*, const char*)
typedef _NcoreAddScanFolderNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef NcoreAddScanFolder = void Function(Pointer<Void>, Pointer<Utf8>);

// void ncore_scan_library(NatsuyumeCore*)
typedef _NcoreScanLibraryNative = Void Function(Pointer<Void>);
typedef NcoreScanLibrary = void Function(Pointer<Void>);

// void ncore_remove_scan_folder(NatsuyumeCore*, const char*)
typedef _NcoreRemoveScanFolderNative =
    Void Function(Pointer<Void>, Pointer<Utf8>);
typedef NcoreRemoveScanFolder = void Function(Pointer<Void>, Pointer<Utf8>);

// void ncore_cancel_scan(NatsuyumeCore*)
typedef _NcoreCancelScanNative = Void Function(Pointer<Void>);
typedef NcoreCancelScan = void Function(Pointer<Void>);

// char* ncore_get_queue_json(NatsuyumeCore*)
typedef _NcoreGetQueueJsonNative = Pointer<Utf8> Function(Pointer<Void>);
typedef NcoreGetQueueJson = Pointer<Utf8> Function(Pointer<Void>);

// char* ncore_get_albums_json(NatsuyumeCore*)
typedef _NcoreGetAlbumsJsonNative = Pointer<Utf8> Function(Pointer<Void>);
typedef NcoreGetAlbumsJson = Pointer<Utf8> Function(Pointer<Void>);

// char* ncore_get_artists_json(NatsuyumeCore*)
typedef _NcoreGetArtistsJsonNative = Pointer<Utf8> Function(Pointer<Void>);
typedef NcoreGetArtistsJson = Pointer<Utf8> Function(Pointer<Void>);

// char* ncore_get_album_tracks_json(NatsuyumeCore*, const char*)
typedef _NcoreGetAlbumTracksJsonNative =
    Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef NcoreGetAlbumTracksJson =
    Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);

// char* ncore_get_artist_albums_json(NatsuyumeCore*, const char*)
typedef _NcoreGetArtistAlbumsJsonNative =
    Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef NcoreGetArtistAlbumsJson =
    Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);

// void ncore_open_paths_in_new_queue(NatsuyumeCore*, const char*, int)
typedef _NcoreOpenPathsInNewQueueNative =
    Void Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef NcoreOpenPathsInNewQueue =
    void Function(Pointer<Void>, Pointer<Utf8>, int);

// void ncore_seek(NatsuyumeCore*, double position_seconds)
typedef _NcoreSeekNative = Void Function(Pointer<Void>, Double);
typedef NcoreSeek = void Function(Pointer<Void>, double);

// ---------------------------------------------------------------------------
// NatsuyumeBindings — loads libnatsuyume_bridge.so and binds symbols
// ---------------------------------------------------------------------------
class NatsuyumeBindings {
  late final DynamicLibrary _lib;

  late final NcoreGetVersion ncoreGetVersion;
  late final NcoreFreeString ncoreFreeString;

  late final NcoreCreate ncoreCreate;
  late final NcoreInit ncoreInit;
  late final NcoreShutdown ncoreShutdown;
  late final NcoreSetDataDir ncoreSetDataDir;

  late final NcoreOpenFile ncoreOpenFile;
  late final NcorePlay ncorePlay;
  late final NcorePause ncorePause;
  late final NcoreNext ncoreNext;
  late final NcorePrevious ncorePrevious;

  late final NcoreIsPlaying ncoreIsPlaying;
  late final NcoreGetPosition ncoreGetPosition;
  late final NcoreGetDuration ncoreGetDuration;
  late final NcoreGetCurrentTrack ncoreGetCurrentTrack;

  late final NcoreSetPlaybackStateCallback ncoreSetPlaybackStateCallback;
  late final NcoreSetPositionCallback ncoreSetPositionCallback;
  late final NcoreSetDurationCallback ncoreSetDurationCallback;
  late final NcoreSetTrackChangedCallback ncoreSetTrackChangedCallback;

  late final NcoreDrainLibraryCallbacks ncoreDrainLibraryCallbacks;
  late final NcoreIsScanning ncoreIsScanning;
  late final NcoreScanProgress ncoreScanProgress;
  late final NcoreScanTotal ncoreScanTotal;
  late final NcoreRemoveScanFolder ncoreRemoveScanFolder;
  late final NcoreCancelScan ncoreCancelScan;
  late final NcoreAddScanFolder ncoreAddScanFolder;
  late final NcoreScanLibrary ncoreScanLibrary;

  late final NcoreGetQueueJson ncoreGetQueueJson;
  late final NcoreGetAlbumsJson ncoreGetAlbumsJson;
  late final NcoreGetArtistsJson ncoreGetArtistsJson;
  late final NcoreGetAlbumTracksJson ncoreGetAlbumTracksJson;
  late final NcoreGetArtistAlbumsJson ncoreGetArtistAlbumsJson;
  late final NcoreOpenPathsInNewQueue ncoreOpenPathsInNewQueue;

  late final NcoreSeek ncoreSeek;

  NatsuyumeBindings() {
    _lib = DynamicLibrary.open('libnatsuyume_bridge.so');

    ncoreGetVersion = _lib
        .lookup<NativeFunction<_NcoreGetVersionNative>>('ncore_get_version')
        .asFunction();

    ncoreFreeString = _lib
        .lookup<NativeFunction<_NcoreFreeStringNative>>('ncore_free_string')
        .asFunction();

    ncoreCreate = _lib
        .lookup<NativeFunction<_NcoreCreateNative>>('ncore_create')
        .asFunction();

    ncoreInit = _lib
        .lookup<NativeFunction<_NcoreInitNative>>('ncore_init')
        .asFunction();

    ncoreShutdown = _lib
        .lookup<NativeFunction<_NcoreShutdownNative>>('ncore_shutdown')
        .asFunction();

    ncoreSetDataDir = _lib
        .lookup<NativeFunction<_NcoreSetDataDirNative>>('ncore_set_data_dir')
        .asFunction();

    ncoreOpenFile = _lib
        .lookup<NativeFunction<_NcoreOpenFileNative>>('ncore_open_file')
        .asFunction();

    ncorePlay = _lib
        .lookup<NativeFunction<_NcorePlayNative>>('ncore_play')
        .asFunction();

    ncorePause = _lib
        .lookup<NativeFunction<_NcorePauseNative>>('ncore_pause')
        .asFunction();

    ncoreNext = _lib
        .lookup<NativeFunction<_NcoreNextNative>>('ncore_next')
        .asFunction();

    ncorePrevious = _lib
        .lookup<NativeFunction<_NcorePreviousNative>>('ncore_previous')
        .asFunction();

    ncoreIsPlaying = _lib
        .lookup<NativeFunction<_NcoreIsPlayingNative>>('ncore_is_playing')
        .asFunction();

    ncoreGetPosition = _lib
        .lookup<NativeFunction<_NcoreGetPositionNative>>('ncore_get_position')
        .asFunction();

    ncoreGetDuration = _lib
        .lookup<NativeFunction<_NcoreGetDurationNative>>('ncore_get_duration')
        .asFunction();

    ncoreGetCurrentTrack = _lib
        .lookup<NativeFunction<_NcoreGetCurrentTrackNative>>(
          'ncore_get_current_track',
        )
        .asFunction();

    ncoreSetPlaybackStateCallback = _lib
        .lookup<NativeFunction<_NcoreSetPlaybackStateCallbackNative>>(
          'ncore_set_playback_state_callback',
        )
        .asFunction();

    ncoreSetPositionCallback = _lib
        .lookup<NativeFunction<_NcoreSetPositionCallbackNative>>(
          'ncore_set_position_callback',
        )
        .asFunction();

    ncoreSetDurationCallback = _lib
        .lookup<NativeFunction<_NcoreSetDurationCallbackNative>>(
          'ncore_set_duration_callback',
        )
        .asFunction();

    ncoreSetTrackChangedCallback = _lib
        .lookup<NativeFunction<_NcoreSetTrackChangedCallbackNative>>(
          'ncore_set_track_changed_callback',
        )
        .asFunction();

    ncoreDrainLibraryCallbacks = _lib
        .lookup<NativeFunction<_NcoreDrainLibraryCallbacksNative>>(
          'ncore_drain_library_callbacks',
        )
        .asFunction();

    ncoreIsScanning = _lib
        .lookup<NativeFunction<_NcoreIsScanningNative>>('ncore_is_scanning')
        .asFunction();

    ncoreScanProgress = _lib
        .lookup<NativeFunction<_NcoreScanProgressNative>>('ncore_scan_progress')
        .asFunction();

    ncoreScanTotal = _lib
        .lookup<NativeFunction<_NcoreScanTotalNative>>('ncore_scan_total')
        .asFunction();

    ncoreRemoveScanFolder = _lib
        .lookup<NativeFunction<_NcoreRemoveScanFolderNative>>(
          'ncore_remove_scan_folder',
        )
        .asFunction();

    ncoreCancelScan = _lib
        .lookup<NativeFunction<_NcoreCancelScanNative>>('ncore_cancel_scan')
        .asFunction();

    ncoreAddScanFolder = _lib
        .lookup<NativeFunction<_NcoreAddScanFolderNative>>(
          'ncore_add_scan_folder',
        )
        .asFunction();

    ncoreScanLibrary = _lib
        .lookup<NativeFunction<_NcoreScanLibraryNative>>('ncore_scan_library')
        .asFunction();

    ncoreGetQueueJson = _lib
        .lookup<NativeFunction<_NcoreGetQueueJsonNative>>(
          'ncore_get_queue_json',
        )
        .asFunction();

    ncoreGetAlbumsJson = _lib
        .lookup<NativeFunction<_NcoreGetAlbumsJsonNative>>(
          'ncore_get_albums_json',
        )
        .asFunction();

    ncoreGetArtistsJson = _lib
        .lookup<NativeFunction<_NcoreGetArtistsJsonNative>>(
          'ncore_get_artists_json',
        )
        .asFunction();

    ncoreGetAlbumTracksJson = _lib
        .lookup<NativeFunction<_NcoreGetAlbumTracksJsonNative>>(
          'ncore_get_album_tracks_json',
        )
        .asFunction();

    ncoreGetArtistAlbumsJson = _lib
        .lookup<NativeFunction<_NcoreGetArtistAlbumsJsonNative>>(
          'ncore_get_artist_albums_json',
        )
        .asFunction();

    ncoreOpenPathsInNewQueue = _lib
        .lookup<NativeFunction<_NcoreOpenPathsInNewQueueNative>>(
          'ncore_open_paths_in_new_queue',
        )
        .asFunction();

    ncoreSeek = _lib
        .lookup<NativeFunction<_NcoreSeekNative>>('ncore_seek')
        .asFunction();
  }
}
