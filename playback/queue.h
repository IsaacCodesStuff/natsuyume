#ifndef QUEUE_H
#define QUEUE_H

#include <QObject>
#include <QList>
#include "track.h"
#include "playback.h"
#include "metadata.h"
#include "library.h"

class Queue : public QObject
{
    Q_OBJECT

public:
    enum RepeatMode {
        NoRepeat,
        RepeatQueue,
        RepeatTrack
    };

    explicit Queue(const QString &name, QObject *parent = nullptr);
    ~Queue();

    // --- Track management ---
    void addTrack(const QString &filePath, bool autoPlayFirst = false);
    void removeTrack(int index);
    void clearTracks();
    int          trackCount() const;
    Track        trackAt(int index) const;
    QList<Track> tracks() const;

    // --- Playback control ---
    void play();
    void pause();
    void seekTo(qint64 positionMs);
    void loadTrackAt(int index, bool autoPlay = true);
    void playNext();
    void playPrevious();

    // --- Gapless playback ---
    Track    peekNextTrack()    const; // read-only, no mutation
    void     preloadNextTrack();       // loads peekNextTrack() into m_preloadPlayback
    void     swapPlayback();           // swaps current <-> preload pointers + indices
    void     advancePlayback();        // advances m_currentTrackIndex to m_preloadTrackIndex

    // --- State save / restore ---
    void saveState();
    void restoreState();

    // --- Getters ---
    QString name() const;
    void    setName(const QString &name);
    int     currentTrackIndex() const;
    bool    hasNext()           const;
    bool    hasPrevious()       const;
    bool    isPlaying()         const;
    qint64  position()          const;
    qint64  duration()          const;
    qint64  savedPosition()     const { return m_savedPosition; }

    // --- Repeat ---
    RepeatMode repeatMode() const;
    void       cycleRepeatMode();

    // --- Shuffle ---
    bool isShuffled() const;
    void toggleShuffle();

    // --- Audio ---
    void setVolume(float volume);
    void moveTrack(int from, int to);
    void updateTrackStats(const QString &path, qint64 lastPlayed, int playCount);
    void addTrackSilent(const Track &track);

    // --- Stop after this song ---
    bool stopAfterCurrent() const;
    void setStopAfterCurrent(bool stop);

    // --- Playback accessors ---
    Playback *currentPlayback()  const; // renamed from playback()
    Playback *preloadPlayback()  const;
    bool      hasPlayback()      const;
    void      initPlayback();
    void      destroyPlayback();

    // --- Sort ---
    void sortTracks(Library::TrackSort sort, bool ascending);
    void reverseTracks();
    void addTracksBatch(const QStringList &filePaths, bool autoPlayFirst = false);

    // --- State setters (used by QueueManager during restore) ---
    void setSavedPosition(qint64 position);
    void setWasPlaying(bool wasPlaying);
    void setCurrentTrackIndex(int index);

signals:
    void trackChanged();
    void queueChanged();
    void repeatModeChanged();
    void shuffleChanged();
    void stopAfterCurrentChanged();
    void restoreCompleted();
    void readyToSwap(); // emitted when track ends and preload slot is ready
    // PlaybackManager connects to this to orchestrate gapless swap

private:
    QString      m_name;
    QList<Track> m_tracks;
    int          m_currentTrackIndex;

    Playback *m_currentPlayback  = nullptr; // renamed from m_playback
    Playback *m_preloadPlayback  = nullptr; // new — holds next track pre-decoded
    int       m_preloadTrackIndex = -1;     // which track index is in the preload slot

    float m_volume = 0.8f;

    // Saved state
    qint64 m_savedPosition;
    bool   m_wasPlaying;

    // Repeat
    RepeatMode m_repeatMode;

    // Shuffle
    bool       m_shuffled;
    QList<int> m_shuffleOrder;

    // Stop after current
    bool m_stopAfterCurrent = false;

    // Internal helpers
    void generateShuffleOrder();
    int  nextShuffleIndex()     const;
    int  previousShuffleIndex() const;
    void connectCurrentPlaybackSignals(); // renamed from connectPlaybackSignals
};

#endif // QUEUE_H