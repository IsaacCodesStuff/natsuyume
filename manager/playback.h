#ifndef PLAYBACK_H
#define PLAYBACK_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
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
    void seekTo(qint64 positionMs);
    void loadTrack(const Track &track, bool autoPlay = false);

    // --- Getters ---
    bool isPlaying() const;
    qint64 position() const;
    qint64 duration() const;
    float volume() const;
    void setVolume(float volume);

    QAudioOutput *audioOutput() const;

signals:
    void playbackStateChanged();
    void positionChanged();
    void durationChanged();
    void trackLoaded(const Track &track);
    void readyToPlay();
    void trackEnded();

private:
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    bool m_pendingAutoPlay = false;
    QUrl m_expectedSource;
};

#endif // PLAYBACK_H