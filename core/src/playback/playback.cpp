#include "playback.h"
#include <QMetaObject>
#include <clocale>
#include <QDebug>

static inline void checkMpvError(int status, const char *context)
{
    if (status < 0)
        qWarning() << "mpv error in" << context << ":" << mpv_error_string(status);
}

Playback::Playback(QObject *parent)
    : QObject{parent}
{
    std::setlocale(LC_NUMERIC, "C");

    m_mpv = mpv_create();
    if (!m_mpv) {
        qWarning() << "Playback: failed to create mpv context";
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
}

Playback::~Playback()
{
    if (m_mpv) {
        mpv_terminate_destroy(m_mpv);
        m_mpv = nullptr;
    }
}

void Playback::mpvWakeupCallback(void *ctx)
{
    QMetaObject::invokeMethod(static_cast<Playback *>(ctx),
                              "onMpvEvents",
                              Qt::QueuedConnection);
}

void Playback::onMpvEvents()
{
    if (!m_mpv || m_processingEvents) return;
    m_processingEvents = true;

    while (true) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) break;
        handleMpvEvent(event);
    }

    m_processingEvents = false;
}

void Playback::handleMpvEvent(mpv_event *event)
{
    switch (event->event_id) {

    case MPV_EVENT_PROPERTY_CHANGE: {
        auto *prop = reinterpret_cast<mpv_event_property *>(event->data);

        if (strcmp(prop->name, "time-pos") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double secs = *reinterpret_cast<double *>(prop->data);
                qint64 ms   = static_cast<qint64>(secs * 1000.0);
                if (ms != m_position) {
                    m_position = ms;
                    emit positionChanged();
                }
            }
        } else if (strcmp(prop->name, "duration") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double secs = *reinterpret_cast<double *>(prop->data);
                qint64 ms   = static_cast<qint64>(secs * 1000.0);
                if (ms != m_duration) {
                    m_duration = ms;
                    emit durationChanged();
                }
            }
        } else if (strcmp(prop->name, "core-idle") == 0) {
            if (prop->format == MPV_FORMAT_FLAG) {
                bool idle       = *reinterpret_cast<int *>(prop->data) != 0;
                bool nowPlaying = !idle;
                if (nowPlaying != m_isPlaying) {
                    m_isPlaying = nowPlaying;
                    emit playbackStateChanged();
                }
            }
        } else if (strcmp(prop->name, "pause") == 0) {
            if (prop->format == MPV_FORMAT_FLAG) {
                bool paused     = *reinterpret_cast<int *>(prop->data) != 0;
                bool nowPlaying = !paused;
                if (nowPlaying != m_isPlaying) {
                    m_isPlaying = nowPlaying;
                    emit playbackStateChanged();
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
        emit readyToPlay();
        break;
    }

    case MPV_EVENT_END_FILE: {
        auto *ef = reinterpret_cast<mpv_event_end_file *>(event->data);
        if (ef->reason == MPV_END_FILE_REASON_EOF) {
            m_position = 0;
            if (m_hasAppendedTrack && !m_repeatTrackPending) {
                m_hasAppendedTrack = false;
                m_gaplessAdvance   = true;
                emit trackAdvancedGapless();
            } else {
                m_hasAppendedTrack   = false;
                m_repeatTrackPending = false;
                m_isPlaying          = false;
                emit trackEnded();
            }
        }
        break;
    }
    default:
        break;
    }
}

void Playback::observeProperties()
{
    checkMpvError(mpv_observe_property(m_mpv, 0, "time-pos",  MPV_FORMAT_DOUBLE), "observe time-pos");
    checkMpvError(mpv_observe_property(m_mpv, 0, "duration",  MPV_FORMAT_DOUBLE), "observe duration");
    checkMpvError(mpv_observe_property(m_mpv, 0, "core-idle", MPV_FORMAT_FLAG),   "observe core-idle");
    checkMpvError(mpv_observe_property(m_mpv, 0, "pause",     MPV_FORMAT_FLAG),   "observe pause");
}

void Playback::loadTrack(const Track &track, bool autoPlay)
{
    if (!track.isValid() || !m_mpv) return;

    m_pendingAutoPlay = autoPlay;
    m_position        = 0;
    m_duration        = 0;

    emit positionChanged();
    emit durationChanged();

    const QByteArray pathBytes = track.path.toUtf8();
    const char *args[] = { "loadfile", pathBytes.constData(), "replace", nullptr };
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

    const QByteArray pathBytes = track.path.toUtf8();
    const char *args[] = { "loadfile", pathBytes.constData(), "append", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "appendTrack");
}

void Playback::seekTo(qint64 positionMs)
{
    if (!m_mpv) return;

    double secs = positionMs / 1000.0;
    const QByteArray secsStr = QString::number(secs, 'f', 3).toUtf8();
    const char *args[] = { "seek", secsStr.constData(), "absolute", nullptr };
    checkMpvError(mpv_command_async(m_mpv, 0, args), "seek");
}

bool   Playback::isPlaying() const { return m_isPlaying; }
qint64 Playback::position()  const { return m_position; }
qint64 Playback::duration()  const { return m_duration; }
float  Playback::volume()    const { return m_volume; }

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