#include "playbackmanager.h"
#include "metadata.h"
#include <chrono>
#include <sqlite3.h>
#include <android/log.h>
#define PMLOG(...) __android_log_print(ANDROID_LOG_DEBUG, "NatsuyumePM", __VA_ARGS__)

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
      try {
            m_savedActiveQueueIndex =
            std::stoi(readVal("playback/activeQueueIndex", "-1"));
      } catch (...) { m_savedActiveQueueIndex = -1; }
      try {
            m_savedTrackIndex =
            std::stoi(readVal("playback/currentTrackIndex", "-1"));
      } catch (...) { m_savedTrackIndex = -1; }
      try {
            m_savedPositionMs =
            std::stoll(readVal("playback/positionMs", "0"));
      } catch (...) { m_savedPositionMs = 0; }
            m_savedTrackPath = readVal("playback/trackPath", "");
            m_pendingRestore = m_savedActiveQueueIndex >= 0 &&
                              m_savedTrackIndex >= 0 &&
                              !m_savedTrackPath.empty();

      m_savedQueuePaths = readVal("playback/queuePaths", "[]");
      m_savedQueueName  = readVal("playback/queueName", "");

      PMLOG("loadSettings: savedQueue=%d savedTrack=%d savedPos=%lld pendingRestore=%d",
            m_savedActiveQueueIndex,
            m_savedTrackIndex,
            (long long)m_savedPositionMs,
            (int)m_pendingRestore);
      PMLOG("loadSettings: savedPath=%s", m_savedTrackPath.c_str());
      PMLOG("loadSettings: queuePaths=%s", m_savedQueuePaths.c_str());
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

      // Save playback state
      write("playback/activeQueueIndex",
            std::to_string(m_session->playingQueueIndex()));

      // Save queue track paths as JSON
      Queue *qLog = m_session->playingQueue();
      if (qLog) {
      PMLOG("saveSettings: activeQueue=%d trackIdx=%d pos=%lld name=%s trackCount=%d",
            m_session->playingQueueIndex(),
            qLog->currentTrackIndex(),
            (long long)qLog->position(),
            qLog->name().c_str(),
            qLog->trackCount());
      }

      if (qLog && qLog->trackCount() > 0) {
      std::string pathsJson = "[";
      for (int i = 0; i < qLog->trackCount(); ++i) {
            if (i > 0) pathsJson += ",";
            std::string path = qLog->trackAt(i).path;
            std::string escaped;
            for (char c : path) {
                  if (c == '"')  escaped += "\\\"";
                  else if (c == '\\') escaped += "\\\\";
                  else escaped += c;
            }
            pathsJson += "\"" + escaped + "\"";
      }
      pathsJson += "]";
      write("playback/queuePaths", pathsJson);
      write("playback/queueName", qLog->name());
      } else {
      write("playback/queuePaths", "[]");
      write("playback/queueName", "");
      }
      
      if (qLog && qLog->currentTrackIndex() >= 0) {
      write("playback/currentTrackIndex",
            std::to_string(qLog->currentTrackIndex()));
      write("playback/positionMs",
            std::to_string(qLog->position()));
      write("playback/trackPath",
            qLog->trackAt(qLog->currentTrackIndex()).path);
      } else {
      write("playback/currentTrackIndex", "-1");
      write("playback/positionMs", "0");
      write("playback/trackPath", "");
      }
      write("playback/volume",
            std::to_string(m_volume));
      write("playback/playCountThreshold",
            std::to_string(m_playCountThreshold));

      sqlite3_close(db);
}

void PlaybackManager::restoreLastSession()
{
      PMLOG("restoreLastSession: pendingRestore=%d savedTrack=%d pathsLen=%zu",
            (int)m_pendingRestore,
            m_savedTrackIndex,
            m_savedQueuePaths.size());
      if (!m_pendingRestore) return;
      if (m_savedTrackIndex < 0) return;
      if (m_savedQueuePaths == "[]" || m_savedQueuePaths.empty()) return;
      m_pendingRestore = false;

      // Parse paths JSON
      std::vector<std::string> paths;
      const std::string &json = m_savedQueuePaths;
      size_t pos = 0;
      while ((pos = json.find('"', pos)) != std::string::npos) {
            size_t start = pos + 1;
            size_t end = start;
            while (end < json.size()) {
                  if (json[end] == '\\') { end += 2; continue; }
                  if (json[end] == '"') break;
                  end++;
            }
            if (end < json.size()) {
                  std::string raw = json.substr(start, end - start);
                  std::string path;
                  for (size_t i = 0; i < raw.size(); i++) {
                  if (raw[i] == '\\' && i + 1 < raw.size()) {
                        switch (raw[i+1]) {
                              case '"':  path += '"';  i++; break;
                              case '\\': path += '\\'; i++; break;
                              default:   path += raw[i]; break;
                        }
                  } else {
                        path += raw[i];
                  }
                  }
                  if (!path.empty()) paths.push_back(path);
            }
            pos = end + 1;
      }

      if (paths.empty()) return;
      if (m_savedTrackIndex >= (int)paths.size()) return;

      // Create a new queue with the saved tracks
      std::string name = m_savedQueueName.empty() ? "Queue" : m_savedQueueName;
      Queue *q = new Queue(name);

      // Load track metadata for each path
      for (const auto &path : paths) {
            Track t = Metadata::read(path, false);
            if (t.path.empty()) t.path = path;
            q->addTrackSilent(t);
      }

      if (q->trackCount() == 0) { delete q; return; }

      // Init playback and attach to session
      q->initPlayback();
      connectPlaybackCallbacks(q);
      connectCurrentPlaybackCallbacks(q);
      m_session->appendQueue(q);
      m_session->setPlayingQueueIndex(0);
      m_session->setViewedQueueIndex(0);

      // Load track at saved index, paused
      int trackIdx = std::min(m_savedTrackIndex, q->trackCount() - 1);
      q->loadTrackAt(trackIdx, false);

      // Seek to saved position after brief delay
      m_pendingSeekMs = m_savedPositionMs;

      if (onPlayingTrackChanged) onPlayingTrackChanged();
      if (onMetadataChanged)     onMetadataChanged();
      if (m_session->onQueuesChanged) m_session->onQueuesChanged();
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

    queue->onTrackChanged = [this, queue]() {
        connectCurrentPlaybackCallbacks(queue);
        resetPlayCountState();
        clearAbRepeat();
        rebuildLyricLines();
        if (onPlayingTrackChanged) onPlayingTrackChanged();
        if (onMetadataChanged)     onMetadataChanged();
        if (onIsFavoriteChanged)   onIsFavoriteChanged();
        if (onPositionChanged)     onPositionChanged();
        if (onDurationChanged)     onDurationChanged();
    };

    queue->onQueueEnded = [this]() {
        if (onPlayingTrackChanged) onPlayingTrackChanged();
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
    // Apply pending seek from session restore
    if (m_pendingSeekMs > 0) {
        int64_t seekTarget = m_pendingSeekMs;
        m_pendingSeekMs = 0;
        Queue *pq = m_session->playingQueue();
        if (pq) pq->seekTo(seekTarget);
    }
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

    pb->onTrackAdvancedGapless = [this, queue]() {
        // First advance the queue index (what Queue's callback was doing)
        queue->advancePlayback();
        // Then set the pending flag for onReadyToPlay to append the next track
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