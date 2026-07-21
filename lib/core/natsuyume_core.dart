import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'natsuyume_bindings.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class NatsuyumeCore {
  NatsuyumeCore._();
  static final NatsuyumeCore instance = NatsuyumeCore._();

  late final NatsuyumeBindings _bindings;
  late final Pointer<Void> _core;
  bool _initialized = false;

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

  void play() => _bindings.ncorePlay(_core);
  void pause() => _bindings.ncorePause(_core);
  void next() => _bindings.ncoreNext(_core);
  void previous() => _bindings.ncorePrevious(_core);
}
