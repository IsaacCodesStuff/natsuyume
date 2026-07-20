#include "playbackmanager.h"
#include "metadata.h"
#include <chrono>
#include <sqlite3.h>

static int64_t nowSeconds()
{
    return std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

PlaybackManager::PlaybackManager(QueueSession *session)
    : m_session(session)
{}

void PlaybackManager::setLibrary(Library *library)         { m_library = library; }
void PlaybackManager::setUserDataManager(UserDataManager *mgr) { m_userDataManager = mgr; }

// ---------------------------------------------------------------------------
// Settings (SQLite key-value in userdata.db)
// ---------------------------------------------------------------------------

void PlaybackManager::loadSettings(const std::string &dataDir)
{
    m_dataDir = dataDir;
    std::string dbPath = dataDir + "/userdata.db";
    sqlite3 *db = nullptr;
    if (sqlite3_open(dbPath.c_str(), &db) != SQLITE_OK) return;

    sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS settings "
        "(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
        nullptr, nullptr, nullptr);

    auto readVal = [&](const char *key, const std::string &fallback) -> std::string {
        sqlite3_stmt *stmt = nullptr;
        std::string result = fallback;
        if (sqlite3_prepare_v2(db,
                "SELECT value FROM settings WHERE key = ?",
                -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                const char *v = reinterpret_cast<const char *>(
                    sqlite3_column_text(stmt, 0));
                if (v) result = v;
            }
            sqlite3_finalize(stmt);
        }
        return result;
    };

    try {
        m_volume = std::stof(readVal("playback/volume", "0.8"));
    } catch (...) { m_volume = 0.8f; }
    try {
        m_playCountThreshold = std::stoi(
            readVal("playback/playCountThreshold", "10"));
    } catch (...) { m_playCountThreshold = 10; }

    sqlite3_close(db);

    for (int i = 0; i < m_session->queueCount(); ++i)
        m_session->queueAt(i)->setVolume(m_volume);

    if (onVolumeChanged)       onVolumeChanged();
    if (onPlayingTrackChanged) onPlayingTrackChanged();
}

void PlaybackManager::saveSettings(const std::string &dataDir)
{
    std::string dbPath = dataDir + "/userdata.db";
    sqlite3 *db = nullptr;
    if (sqlite3_open(dbPath.c_str(), &db) != SQLITE_OK) return;

    sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS settings "
        "(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
        nullptr, nullptr, nullptr);

    auto write = [&](const char *key, const std::string &value) {
        sqlite3_stmt *stmt = nullptr;
        if (sqlite3_prepare_v2(db,
                "INSERT INTO settings (key,value) VALUES(?,?) "
                "ON CONFLICT(key) DO UPDATE SET value=?",
                -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 2, value.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 3, value.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    };

    write("playback/volume",
          std::to_string(m_volume));
    write("playback/playCountThreshold",
          std::to_string(m_playCountThreshold));

    sqlite3_close(db);
}

// ---------------------------------------------------------------------------
// Volume
// ---------------------------------------------------------------------------

float PlaybackManager::volume() const { return m_volume; }

void PlaybackManager::setVolume(float volume)
{
    m_volume = volume;
    for (int i = 0; i < m_session->queueCount(); ++i)
        m_session->queueAt(i)->setVolume(volume);
    if (onVolumeChanged) onVolumeChanged();
    saveSettings(m_dataDir);
}

// ---------------------------------------------------------------------------
// Transport
// ---------------------------------------------------------------------------

void PlaybackManager::play()
{
    if (Queue *q = m_session->playingQueue()) q->play();
}

void PlaybackManager::pause()
{
    if (Queue *q = m_session->playingQueue()) q->pause();
}

void PlaybackManager::seekTo(int64_t positionMs)
{
    m_isSeeking = true;
    if (Queue *q = m_session->playingQueue()) q->seekTo(positionMs);
    m_isSeeking = false;
}

void PlaybackManager::playNext()
{
    if (Queue *q = m_session->playingQueue()) q->playNext();
}

void PlaybackManager::playPrevious()
{
    if (Queue *q = m_session->playingQueue()) q->playPrevious();
}

void PlaybackManager::cycleRepeatMode()
{
    if (Queue *q = m_session->playingQueue()) q->cycleRepeatMode();
}

void PlaybackManager::toggleShuffle()
{
    if (Queue *q = m_session->playingQueue()) q->toggleShuffle();
}

void PlaybackManager::toggleStopAfterCurrent()
{
    Queue *q = m_session->playingQueue();
    if (q) q->setStopAfterCurrent(!q->stopAfterCurrent());
}

// ---------------------------------------------------------------------------
// Playback state getters
// ---------------------------------------------------------------------------

bool    PlaybackManager::isPlaying()  const
{
    Queue *q = m_session->playingQueue();
    return q ? q->isPlaying() : false;
}

int64_t PlaybackManager::position()   const
{
    Queue *q = m_session->playingQueue();
    return q ? q->position() : 0;
}

int64_t PlaybackManager::duration()   const
{
    Queue *q = m_session->playingQueue();
    return q ? q->duration() : 0;
}

int PlaybackManager::repeatMode()     const
{
    Queue *q = m_session->playingQueue();
    return q ? static_cast<int>(q->repeatMode()) : 0;
}

bool PlaybackManager::isShuffled()    const
{
    Queue *q = m_session->playingQueue();
    return q ? q->isShuffled() : false;
}

bool PlaybackManager::stopAfterCurrent() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->stopAfterCurrent() : false;
}

