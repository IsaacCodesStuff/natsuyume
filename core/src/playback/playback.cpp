#include "playback.h"
#include <clocale>
#include <cstring>
#include <cstdio>
#include <unistd.h>
#include <cerrno>
#include <thread>
#include <atomic>

static void checkMpvError(int status, const char *context)
{
    if (status < 0)
        fprintf(stderr, "mpv error in %s: %s\n",
                context, mpv_error_string(status));
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

Playback::Playback()
{
    // Required before mpv_create()
    std::setlocale(LC_NUMERIC, "C");

    // Self-pipe for wakeup marshalling
    if (pipe(m_pipeFd) != 0) {
        fprintf(stderr, "Playback: pipe() failed: %s\n", strerror(errno));
        m_pipeFd[0] = m_pipeFd[1] = -1;
    }

    m_mpv = mpv_create();
    if (!m_mpv) {
        fprintf(stderr, "Playback: failed to create mpv context\n");
        return;
    }

    checkMpvError(mpv_set_option_string(m_mpv, "vo",            "null"), "vo");
    checkMpvError(mpv_set_option_string(m_mpv, "vid",           "no"),   "vid");
    checkMpvError(mpv_set_option_string(m_mpv, "audio-display", "no"),   "audio-display");
    checkMpvError(mpv_set_option_string(m_mpv, "terminal",      "no"),   "terminal");
    checkMpvError(mpv_set_option_string(m_mpv, "gapless-audio", "yes"),  "gapless-audio");
    checkMpvError(mpv_set_option_string(m_mpv, "idle",          "yes"),  "idle");
    checkMpvError(mpv_initialize(m_mpv), "mpv_initialize");

    mpv_set_wakeup_callback(m_mpv, mpvWakeupCallback, this);
    observeProperties();
    startEventThread();
}

Playback::~Playback()
{
    stopEventThread(); // must be before mpv_terminate_destroy
    if (m_mpv) {
        mpv_terminate_destroy(m_mpv);
        m_mpv = nullptr;
    }
    if (m_pipeFd[0] != -1) { close(m_pipeFd[0]); m_pipeFd[0] = -1; }
    if (m_pipeFd[1] != -1) { close(m_pipeFd[1]); m_pipeFd[1] = -1; }
}

// ---------------------------------------------------------------------------
// Wakeup marshalling
// ---------------------------------------------------------------------------

void Playback::mpvWakeupCallback(void *ctx)
{
    // Called on mpv's internal thread — only safe operation is writing a byte
    auto *self = static_cast<Playback *>(ctx);
    if (self->m_pipeFd[1] != -1) {
        char byte = 1;
        write(self->m_pipeFd[1], &byte, 1);
    }
}

void Playback::processPendingEvents()
{
    if (!m_mpv || m_processingEvents) return;
    m_processingEvents = true;

    // Drain the pipe
    if (m_pipeFd[0] != -1) {
        char buf[64];
        while (read(m_pipeFd[0], buf, sizeof(buf)) > 0) {}
    }

    // Drain mpv event queue
    while (true) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) break;
        handleMpvEvent(event);
    }

    m_processingEvents = false;
}

// ---------------------------------------------------------------------------
// Event handling
// ---------------------------------------------------------------------------

void Playback::observeProperties()
{
    checkMpvError(mpv_observe_property(m_mpv, 0, "time-pos",  MPV_FORMAT_DOUBLE), "observe time-pos");
    checkMpvError(mpv_observe_property(m_mpv, 0, "duration",  MPV_FORMAT_DOUBLE), "observe duration");
    checkMpvError(mpv_observe_property(m_mpv, 0, "core-idle", MPV_FORMAT_FLAG),   "observe core-idle");
    checkMpvError(mpv_observe_property(m_mpv, 0, "pause",     MPV_FORMAT_FLAG),   "observe pause");
}

