import 'package:flutter/services.dart';

class MediaSessionBridge {
  MediaSessionBridge._();
  static final MediaSessionBridge instance = MediaSessionBridge._();

  static const _channel = MethodChannel(
    'com.isaaccodesstuff.natsuyume/media_session',
  );

  /// Called once at app startup
  void init({required void Function(String command) onCommand}) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onCommand') {
        final command = call.arguments as String;
        onCommand(command);
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
