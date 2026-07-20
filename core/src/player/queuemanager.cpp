#include "queuemanager.h"
#include "metadata.h"
#include <algorithm>

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static Natsuyume::CoreTrack toCoreTrack(const Track &t)
{
    Natsuyume::CoreTrack c;
    c.path          = t.path;
    c.title         = t.title;
    c.artist        = t.artist;
    c.album         = t.album;
    c.albumArtist   = t.albumArtist;
    c.composer      = t.composer;
    c.genre         = t.genre;
    c.trackNumber   = t.trackNumber;
    c.discNumber    = t.discNumber;
    c.year          = t.year;
    c.duration      = t.duration;
    c.playCount     = t.playCount;
    c.dateAdded     = t.dateAdded;
    c.dateLastPlayed = t.dateLastPlayed;
    c.isFavorite    = t.isFavorite;
    c.coverArtData  = t.coverArtData;
    c.coverArtMimeType = t.coverArtMimeType;
    c.lyrics        = t.lyrics;
    c.lastModified  = t.lastModified;
    return c;
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

QueueManager::QueueManager(QueueSession *session)
    : m_session(session)
{}

void QueueManager::connectQueueCallbacks(Queue *queue)
{
    // Queue-level callbacks QueueManager cares about.
    // Playback-level callbacks are connected by PlaybackManager.
    queue->onQueueChanged = [this]() {
        // NatsuyumeCore will relay to Flutter via onQueueChanged callback
    };
}

void QueueManager::setLibrary(Library *library)
{
    m_library = library;
}

// ---------------------------------------------------------------------------
// Queue naming
// ---------------------------------------------------------------------------

std::string QueueManager::generateQueueName() const
{
    std::vector<int> usedNumbers;
    for (int i = 0; i < m_session->queueCount(); ++i) {
        Queue *q = m_session->queueAt(i);
        std::string name = q->name();
        const std::string prefix = "Queue ";
        if (name.rfind(prefix, 0) == 0) {
            try {
                int number = std::stoi(name.substr(prefix.size()));
                usedNumbers.push_back(number);
            } catch (...) {}
        }
    }
    int candidate = 1;
    while (std::find(usedNumbers.begin(), usedNumbers.end(), candidate)
           != usedNumbers.end())
        candidate++;
    return "Queue " + std::to_string(candidate);
}

std::vector<std::string> QueueManager::queueNames() const
{
    std::vector<std::string> names;
    for (int i = 0; i < m_session->queueCount(); ++i)
        names.push_back(m_session->queueAt(i)->name());
    return names;
}

// ---------------------------------------------------------------------------
// Queue lifecycle
// ---------------------------------------------------------------------------

void QueueManager::openFilesInNewQueue(const std::vector<std::string> &paths,
                                       const std::string &name,
                                       bool shuffle)
{
    if (paths.empty()) return;

    int oldPlayingIndex = m_session->playingQueueIndex();
    if (oldPlayingIndex >= 0) {
        Queue *oldQueue = m_session->queueAt(oldPlayingIndex);
        if (oldQueue) oldQueue->pause();
    }

    std::string queueName = name.empty() ? generateQueueName() : name;
    Queue *newQueue = new Queue(queueName);
    connectQueueCallbacks(newQueue);

    if (shuffle) newQueue->toggleShuffle();

    m_session->appendQueue(newQueue);
    int newIndex = m_session->queueCount() - 1;

    m_session->setViewedQueueIndex(newIndex);
    m_session->setPlayingQueueIndex(newIndex);

    if (onPlaybackInitNewRequested) onPlaybackInitNewRequested(newIndex);
    newQueue->addTracksBatch(paths, true);
}

void QueueManager::addPathsToNewQueue(const std::vector<std::string> &paths,
                                      const std::string &name)
{
    if (paths.empty()) return;

    std::string queueName = name.empty() ? generateQueueName() : name;
    Queue *newQueue = new Queue(queueName);
    connectQueueCallbacks(newQueue);

    for (const auto &path : paths)
        newQueue->addTrack(path);

    m_session->appendQueue(newQueue);
    int newIndex = m_session->queueCount() - 1;
    if (onPlaybackInitRequested) onPlaybackInitRequested(newIndex);
}

void QueueManager::addPathsToQueue(int queueIndex,
                                   const std::vector<std::string> &paths)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    for (const auto &path : paths)
        q->addTrack(path);
}