void Playback::handleMpvEvent(mpv_event *event)
{
    switch (event->event_id) {

    case MPV_EVENT_PROPERTY_CHANGE: {
        auto *prop = reinterpret_cast<mpv_event_property *>(event->data);

        if (strcmp(prop->name, "time-pos") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double secs = *reinterpret_cast<double *>(prop->data);
                int64_t ms  = static_cast<int64_t>(secs * 1000.0);
                if (ms != m_position) {
                    m_position = ms;
                    if (onPositionChanged) onPositionChanged();
                }
            }
        } else if (strcmp(prop->name, "duration") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double secs = *reinterpret_cast<double *>(prop->data);
                int64_t ms  = static_cast<int64_t>(secs * 1000.0);
                if (ms != m_duration) {
                    m_duration = ms;
                    if (onDurationChanged) onDurationChanged();
                }
            }
        } else if (strcmp(prop->name, "core-idle") == 0) {
            if (prop->format == MPV_FORMAT_FLAG) {
                bool idle       = *reinterpret_cast<int *>(prop->data) != 0;
                bool nowPlaying = !idle;
                if (nowPlaying != m_isPlaying) {
                    m_isPlaying = nowPlaying;
                    if (onPlaybackStateChanged) onPlaybackStateChanged();
                }
            }
        } else if (strcmp(prop->name, "pause") == 0) {
            if (prop->format == MPV_FORMAT_FLAG) {
                bool paused     = *reinterpret_cast<int *>(prop->data) != 0;
                bool nowPlaying = !paused;
                if (nowPlaying != m_isPlaying) {
                    m_isPlaying = nowPlaying;
                    if (onPlaybackStateChanged) onPlaybackStateChanged();
                }
            }
        }
        break;
    }

    case MPV_EVENT_FILE_LOADED: {
        if (m_gaplessAdvance) {
            m_gaplessAdvance  = false;
            m_pendingAutoPlay = false;
        } else if (m_pendingAutoPlay) {
            m_pendingAutoPlay = false;
            const char *args[] = { "set", "pause", "no", nullptr };
            mpv_command_async(m_mpv, 0, args);
        } else {
            m_pendingAutoPlay = false;
            const char *args[] = { "set", "pause", "yes", nullptr };
            mpv_command_async(m_mpv, 0, args);
        }
        if (onReadyToPlay) onReadyToPlay();
        break;
    }

    case MPV_EVENT_END_FILE: {
        auto *ef = reinterpret_cast<mpv_event_end_file *>(event->data);
        if (ef->reason == MPV_END_FILE_REASON_EOF) {
            m_position = 0;
            if (m_hasAppendedTrack && !m_repeatTrackPending) {
                m_hasAppendedTrack = false;
                m_gaplessAdvance   = true;
                if (onTrackAdvancedGapless) onTrackAdvancedGapless();
            } else {
                m_hasAppendedTrack   = false;
                m_repeatTrackPending = false;
                m_isPlaying          = false;
                if (onTrackEnded) onTrackEnded();
            }
        }
        break;
    }

    default:
        break;
    }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

void Playback::loadTrack(const Track &track, bool autoPlay)
{
    if (!track.isValid() || !m_mpv) return;

    m_pendingAutoPlay = autoPlay;
    m_position        = 0;
    m_duration        = 0;

    if (onPositionChanged) onPositionChanged();
    if (onDurationChanged) onDurationChanged();

    const char *args[] = { "loadfile", track.path.c_str(), "replace", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "loadfile");
}

void Playback::play()
{
    if (!m_mpv) return;
    const char *args[] = { "set", "pause", "no", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "play");
}

void Playback::pause()
{
    if (!m_mpv) return;
    const char *args[] = { "set", "pause", "yes", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "pause");
}

void Playback::appendTrack(const Track &track)
{
    if (!track.isValid() || !m_mpv) return;
    m_hasAppendedTrack = true;
    m_gaplessAdvance   = false;

    const char *args[] = { "loadfile", track.path.c_str(), "append", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "appendTrack");
}

void Playback::seekTo(int64_t positionMs)
{
    if (!m_mpv) return;
    char secsStr[32];
    snprintf(secsStr, sizeof(secsStr), "%.3f", positionMs / 1000.0);
    const char *args[] = { "seek", secsStr, "absolute", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "seek");
}

void Playback::setVolume(float volume)
{
    if (!m_mpv) return;
    m_volume = volume;
    double mpvVolume = static_cast<double>(volume) * 100.0;
    checkMpvError(
        mpv_set_property_async(m_mpv, 0, "volume", MPV_FORMAT_DOUBLE, &mpvVolume),
        "setVolume");
}

void Playback::clearAppendedTrack()
{
    if (!m_mpv) return;
    m_hasAppendedTrack = false;
    const char *args[] = { "playlist-clear", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "playlist-clear");
}

void Playback::startEventThread()
{
    m_eventThreadRunning = true;
    m_eventThread = std::thread([this]() {
        while (m_eventThreadRunning) {
            // Block until mpv wakes us up, timeout 100ms
            struct pollfd pfd = { m_pipeFd[0], POLLIN, 0 };
            int ret = ::poll(&pfd, 1, 100);
            if (ret > 0 && m_eventThreadRunning)
                processPendingEvents();
        }
    });
}

void Playback::stopEventThread()
{
    m_eventThreadRunning = false;
    // Wake the thread so it exits
    if (m_pipeFd[1] != -1) {
        char byte = 1;
        write(m_pipeFd[1], &byte, 1);
    }
    if (m_eventThread.joinable())
        m_eventThread.join();
}