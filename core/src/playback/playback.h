#ifndef PLAYBACK_H
#define PLAYBACK_H

#include <mpv/client.h>
#include <functional>
#include <atomic>
#include <mutex>
#include <cstdint>
#include "track.h"
#include <thread>
#include <atomic>
#include <poll.h>

class Playback
{
public:
    Playback();
    ~Playback();

    // --- Controls ---
    void play();
    void pause();
    void loadTrack(const Track &track, bool autoPlay = false);
    void appendTrack(const Track &track);
    void seekTo(int64_t positionMs);
    void setVolume(float volume);
    void clearAppendedTrack();
    void setRepeatTrackPending(bool pending) { m_repeatTrackPending = pending; }

    // --- Getters ---
    bool    isPlaying() const { return m_isPlaying; }
    int64_t position()  const { return m_position;  }
    int64_t duration()  const { return m_duration;  }
    float   volume()    const { return m_volume;    }

    // --- Callbacks (set before use) ---
    std::function<void()> onPlaybackStateChanged;
    std::function<void()> onPositionChanged;
    std::function<void()> onDurationChanged;
    std::function<void()> onReadyToPlay;
    std::function<void()> onTrackEnded;
    std::function<void()> onTrackAdvancedGapless;

    // Called by the owner's event loop to drain pending mpv events.
    // Must be called on the main thread whenever the wakeup pipe is readable.
    void processPendingEvents();

    // File descriptor that becomes readable when mpv has events pending.
    // The owner should poll/select/epoll this and call processPendingEvents().
    int wakeupReadFd() const { return m_pipeFd[0]; }

private:
    mpv_handle *m_mpv = nullptr;

    float   m_volume   = 0.8f;
    bool    m_isPlaying       = false;
    bool    m_pendingAutoPlay = false;
    bool    m_processingEvents = false;
    bool    m_hasAppendedTrack = false;
    bool    m_gaplessAdvance   = false;
    bool    m_repeatTrackPending = false;
    int64_t m_position = 0;
    int64_t m_duration = 0;

    // Self-pipe for wakeup marshalling
    int m_pipeFd[2] = {-1, -1};

    void handleMpvEvent(mpv_event *event);
    void observeProperties();
    static void mpvWakeupCallback(void *ctx);

    std::thread m_eventThread;
    std::atomic<bool> m_eventThreadRunning{false};

    void startEventThread();
    void stopEventThread();
};

#endif // PLAYBACK_H