void QueueManager::closeQueue(int index)
{
    if (!m_session->isValidIndex(index)) return;

    bool deletingPlaying = (index == m_session->playingQueueIndex());
    Queue *toDelete = m_session->queueAt(index);
    toDelete->pause();
    toDelete->destroyPlayback();

    int newViewedIndex  = m_session->viewedQueueIndex();
    int newPlayingIndex = m_session->playingQueueIndex();

    if (m_session->queueCount() == 1) {
        newViewedIndex  = -1;
        newPlayingIndex = -1;
    } else {
        if (newViewedIndex >= m_session->queueCount() - 1)
            newViewedIndex = m_session->queueCount() - 2;
        else if (index < newViewedIndex)
            newViewedIndex--;

        if (deletingPlaying) {
            newPlayingIndex = std::max(0,
                std::min(index, m_session->queueCount() - 2));
        } else if (index < newPlayingIndex) {
            newPlayingIndex--;
        }
    }

    m_session->removeQueueAt(index);
    delete toDelete;

    m_session->setViewedQueueIndex(newViewedIndex);

    if (deletingPlaying && newPlayingIndex >= 0) {
        m_session->setPlayingQueueIndex(newPlayingIndex);
        if (onPlaybackInitRequested) onPlaybackInitRequested(newPlayingIndex);

        Queue *nextQueue = m_session->queueAt(newPlayingIndex);
        if (nextQueue) {
            if (!nextQueue->isPlaying()) {
                if (nextQueue->position() > 0 || nextQueue->duration() > 0)
                    nextQueue->play();
                else if (nextQueue->currentTrackIndex() >= 0)
                    nextQueue->loadTrackAt(nextQueue->currentTrackIndex());
            }
        }
    }
}

void QueueManager::renameQueue(int index, const std::string &name)
{
    Queue *q = m_session->queueAt(index);
    if (q) q->setName(name);
}

void QueueManager::moveQueue(int from, int to)
{
    if (!m_session->isValidIndex(from) || !m_session->isValidIndex(to)) return;
    if (from == to) return;

    m_session->moveQueue(from, to);

    int viewedIndex  = m_session->viewedQueueIndex();
    int playingIndex = m_session->playingQueueIndex();

    auto adjustIndex = [&](int idx) -> int {
        if (idx == from) return to;
        if (from < to) {
            if (idx > from && idx <= to) return idx - 1;
        } else {
            if (idx >= to && idx < from) return idx + 1;
        }
        return idx;
    };

    m_session->setViewedQueueIndex(adjustIndex(viewedIndex));
    m_session->setPlayingQueueIndex(adjustIndex(playingIndex));
}

void QueueManager::viewQueue(int index)
{
    if (m_session->isValidIndex(index))
        m_session->setViewedQueueIndex(index);
}

// ---------------------------------------------------------------------------
// Track manipulation
// ---------------------------------------------------------------------------

void QueueManager::addTrackToQueue(const std::string &path)
{
    Queue *q = m_session->playingQueue();
    if (q) q->addTrack(path);
}

void QueueManager::addAlbumToQueue(const std::string &album,
                                   Library::TrackSort sort,
                                   bool ascending)
{
    Queue *q = m_session->playingQueue();
    if (!q || !m_library) return;
    auto tracks = m_library->tracksByAlbum(album, sort, ascending);
    for (const Track &t : tracks)
        q->addTrack(t.path);
}

void QueueManager::removeTrackAt(int index)
{
    Queue *q = m_session->viewedQueue();
    if (q) q->removeTrack(index);
}

void QueueManager::moveTrack(int from, int to)
{
    Queue *q = m_session->viewedQueue();
    if (q) q->moveTrack(from, to);
}

void QueueManager::sortQueue(int sort, bool ascending)
{
    Queue *q = m_session->viewedQueue();
    if (q) q->sortTracks(static_cast<Library::TrackSort>(sort), ascending);
}

void QueueManager::reverseQueue()
{
    Queue *q = m_session->viewedQueue();
    if (q) q->reverseTracks();
}

// ---------------------------------------------------------------------------
// Track lookup
// ---------------------------------------------------------------------------

std::vector<Natsuyume::CoreTrack> QueueManager::trackList() const
{
    std::vector<Natsuyume::CoreTrack> list;
    Queue *q = m_session->viewedQueue();
    if (!q) return list;
    for (int i = 0; i < q->trackCount(); ++i)
        list.push_back(toCoreTrack(q->trackAt(i)));
    return list;
}

