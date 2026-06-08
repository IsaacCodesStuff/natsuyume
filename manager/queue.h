#ifndef QUEUE_H
#define QUEUE_H

#include <QObject>
#include <QList>
#include "track.h"
#include "playback.h"
#include "metadata.h"

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
    void addTrack(const QString &filePath);
    void removeTrack(int index);
    void clearTracks();

    int trackCount() const;
    Track trackAt(int index) const;
    QList<Track> tracks() const;

    // --- Playback control ---
    void play();
    void pause();
    void seekTo(qint64 positionMs);
    void loadTrackAt(int index);
    void playNext();
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

    // --- Repeat ---
    RepeatMode repeatMode() const;
    void cycleRepeatMode();

    // --- Shuffle ---
    bool isShuffled() const;
    void toggleShuffle();

    // --- Audio ---
    void setVolume(float volume);

    Playback *playback() const;

    void moveTrack(int from, int to);

signals:
    void trackChanged();
    void queueChanged();
    void repeatModeChanged();
    void shuffleChanged();

private:
    QString m_name;
    QList<Track> m_tracks;
    int m_currentTrackIndex;

    Playback *m_playback;

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
};

#endif // QUEUE_H