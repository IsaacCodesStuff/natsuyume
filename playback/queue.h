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

    int trackCount() const;
    Track trackAt(int index) const;
    QList<Track> tracks() const;

    // --- Playback control ---
    void play();
    void pause();
    void seekTo(qint64 positionMs);
    void loadTrackAt(int index, bool autoPlay = true);    void playNext();
    void playPrevious();

    // --- State save / restore ---
    void saveState();
    void restoreState();

    // --- Getters ---
    QString name() const;
    void setName(const QString &name);

    int currentTrackIndex() const;
    bool hasNext() const;
    bool hasPrevious() const;

    bool isPlaying() const;
    qint64 position() const;
    qint64 duration() const;

    qint64 savedPosition() const { return m_savedPosition; }

    // --- Repeat ---
    RepeatMode repeatMode() const;
    void cycleRepeatMode();

    // --- Shuffle ---
    bool isShuffled() const;
    void toggleShuffle();

    // --- Audio ---
    void moveTrack(int from, int to);

    void updateTrackStats(const QString &path, qint64 lastPlayed, int playCount);
    void addTrackSilent(const Track &track);

    // --- Stop after this song ---
    bool stopAfterCurrent() const;
    void setStopAfterCurrent(bool stop);

    void setVolume(float volume);
    Playback *playback() const;
    bool hasPlayback() const;
    void initPlayback();
    void destroyPlayback();

    void sortTracks(Library::TrackSort sort, bool ascending);
    void reverseTracks();

    void addTracksBatch(const QStringList &filePaths, bool autoPlayFirst = false);

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

private:
    friend class Player;
    QString m_name;
    QList<Track> m_tracks;
    int m_currentTrackIndex;
    Playback *m_playback = nullptr;
    float m_volume = 0.8f;
    // Saved state
    qint64 m_savedPosition;
    bool m_wasPlaying;
    // Repeat
    RepeatMode m_repeatMode;
    // Shuffle
    bool m_shuffled;
    QList<int> m_shuffleOrder;
    // Internal helpers
    void generateShuffleOrder();
    int nextShuffleIndex() const;
    int previousShuffleIndex() const;
    void connectPlaybackSignals();
    bool m_stopAfterCurrent = false;
};

#endif // QUEUE_H