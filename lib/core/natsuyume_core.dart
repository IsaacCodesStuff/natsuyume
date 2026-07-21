import 'package:ffi/ffi.dart';
import 'natsuyume_bindings.dart';

class NatsuyumeCore {
  NatsuyumeCore._();
  static final NatsuyumeCore instance = NatsuyumeCore._();

  late final NatsuyumeBindings _bindings;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _bindings = NatsuyumeBindings();
    _initialized = true;
  }

  // Phase 2A — version string from native core
  String get version {
    final ptr = _bindings.ncoreGetVersion();
    final str = ptr.toDartString();
    _bindings.ncoreFreeString(ptr);
    return str;
  }
}
