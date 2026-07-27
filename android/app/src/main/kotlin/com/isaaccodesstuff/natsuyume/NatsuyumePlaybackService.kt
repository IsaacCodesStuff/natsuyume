package com.isaaccodesstuff.natsuyume

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle

class NatsuyumePlaybackService : Service() {

    companion object {
        const val CHANNEL_ID = "natsuyume_playback"
        const val NOTIFICATION_ID = 1
        const val ACTION_PLAY   = "com.isaaccodesstuff.natsuyume.PLAY"
        const val ACTION_PAUSE  = "com.isaaccodesstuff.natsuyume.PAUSE"
        const val ACTION_NEXT   = "com.isaaccodesstuff.natsuyume.NEXT"
        const val ACTION_PREV   = "com.isaaccodesstuff.natsuyume.PREV"
        const val ACTION_STOP   = "com.isaaccodesstuff.natsuyume.STOP"
    }

    inner class LocalBinder : Binder() {
        fun getService(): NatsuyumePlaybackService = this@NatsuyumePlaybackService
    }

    private val binder = LocalBinder()
    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var notificationManager: NotificationManager
    private lateinit var audioManager: AudioManager
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasFocus = false

    private var currentTitle: String = "Natsuyume"
    private var currentArtist: String = ""
    private var currentAlbum: String = ""
    private var currentArtBytes: ByteArray? = null
    private var isPlaying: Boolean = false
    private var positionMs: Long = 0L
    private var durationMs: Long = 0L

    var onCommand: ((String) -> Unit)? = null

    // ── Audio focus listener ─────────────────────────────────────────────────

    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Resumed focus — play if we were playing before
                hasFocus = true
                onCommand?.invoke("play")
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                // Permanent loss (another player took over) — pause
                hasFocus = false
                onCommand?.invoke("pause")
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Temporary loss (phone call, navigation prompt) — pause
                hasFocus = false
                onCommand?.invoke("pause")
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Another app wants to briefly play a sound — pause rather than duck
                // since music ducking sounds bad for a music player
                hasFocus = false
                onCommand?.invoke("pause")
            }
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
        initMediaSession()
        startForeground(NOTIFICATION_ID, buildNotification())
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY  -> {
                if (requestAudioFocus()) onCommand?.invoke("play")
            }
            ACTION_PAUSE -> {
                onCommand?.invoke("pause")
                abandonAudioFocus()
            }
            ACTION_NEXT  -> onCommand?.invoke("next")
            ACTION_PREV  -> onCommand?.invoke("prev")
            ACTION_STOP  -> {
                onCommand?.invoke("stop")
                abandonAudioFocus()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // User swiped app from recents — pause and clean up
        onCommand?.invoke("pause")
        abandonAudioFocus()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        abandonAudioFocus()
        mediaSession.release()
        super.onDestroy()
    }

    // ── Public API ───────────────────────────────────────────────────────────

    fun updateState(
        title: String,
        artist: String,
        album: String,
        artBytes: ByteArray?,
        playing: Boolean,
        positionMs: Long,
        durationMs: Long
    ) {
        // Request focus when transitioning to playing
        if (playing && !isPlaying) {
            requestAudioFocus()
        }
        // Abandon focus when transitioning to paused
        if (!playing && isPlaying) {
            abandonAudioFocus()
        }

        currentTitle    = title
        currentArtist   = artist
        currentAlbum    = album
        currentArtBytes = artBytes
        isPlaying       = playing
        this.positionMs = positionMs
        this.durationMs = durationMs

        updateMediaSession()
        updateNotification()
    }

    // ── Audio focus ──────────────────────────────────────────────────────────

    private fun requestAudioFocus(): Boolean {
        if (hasFocus) return true

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener(focusChangeListener)
                .build()
            audioFocusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }

        hasFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        return hasFocus
    }

    private fun abandonAudioFocus() {
        if (!hasFocus) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusChangeListener)
        }
        hasFocus = false
    }

    // ── MediaSession ─────────────────────────────────────────────────────────

    private fun initMediaSession() {
        mediaSession = MediaSessionCompat(this, "NatsuyumeSession").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    if (requestAudioFocus()) onCommand?.invoke("play")
                }
                override fun onPause() {
                    onCommand?.invoke("pause")
                    abandonAudioFocus()
                }
                override fun onSkipToNext()     { onCommand?.invoke("next") }
                override fun onSkipToPrevious() { onCommand?.invoke("prev") }
                override fun onStop() {
                    onCommand?.invoke("stop")
                    abandonAudioFocus()
                }
                override fun onSeekTo(pos: Long) { onCommand?.invoke("seek:$pos") }
            })
            isActive = true
        }
    }

    private fun updateMediaSession() {
        val artBitmap: Bitmap? = currentArtBytes?.let {
            BitmapFactory.decodeByteArray(it, 0, it.size)
        }

        mediaSession.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE,  currentTitle)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
                .putString(MediaMetadataCompat.METADATA_KEY_ALBUM,  currentAlbum)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                .apply { artBitmap?.let {
                    putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, it)
                }}
                .build()
        )

        val state = if (isPlaying) PlaybackStateCompat.STATE_PLAYING
                    else           PlaybackStateCompat.STATE_PAUSED

        mediaSession.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(state, positionMs, if (isPlaying) 1f else 0f)
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
                )
                .build()
        )
    }

    // ── Notification ─────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Natsuyume Playback",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Music playback controls"
            setShowBadge(false)
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val artBitmap: Bitmap? = currentArtBytes?.let {
            BitmapFactory.decodeByteArray(it, 0, it.size)
        }

        val launchIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }
        val contentIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        fun actionIntent(action: String): PendingIntent {
            val i = Intent(this, NatsuyumePlaybackService::class.java).apply {
                this.action = action
            }
            val requestCode = when (action) {
                ACTION_PREV  -> 10
                ACTION_PLAY  -> 11
                ACTION_PAUSE -> 12
                ACTION_NEXT  -> 13
                ACTION_STOP  -> 14
                else         -> 99
            }
            return PendingIntent.getService(
                this, requestCode, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val playPauseIcon   = if (isPlaying) android.R.drawable.ic_media_pause
                              else           android.R.drawable.ic_media_play
        val playPauseAction = if (isPlaying) ACTION_PAUSE else ACTION_PLAY
        val playPauseLabel  = if (isPlaying) "Pause" else "Play"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSubText(currentAlbum)
            .setLargeIcon(artBitmap)
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(android.R.drawable.ic_media_previous, "Previous", actionIntent(ACTION_PREV))
            .addAction(playPauseIcon, playPauseLabel, actionIntent(playPauseAction))
            .addAction(android.R.drawable.ic_media_next, "Next", actionIntent(ACTION_NEXT))
            .setStyle(
                MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .build()
    }

    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }
}