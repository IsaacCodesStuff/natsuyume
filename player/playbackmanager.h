#ifndef PLAYBACKMANAGER_H
#define PLAYBACKMANAGER_H

#include <QObject>
#include <QVariantList>
#include "queuesession.h"
#include "coverimageprovider.h"
#include "lrcparser.h"
#include "library.h"

class PlaybackManager : public QObject
{
    Q_OBJECT

public:
    explicit PlaybackManager(QueueSession *session, QObject *parent = nullptr);

    void setLibrary(Library *library);
    void setCoverImageProvider(CoverImageProvider *provider);

    // --- Transport ---
    void play();
    void pause();
    void seekTo(qint64 positionMs);
    void playNext();
    void playPrevious();
    void cycleRepeatMode();
    void toggleShuffle();
    void toggleStopAfterCurrent();

    // --- Volume ---
    float volume() const;
    void  setVolume(float volume);

    // --- Playback state getters ---
    bool   isPlaying()        const;
    qint64 position()         const;
    qint64 duration()         const;
    int    repeatMode()       const;
    bool   isShuffled()       const;
    bool   stopAfterCurrent() const;

    // --- Now-playing metadata ---
    QString      trackTitle()  const;
    QString      trackArtist() const;
    QString      trackAlbum()  const;
    QString      trackPath()   const;
    bool         hasCoverArt() const;
    QString      rawLyrics()   const;
    QVariantList lyricLines()  const;
    bool         lyricsAreSynced() const;

    // --- Playing-queue track navigation ---
    int  playingTrackIndex() const;
    int  playingTrackCount() const;
    bool hasPrevious()       const;
    bool hasNext()           const;

    // --- Play count ---
    int  playCountThreshold() const;
    void setPlayCountThreshold(int percent);

    // --- Settings ---
    void loadSettings();
    void saveSettings();

    // --- Playback wiring ---
    // Called by PlayerController when a queue gains/loses playback ownership
    void initPlayback(int queueIndex);
    void destroyPlayback(int queueIndex);
    void restorePlaybackState(int queueIndex);
    void resetPlayCountState();

    // Returns whichever Playback instance is currently active.
    // Today this is always the playing queue's single Playback;
    // in 0.4.x this will return whichever of the two ping-pong
    // players is currently playing rather than preloading.
    Playback *activePlayback() const;

    // --- A-B Repeat ---
    Q_INVOKABLE void setPointA();
    Q_INVOKABLE void setPointB();
    Q_INVOKABLE void clearAbRepeat();
    bool   abRepeatActive() const;
    qint64 pointA()         const;
    qint64 pointB()         const;

signals:
    void isPlayingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void metadataChanged();
    void coverArtChanged();
    void repeatModeChanged();
    void shuffleChanged();
    void stopAfterCurrentChanged();
    void playingTrackChanged();
    void isFavoriteChanged();
    void abRepeatChanged();

private:
    QueueSession       *m_session;
    Library            *m_library  = nullptr;
    CoverImageProvider *m_coverImageProvider = nullptr;

    float  m_volume             = 0.8f;
    int    m_playCountThreshold = 10;
    bool   m_playCountCredited  = false;
    qint64 m_creditThresholdMs  = 0;

    QList<LrcLine> m_lyricLines;
    QString        m_rawLyrics;

    void connectPlaybackSignals(Queue *queue);
    void rebuildLyricLines();
    void pushCoverArt();
    bool m_isSeeking = false;

    void connectCurrentPlaybackSignals(Queue *queue);

    qint64 m_pointA         = -1;
    qint64 m_pointB         = -1;
    bool   m_abRepeatActive = false;

    bool m_pendingGaplessAdvance = false;
};

#endif // PLAYBACKMANAGER_H