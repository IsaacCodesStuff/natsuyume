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

// ---------------------------------------------------------------------------
// NatsuyumeBindings — loads libnatsuyume_bridge.so and binds symbols
// ---------------------------------------------------------------------------
class NatsuyumeBindings {
  late final DynamicLibrary _lib;

  late final NcoreGetVersion ncoreGetVersion;
  late final NcoreFreeString ncoreFreeString;

  NatsuyumeBindings() {
    _lib = DynamicLibrary.open('libnatsuyume_bridge.so');

    ncoreGetVersion = _lib
        .lookup<NativeFunction<_NcoreGetVersionNative>>('ncore_get_version')
        .asFunction();

    ncoreFreeString = _lib
        .lookup<NativeFunction<_NcoreFreeStringNative>>('ncore_free_string')
        .asFunction();
  }
}