// ---------------------------------------------------------------------------
// Now-playing metadata
// ---------------------------------------------------------------------------

std::string PlaybackManager::trackTitle() const
{
    Queue *q = m_session->playingQueue();
    return (q && q->currentTrackIndex() >= 0)
               ? q->trackAt(q->currentTrackIndex()).title : "";
}

std::string PlaybackManager::trackArtist() const
{
    Queue *q = m_session->playingQueue();
    return (q && q->currentTrackIndex() >= 0)
               ? q->trackAt(q->currentTrackIndex()).artist : "";
}

std::string PlaybackManager::trackAlbum() const
{
    Queue *q = m_session->playingQueue();
    return (q && q->currentTrackIndex() >= 0)
               ? q->trackAt(q->currentTrackIndex()).album : "";
}

std::string PlaybackManager::trackPath() const
{
    Queue *q = m_session->playingQueue();
    return (q && q->currentTrackIndex() >= 0)
               ? q->trackAt(q->currentTrackIndex()).path : "";
}

bool PlaybackManager::hasCoverArt() const
{
    Queue *q = m_session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return false;
    return !q->trackAt(q->currentTrackIndex()).path.empty();
}

std::string          PlaybackManager::rawLyrics()      const { return m_rawLyrics; }
std::vector<LrcLine> PlaybackManager::lyricLines()     const { return m_lyricLines; }
bool                 PlaybackManager::lyricsAreSynced() const { return !m_lyricLines.empty(); }

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------

int PlaybackManager::playingTrackIndex() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->currentTrackIndex() : -1;
}

int PlaybackManager::playingTrackCount() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->trackCount() : 0;
}

bool PlaybackManager::hasPrevious() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->hasPrevious() : false;
}

bool PlaybackManager::hasNext() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->hasNext() : false;
}

// ---------------------------------------------------------------------------
// Play count
// ---------------------------------------------------------------------------

int PlaybackManager::playCountThreshold() const { return m_playCountThreshold; }

void PlaybackManager::setPlayCountThreshold(int percent)
{
    m_playCountThreshold = percent;
    resetPlayCountState();
    saveSettings(m_dataDir);
}

// ---------------------------------------------------------------------------
// Playback wiring
// ---------------------------------------------------------------------------

void PlaybackManager::initPlayback(int queueIndex)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    q->setVolume(m_volume);
    q->initPlayback();
    connectPlaybackCallbacks(q);
}

void PlaybackManager::destroyPlayback(int queueIndex)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    q->saveState();
    q->destroyPlayback();
}

void PlaybackManager::restorePlaybackState(int queueIndex)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (q) q->restoreState();
}

Playback *PlaybackManager::activePlayback() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->currentPlayback() : nullptr;
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

void PlaybackManager::resetPlayCountState()
{
    m_playCountCredited = false;
    m_creditThresholdMs = 0;

    Queue *q = m_session->playingQueue();
    if (q && q->currentTrackIndex() >= 0) {
        int64_t dur = q->trackAt(q->currentTrackIndex()).duration;
        m_creditThresholdMs = int64_t(dur * (m_playCountThreshold / 100.0));
    }
}

void PlaybackManager::rebuildLyricLines()
{
    m_lyricLines.clear();
    Queue *q = m_session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return;

    Track current = q->trackAt(q->currentTrackIndex());
    if (current.path.empty()) return;

    Track fresh  = Metadata::read(current.path, false);
    m_rawLyrics  = fresh.lyrics;

    if (LrcParser::isLrc(fresh.lyrics))
        m_lyricLines = LrcParser::parse(fresh.lyrics);
}

void PlaybackManager::connectPlaybackCallbacks(Queue *queue)
{
    connectCurrentPlaybackCallbacks(queue);

    queue->onTrackChanged = [this]() {
        resetPlayCountState();
        clearAbRepeat();
        rebuildLyricLines();
        if (onPlayingTrackChanged) onPlayingTrackChanged();
        if (onMetadataChanged)     onMetadataChanged();
        if (onIsFavoriteChanged)   onIsFavoriteChanged();
        if (onPositionChanged)     onPositionChanged();
        if (onDurationChanged)     onDurationChanged();
    };

    queue->onRestoreCompleted = [this]() {
        resetPlayCountState();
    };

    queue->onRepeatModeChanged = [this]() {
        if (onRepeatModeChanged) onRepeatModeChanged();
    };

    queue->onShuffleChanged = [this]() {
        if (onShuffleChanged) onShuffleChanged();
    };

    queue->onStopAfterCurrentChanged = [this]() {
        if (onStopAfterCurrentChanged) onStopAfterCurrentChanged();
    };
}

