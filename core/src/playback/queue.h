#ifndef QUEUE_H
#define QUEUE_H

#include <string>
#include <vector>
#include <functional>
#include <cstdint>
#include "track.h"
#include "playback.h"
#include "metadata.h"
#include "library.h"

class Queue
{
public:
    enum RepeatMode {
        NoRepeat,
        RepeatQueue,
        RepeatTrack
    };

    explicit Queue(const std::string &name);
    ~Queue();

    // --- Callbacks ---
    std::function<void()> onTrackChanged;
    std::function<void()> onQueueChanged;
    std::function<void()> onRepeatModeChanged;
    std::function<void()> onShuffleChanged;
    std::function<void()> onStopAfterCurrentChanged;
    std::function<void()> onRestoreCompleted;

    // --- Track management ---
    void addTrack(const std::string &filePath, bool autoPlayFirst = false);
    void addTracksBatch(const std::vector<std::string> &filePaths,
                        bool autoPlayFirst = false);
    void addTrackSilent(const Track &track);
    void removeTrack(int index);
    void clearTracks();
    int                  trackCount() const;
    Track                trackAt(int index) const;
    std::vector<Track>   tracks() const;

    // --- Playback control ---
    void play();
    void pause();
    void seekTo(int64_t positionMs);
    void loadTrackAt(int index, bool autoPlay = true);
    void playNext();
    void playPrevious();

    // --- Gapless ---
    Track peekNextTrack()  const;
    void  advancePlayback();

    // --- State save / restore ---
    void saveState();
    void restoreState();

    // --- Getters ---
    std::string name() const;
    void        setName(const std::string &name);
    int         currentTrackIndex() const;
    bool        hasNext()           const;
    bool        hasPrevious()       const;
    bool        isPlaying()         const;
    int64_t     position()          const;
    int64_t     duration()          const;
    int64_t     savedPosition()     const { return m_savedPosition; }

    // --- Repeat ---
    RepeatMode repeatMode() const;
    void       cycleRepeatMode();

    // --- Shuffle ---
    bool isShuffled() const;
    void toggleShuffle();

    // --- Audio ---
    void setVolume(float volume);

    // --- Track ops ---
    void moveTrack(int from, int to);
    void updateTrackStats(const std::string &path,
                          int64_t lastPlayed, int playCount);
    void sortTracks(Library::TrackSort sort, bool ascending);
    void reverseTracks();

    // --- Stop after current ---
    bool stopAfterCurrent() const;
    void setStopAfterCurrent(bool stop);

    // --- Playback accessors ---
    Playback *currentPlayback() const;
    bool      hasPlayback()     const;
    void      initPlayback();
    void      destroyPlayback();

    // --- State setters (used during restore) ---
    void setSavedPosition(int64_t position);
    void setWasPlaying(bool wasPlaying);
    void setCurrentTrackIndex(int index);

private:
    std::string        m_name;
    std::vector<Track> m_tracks;
    int                m_currentTrackIndex = -1;

    Playback *m_currentPlayback = nullptr;
    float     m_volume          = 0.8f;

    int64_t    m_savedPosition = 0;
    bool       m_wasPlaying    = false;
    RepeatMode m_repeatMode    = NoRepeat;
    bool       m_shuffled      = false;
    std::vector<int> m_shuffleOrder;
    bool       m_stopAfterCurrent = false;

    void generateShuffleOrder();
    int  nextShuffleIndex()     const;
    int  previousShuffleIndex() const;
    void connectPlaybackCallbacks();
};

#endif // QUEUE_H