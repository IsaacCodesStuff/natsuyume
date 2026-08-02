import 'package:flutter/services.dart';
import 'natsuyume_core.dart';

class MediaSessionBridge {
  MediaSessionBridge._();
  static final MediaSessionBridge instance = MediaSessionBridge._();

  static const _channel = MethodChannel(
    'com.isaaccodesstuff.natsuyume/media_session',
  );

  void init({required void Function(String command) onCommand}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCommand':
          final command = call.arguments as String;
          onCommand(command);
          break;
        case 'shutdown':
          NatsuyumeCore.instance.saveAndShutdown();
          break;
      }
    });
  }

  /// Push current playback state to Android.
  /// Call this from your existing poll loop.
  Future<void> updateState({
    required String title,
    required String artist,
    required String album,
    required Uint8List? artBytes,
    required bool playing,
    required Duration position,
    required Duration duration,
  }) async {
    await _channel.invokeMethod('updateState', {
      'title': title,
      'artist': artist,
      'album': album,
      'artBytes': artBytes,
      'playing': playing,
      'positionMs': position.inMilliseconds,
      'durationMs': duration.inMilliseconds,
    });
  }
}
