#ifndef PLAYBACK_H
#define PLAYBACK_H

#include <QObject>
#include <mpv/client.h>
#include "track.h"

class Playback : public QObject
{
    Q_OBJECT

public:
    explicit Playback(QObject *parent = nullptr);
    ~Playback();

    // --- Controls ---
    void play();
    void pause();
    void appendTrack(const Track &track);
    void seekTo(qint64 positionMs);
    void loadTrack(const Track &track, bool autoPlay = false);

    // --- Getters ---
    bool   isPlaying() const;
    qint64 position()  const;
    qint64 duration()  const;
    float  volume()    const;
    void   setVolume(float volume);

signals:
    void playbackStateChanged();
    void positionChanged();
    void durationChanged();
    void readyToPlay();
    void trackEnded();
    void trackAdvancedGapless();

private slots:
    void onMpvEvents();

private:
    mpv_handle *m_mpv = nullptr;
    float       m_volume = 0.8f;
    bool        m_pendingAutoPlay = false;
    bool        m_isPlaying = false;
    qint64      m_position  = 0;
    qint64      m_duration  = 0;

    void handleMpvEvent(mpv_event *event);
    void observeProperties();

    static void mpvWakeupCallback(void *ctx);
    bool m_hasAppendedTrack = false;
    bool m_gaplessAdvance = false;
};

#endif // PLAYBACK_H