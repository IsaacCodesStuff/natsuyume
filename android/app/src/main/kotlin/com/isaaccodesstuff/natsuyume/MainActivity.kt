package com.isaaccodesstuff.natsuyume

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.IBinder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.isaaccodesstuff.natsuyume/media_session"
    }

    private var playbackService: NatsuyumePlaybackService? = null
    private var isBound = false
    private var methodChannel: MethodChannel? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            val localBinder = binder as NatsuyumePlaybackService.LocalBinder
            playbackService = localBinder.getService()
            isBound = true

            playbackService?.onCommand = { command ->
                runOnUiThread {
                    methodChannel?.invokeMethod("onCommand", command)
                }
            }

            playbackService?.onShutdown = {
                runOnUiThread {
                    methodChannel?.invokeMethod("shutdown", null)
                }
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            playbackService = null
            isBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateState" -> {
                    val title      = call.argument<String>("title")      ?: ""
                    val artist     = call.argument<String>("artist")     ?: ""
                    val album      = call.argument<String>("album")      ?: ""
                    val artBytes   = call.argument<ByteArray>("artBytes")
                    val playing    = call.argument<Boolean>("playing")   ?: false
                    val positionMs = (call.argument<Number>("positionMs") ?: 0).toLong()
                    val durationMs = (call.argument<Number>("durationMs") ?: 0).toLong()

                    playbackService?.updateState(
                        title, artist, album, artBytes,
                        playing, positionMs, durationMs
                    )
                    result.success(null)
                }
                "startService" -> {
                    startPlaybackService()
                    result.success(null)
                }
                "stopService" -> {
                    stopPlaybackService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        startPlaybackService()
    }

    override fun onStop() {
        super.onStop()
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
    }

    private fun startPlaybackService() {
        val intent = Intent(this, NatsuyumePlaybackService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun stopPlaybackService() {
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
        stopService(Intent(this, NatsuyumePlaybackService::class.java))
    }
}