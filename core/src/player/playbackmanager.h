#ifndef PLAYBACKMANAGER_H
#define PLAYBACKMANAGER_H

#include <string>
#include <vector>
#include <functional>
#include <cstdint>
#include "queuesession.h"
#include "lrcparser.h"
#include "library.h"
#include "userdatamanager.h"

class PlaybackManager
{
public:
    explicit PlaybackManager(QueueSession *session);

    void setLibrary(Library *library);
    void setUserDataManager(UserDataManager *mgr);

    // --- Callbacks ---
    std::function<void()> onIsPlayingChanged;
    std::function<void()> onPositionChanged;
    std::function<void()> onDurationChanged;
    std::function<void()> onVolumeChanged;
    std::function<void()> onMetadataChanged;
    std::function<void()> onRepeatModeChanged;
    std::function<void()> onShuffleChanged;
    std::function<void()> onStopAfterCurrentChanged;
    std::function<void()> onPlayingTrackChanged;
    std::function<void()> onIsFavoriteChanged;
    std::function<void()> onAbRepeatChanged;

    // --- Transport ---
    void play();
    void pause();
    void seekTo(int64_t positionMs);
    void playNext();
    void playPrevious();
    void cycleRepeatMode();
    void toggleShuffle();
    void toggleStopAfterCurrent();

    // --- Volume ---
    float volume() const;
    void  setVolume(float volume);

    // --- Playback state ---
    bool    isPlaying()        const;
    int64_t position()         const;
    int64_t duration()         const;
    int     repeatMode()       const;
    bool    isShuffled()       const;
    bool    stopAfterCurrent() const;

    // --- Now-playing metadata ---
    std::string              trackTitle()      const;
    std::string              trackArtist()     const;
    std::string              trackAlbum()      const;
    std::string              trackPath()       const;
    bool                     hasCoverArt()     const;
    std::string              rawLyrics()       const;
    std::vector<LrcLine>     lyricLines()      const;
    bool                     lyricsAreSynced() const;

    // --- Playing-queue navigation ---
    int  playingTrackIndex() const;
    int  playingTrackCount() const;
    bool hasPrevious()       const;
    bool hasNext()           const;

    // --- Play count ---
    int  playCountThreshold() const;
    void setPlayCountThreshold(int percent);

    // --- Settings ---
    void loadSettings(const std::string &dataDir);
    void saveSettings(const std::string &dataDir);

    // --- Playback wiring ---
    void initPlayback(int queueIndex);
    void destroyPlayback(int queueIndex);
    void restorePlaybackState(int queueIndex);
    void resetPlayCountState();

    Playback *activePlayback() const;

    // --- A-B repeat ---
    void    setPointA();
    void    setPointB();
    void    clearAbRepeat();
    bool    abRepeatActive() const;
    int64_t pointA()         const;
    int64_t pointB()         const;

private:
    QueueSession    *m_session;
    Library         *m_library         = nullptr;
    UserDataManager *m_userDataManager = nullptr;

    float   m_volume             = 0.8f;
    int     m_playCountThreshold = 10;
    bool    m_playCountCredited  = false;
    int64_t m_creditThresholdMs  = 0;
    bool    m_isSeeking          = false;
    bool    m_pendingGaplessAdvance = false;

    int64_t m_pointA         = -1;
    int64_t m_pointB         = -1;
    bool    m_abRepeatActive = false;

    std::vector<LrcLine> m_lyricLines;
    std::string          m_rawLyrics;

    std::string m_dataDir;

    void connectPlaybackCallbacks(Queue *queue);
    void connectCurrentPlaybackCallbacks(Queue *queue);
    void rebuildLyricLines();
};

#endif // PLAYBACKMANAGER_H