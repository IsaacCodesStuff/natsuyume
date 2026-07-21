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
  }
}