Natsuyume::CoreTrack QueueManager::trackInfoByPath(const std::string &path) const
{
    // Check playing queue first
    Queue *q = m_session->playingQueue();
    if (q) {
        for (int i = 0; i < q->trackCount(); ++i) {
            Track t = q->trackAt(i);
            if (t.path == path) return toCoreTrack(t);
        }
    }
    // Fall back to library
    if (m_library) {
        Track t = m_library->trackByPath(path);
        if (t.isValid()) return toCoreTrack(t);
    }
    return Natsuyume::CoreTrack{};
}

int64_t QueueManager::queueTotalDuration() const
{
    Queue *q = m_session->viewedQueue();
    if (!q) return 0;
    int64_t total = 0;
    for (const Track &t : q->tracks())
        total += t.duration;
    return total;
}

bool QueueManager::isAlbumActiveQueue(const std::string &album,
                                      Library::TrackSort sort,
                                      bool ascending) const
{
    Queue *q = m_session->playingQueue();
    if (!q || q->trackCount() == 0 || !m_library) return false;
    if (q->name() != album) return false;
    auto albumTracks = m_library->tracksByAlbum(album, sort, ascending);
    return q->trackCount() == (int)albumTracks.size();
}

// ---------------------------------------------------------------------------
// Jump
// ---------------------------------------------------------------------------

void QueueManager::jumpToTrack(int index)
{
    Queue *viewed = m_session->viewedQueue();
    if (!viewed) return;

    int viewedIndex  = m_session->viewedQueueIndex();
    int playingIndex = m_session->playingQueueIndex();

    if (playingIndex != viewedIndex) {
        if (onPlaybackDestroyRequested) onPlaybackDestroyRequested(playingIndex);
        m_session->setPlayingQueueIndex(viewedIndex);
        if (onPlaybackInitRequested) onPlaybackInitRequested(viewedIndex);
    }

    viewed->loadTrackAt(index);
}

void QueueManager::jumpToTrackByPath(const std::string &path)
{
    Queue *viewed = m_session->viewedQueue();
    if (!viewed) return;

    int foundIndex = -1;
    for (int i = 0; i < viewed->trackCount(); ++i) {
        if (viewed->trackAt(i).path == path) {
            foundIndex = i;
            break;
        }
    }

    if (foundIndex < 0) {
        viewed->addTrack(path);
        foundIndex = viewed->trackCount() - 1;
    }

    jumpToTrack(foundIndex);
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

void QueueManager::saveQueues(int viewedIndex)
{
    if (!m_library) return;

    std::vector<QueueSnapshot> snapshots;
    for (int i = 0; i < m_session->queueCount(); ++i) {
        Queue *q = m_session->queueAt(i);
        q->saveState();
        QueueSnapshot snap;
        snap.name              = q->name();
        snap.currentTrackIndex = q->currentTrackIndex();
        snap.currentPosition   = q->savedPosition();
        snap.wasPlaying        = q->isPlaying();
        snap.isActive          = (i == viewedIndex);
        for (const Track &t : q->tracks())
            snap.paths.push_back(t.path);
        snapshots.push_back(std::move(snap));
    }
    m_library->saveQueues(snapshots);
}

void QueueManager::loadQueues(float volume)
{
    if (!m_library) return;

    auto snapshots = m_library->loadQueues();
    if (snapshots.empty()) return;

    int activeIndex = 0;
    for (int i = 0; i < (int)snapshots.size(); ++i) {
        const QueueSnapshot &snap = snapshots[i];

        Queue *queue = new Queue(snap.name);
        queue->setVolume(volume);
        connectQueueCallbacks(queue);

        for (const auto &path : snap.paths) {
            Track t = m_library->trackByPath(path);
            if (!t.isValid()) t = Track(path);
            queue->addTrackSilent(t);
        }

        queue->setSavedPosition(snap.currentPosition);
        queue->setWasPlaying(false);
        queue->setCurrentTrackIndex(
            std::max(0, std::min(snap.currentTrackIndex,
                                 (int)snap.paths.size() - 1)));

        m_session->appendQueue(queue);
        if (snap.isActive) activeIndex = i;
    }

    if (m_session->queueCount() == 0) return;

    m_session->setViewedQueueIndex(activeIndex);
    m_session->setPlayingQueueIndex(activeIndex);

    // No QTimer needed — caller (NatsuyumeCore::init) controls sequencing
    if (onPlaybackRestoreRequested) onPlaybackRestoreRequested(activeIndex);
}