void PlaybackManager::connectCurrentPlaybackCallbacks(Queue *queue)
{
    Playback *pb = queue->currentPlayback();
    if (!pb) return;

    pb->onReadyToPlay = [this]() {
        rebuildLyricLines();
        if (onMetadataChanged)   onMetadataChanged();
        if (onIsFavoriteChanged) onIsFavoriteChanged();

        Queue *playingQ = m_session->playingQueue();
        if (!playingQ) return;

        if (playingQ->repeatMode() == Queue::RepeatTrack) {
            if (Playback *p = playingQ->currentPlayback()) {
                p->clearAppendedTrack();
                p->setRepeatTrackPending(true);
            }
            return;
        }

        if (m_pendingGaplessAdvance) {
            m_pendingGaplessAdvance = false;
            if (playingQ->repeatMode() == Queue::RepeatTrack) {
                if (Playback *p = playingQ->currentPlayback())
                    p->clearAppendedTrack();
                return;
            }
            Track next = playingQ->peekNextTrack();
            if (next.isValid()) {
                if (Playback *p = playingQ->currentPlayback())
                    p->appendTrack(next);
            }
            return;
        }

        Track next = playingQ->peekNextTrack();
        if (next.isValid()) {
            if (Playback *p = playingQ->currentPlayback())
                p->appendTrack(next);
        }
    };

    pb->onPlaybackStateChanged = [this]() {
        if (onIsPlayingChanged) onIsPlayingChanged();
    };

    pb->onDurationChanged = [this]() {
        if (onDurationChanged) onDurationChanged();
        if (m_creditThresholdMs == 0 && !m_playCountCredited) {
            Queue *q = m_session->playingQueue();
            if (q && q->currentTrackIndex() >= 0) {
                int64_t dur = q->duration();
                if (dur > 0)
                    m_creditThresholdMs =
                        int64_t(dur * (m_playCountThreshold / 100.0));
            }
        }
    };

    pb->onPositionChanged = [this]() {
        if (onPositionChanged) onPositionChanged();
        if (m_isSeeking) return;

        if (m_abRepeatActive && m_pointA >= 0 && m_pointB >= 0) {
            Queue *q = m_session->playingQueue();
            if (q && q->position() >= m_pointB) {
                q->seekTo(m_pointA);
                return;
            }
        }

        if (!m_playCountCredited && m_creditThresholdMs > 1000) {
            Queue *q = m_session->playingQueue();
            if (q && q->position() >= m_creditThresholdMs) {
                m_playCountCredited = true;
                std::string path = q->trackAt(q->currentTrackIndex()).path;
                int64_t now = nowSeconds();
                if (m_userDataManager) {
                    m_userDataManager->incrementPlayCount(path);
                    int newCount =
                        q->trackAt(q->currentTrackIndex()).playCount + 1;
                    for (int i = 0; i < m_session->queueCount(); ++i)
                        m_session->queueAt(i)->updateTrackStats(
                            path, now, newCount);
                }
                if (onMetadataChanged) onMetadataChanged();
            }
        }
    };

    pb->onTrackAdvancedGapless = [this]() {
        m_pendingGaplessAdvance = true;
    };
}

// ---------------------------------------------------------------------------
// A-B repeat
// ---------------------------------------------------------------------------

void PlaybackManager::setPointA()
{
    Queue *q = m_session->playingQueue();
    if (!q) return;
    m_pointA         = q->position();
    m_pointB         = -1;
    m_abRepeatActive = false;
    if (onAbRepeatChanged) onAbRepeatChanged();
}

void PlaybackManager::setPointB()
{
    Queue *q = m_session->playingQueue();
    if (!q || m_pointA < 0) return;
    int64_t currentPos = q->position();
    if (currentPos <= m_pointA) return;
    m_pointB         = currentPos;
    m_abRepeatActive = true;
    q->seekTo(m_pointA);
    if (onAbRepeatChanged) onAbRepeatChanged();
}

void PlaybackManager::clearAbRepeat()
{
    m_pointA         = -1;
    m_pointB         = -1;
    m_abRepeatActive = false;
    if (onAbRepeatChanged) onAbRepeatChanged();
}

bool    PlaybackManager::abRepeatActive() const { return m_abRepeatActive; }
int64_t PlaybackManager::pointA()         const { return m_pointA; }
int64_t PlaybackManager::pointB()         const { return m_pointB; }