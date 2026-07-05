#include "queuemanager.h"
#include "queue.h"
#include "metadata.h"
#include <QTimer>

QueueManager::QueueManager(QueueSession *session, QObject *parent)
    : QObject{parent},
    m_session{session},
    m_library{nullptr}
{
}

// --- Internal helpers ---

QString QueueManager::generateQueueName() const
{
    QList<int> usedNumbers;
    for (int i = 0; i < m_session->queueCount(); i++) {
        Queue *q = m_session->queueAt(i);
        QString name = q->name();
        if (name.startsWith("Queue ")) {
            bool ok;
            int number = QStringView(name).mid(6).toInt(&ok);
            if (ok)
                usedNumbers.append(number);
        }
    }
    int candidate = 1;
    while (usedNumbers.contains(candidate))
        candidate++;
    return QString("Queue %1").arg(candidate);
}

void QueueManager::connectQueueSignals(Queue *queue)
{
    // Queue-level signals that QueueManager cares about —
    // playback-level signals are connected by PlaybackManager
    connect(queue, &Queue::queueChanged, this, [this]() {
        // PlayerController will relay this to QML via trackChanged
    });
}

QStringList QueueManager::queueNames() const
{
    QStringList names;
    for (int i = 0; i < m_session->queueCount(); i++)
        names.append(m_session->queueAt(i)->name());
    return names;
}

// --- Queue lifecycle ---

void QueueManager::openFilesInNewQueue(const QStringList &paths,
                                       const QString &name,
                                       bool shuffle)
{
    if (paths.isEmpty()) return;

    int oldPlayingIndex = m_session->playingQueueIndex();
    if (oldPlayingIndex >= 0)
        emit playbackDestroyRequested(oldPlayingIndex);

    QString queueName = name.isEmpty() ? generateQueueName() : name;
    Queue *newQueue = new Queue(queueName, this);
    connectQueueSignals(newQueue);

    if (shuffle)
        newQueue->toggleShuffle();

    m_session->appendQueue(newQueue);
    int newIndex = m_session->queueCount() - 1;

    m_session->setViewedQueueIndex(newIndex);
    m_session->setPlayingQueueIndex(newIndex);

    // Init playback BEFORE addTracksBatch so QMediaPlayer exists
    // when addTracksBatch tries to load the first track
    emit playbackInitNewRequested(newIndex);

    // Now add tracks — initPlayback has already run so m_playback exists
    // and addTracksBatch's internal loadTrack call will succeed first time
    newQueue->addTracksBatch(paths, true);
}

void QueueManager::addPathsToNewQueue(const QStringList &paths,
                                      const QString &name)
{
    if (paths.isEmpty()) return;

    // Intentionally does not update viewedQueueIndex or playingQueueIndex —
    // this creates a background queue without transferring playback.
    // connectPlaybackSignals is still required via playbackInitRequested
    // so the queue works correctly if the user switches to it later.
    QString queueName = name.isEmpty() ? generateQueueName() : name;
    Queue *newQueue = new Queue(queueName, this);
    connectQueueSignals(newQueue);

    for (const QString &path : paths)
        newQueue->addTrack(path);

    m_session->appendQueue(newQueue);

    int newIndex = m_session->queueCount() - 1;
    emit playbackInitRequested(newIndex);
}

void QueueManager::addPathsToQueue(int queueIndex, const QStringList &paths)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    for (const QString &path : paths)
        q->addTrack(path);
}

void QueueManager::closeQueue(int index)
{
    if (!m_session->isValidIndex(index)) return;

    bool deletingPlaying = (index == m_session->playingQueueIndex());

    Queue *toDelete = m_session->queueAt(index);
    toDelete->pause();

    // Update indices before removal so they stay consistent
    int newViewedIndex  = m_session->viewedQueueIndex();
    int newPlayingIndex = m_session->playingQueueIndex();

    if (m_session->queueCount() == 1) {
        // Closing the last queue
        newViewedIndex  = -1;
        newPlayingIndex = -1;
    } else {
        if (newViewedIndex >= m_session->queueCount() - 1)
            newViewedIndex = m_session->queueCount() - 2;
        else if (index < newViewedIndex)
            newViewedIndex--;

        if (deletingPlaying) {
            newPlayingIndex = qBound(0, index, m_session->queueCount() - 2);
        } else if (index < newPlayingIndex) {
            newPlayingIndex--;
        }
    }

    m_session->removeQueueAt(index);
    toDelete->deleteLater();

    m_session->setViewedQueueIndex(newViewedIndex);
    m_session->setPlayingQueueIndex(newPlayingIndex);

    if (deletingPlaying && newPlayingIndex >= 0)
        emit playbackInitRequested(newPlayingIndex);
}

void QueueManager::renameQueue(int index, const QString &name)
{
    Queue *q = m_session->queueAt(index);
    if (!q) return;
    q->setName(name);
}

void QueueManager::moveQueue(int from, int to)
{
    if (!m_session->isValidIndex(from) || !m_session->isValidIndex(to)) return;
    if (from == to) return;

    m_session->moveQueue(from, to);

    // Keep indices tracking the same queue objects after the move
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
    if (!m_session->isValidIndex(index)) return;
    m_session->setViewedQueueIndex(index);
}

// --- Track manipulation ---

void QueueManager::addTrackToQueue(const QString &path)
{
    Queue *q = m_session->playingQueue();
    if (!q) return;
    q->addTrack(path);
}

void QueueManager::addAlbumToQueue(const QString &album,
                                   Library::TrackSort sort,
                                   bool ascending)
{
    Queue *q = m_session->playingQueue();
    if (!q || !m_library) return;
    QList<Track> tracks = m_library->tracksByAlbum(album, sort, ascending);
    for (const Track &t : std::as_const(tracks))
        q->addTrack(t.path);
}

void QueueManager::removeTrackAt(int index)
{
    Queue *q = m_session->viewedQueue();
    if (!q) return;
    q->removeTrack(index);
}

void QueueManager::moveTrack(int from, int to)
{
    Queue *q = m_session->viewedQueue();
    if (!q) return;
    q->moveTrack(from, to);
}

void QueueManager::sortQueue(int sort, bool ascending)
{
    Queue *q = m_session->viewedQueue();
    if (!q) return;
    q->sortTracks(static_cast<Library::TrackSort>(sort), ascending);
}

void QueueManager::reverseQueue()
{
    Queue *q = m_session->viewedQueue();
    if (!q) return;
    q->reverseTracks();
}

// --- Track lookup ---

QVariantList QueueManager::trackList() const
{
    QVariantList list;
    Queue *q = m_session->viewedQueue();
    if (!q) return list;

    for (int i = 0; i < q->trackCount(); i++) {
        Track t = q->trackAt(i);
        QVariantMap map;
        map["title"]    = t.title;
        map["artist"]   = t.artist;
        map["album"]    = t.album;
        map["path"]     = t.path;
        map["duration"] = t.duration;
        list.append(map);
    }
    return list;
}

QVariantMap QueueManager::trackInfoByPath(const QString &path) const
{
    QVariantMap map;

    // Check playing queue first — may have tracks not yet in library
    Queue *q = m_session->playingQueue();
    if (q) {
        for (int i = 0; i < q->trackCount(); i++) {
            Track t = q->trackAt(i);
            if (t.path == path) {
                map["path"]           = t.path;
                map["title"]          = t.title;
                map["artist"]         = t.artist;
                map["album"]          = t.album;
                map["albumArtist"]    = t.albumArtist;
                map["composer"]       = t.composer;
                map["genre"]          = t.genre;
                map["trackNumber"]    = t.trackNumber;
                map["discNumber"]     = t.discNumber;
                map["year"]           = t.year;
                map["duration"]       = t.duration;
                map["playCount"]      = t.playCount;
                map["dateAdded"]      = t.dateAdded;
                map["dateLastPlayed"] = t.dateLastPlayed;
                return map;
            }
        }
    }

    // Fall back to library
    if (m_library) {
        Track t = m_library->trackByPath(path);
        if (t.isValid()) {
            map["path"]           = t.path;
            map["title"]          = t.title;
            map["artist"]         = t.artist;
            map["album"]          = t.album;
            map["albumArtist"]    = t.albumArtist;
            map["composer"]       = t.composer;
            map["genre"]          = t.genre;
            map["trackNumber"]    = t.trackNumber;
            map["discNumber"]     = t.discNumber;
            map["year"]           = t.year;
            map["duration"]       = t.duration;
            map["playCount"]      = t.playCount;
            map["dateAdded"]      = t.dateAdded;
            map["dateLastPlayed"] = t.dateLastPlayed;
            return map;
        }
    }

    return map;
}

qint64 QueueManager::queueTotalDuration() const
{
    Queue *q = m_session->viewedQueue();
    if (!q) return 0;
    qint64 total = 0;
    for (const Track &t : q->tracks())
        total += t.duration;
    return total;
}

bool QueueManager::isAlbumActiveQueue(const QString &album,
                                      Library::TrackSort sort,
                                      bool ascending) const
{
    Queue *q = m_session->playingQueue();
    if (!q || q->trackCount() == 0 || !m_library) return false;
    if (q->name() != album) return false;
    QList<Track> albumTracks = m_library->tracksByAlbum(album, sort, ascending);
    return q->trackCount() == albumTracks.size();
}

// --- Jump ---

void QueueManager::jumpToTrack(int index)
{
    Queue *viewed = m_session->viewedQueue();
    if (!viewed) return;

    int viewedIndex  = m_session->viewedQueueIndex();
    int playingIndex = m_session->playingQueueIndex();

    if (playingIndex != viewedIndex) {
        // Transfer playback to the viewed queue
        emit playbackDestroyRequested(playingIndex);
        m_session->setPlayingQueueIndex(viewedIndex);
        emit playbackInitRequested(viewedIndex);
    }

    viewed->loadTrackAt(index);
}

void QueueManager::jumpToTrackByPath(const QString &path)
{
    Queue *viewed = m_session->viewedQueue();
    if (!viewed) return;

    int foundIndex = -1;
    for (int i = 0; i < viewed->trackCount(); i++) {
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

// --- Persistence ---

void QueueManager::saveQueues(int viewedIndex)
{
    if (!m_library) return;

    QList<QueueSnapshot> snapshots;
    for (int i = 0; i < m_session->queueCount(); i++) {
        Queue *q = m_session->queueAt(i);
        q->saveState();
        QueueSnapshot snap;
        snap.name              = q->name();
        snap.currentTrackIndex = q->currentTrackIndex();
        snap.currentPosition   = q->savedPosition();
        snap.wasPlaying        = q->isPlaying();
        snap.isActive          = (i == viewedIndex);
        for (const Track &t : q->tracks())
            snap.paths << t.path;
        snapshots.append(snap);
    }
    m_library->saveQueues(snapshots);
}

void QueueManager::loadQueues(float volume)
{
    if (!m_library) return;

    QList<QueueSnapshot> snapshots = m_library->loadQueues();
    if (snapshots.isEmpty()) return;

    int activeIndex = 0;
    for (int i = 0; i < snapshots.size(); i++) {
        const QueueSnapshot &snap = snapshots[i];

        Queue *queue = new Queue(snap.name, this);
        queue->setVolume(volume);
        connectQueueSignals(queue);

        for (const QString &path : snap.paths) {
            Track t = m_library->trackByPath(path);
            if (!t.isValid())
                t = Track(path);
            queue->addTrackSilent(t);
        }

        queue->setSavedPosition(snap.currentPosition);
        queue->setWasPlaying(false);
        queue->setCurrentTrackIndex(qBound(0, snap.currentTrackIndex,
                                           (int)snap.paths.size() - 1));

        m_session->appendQueue(queue);

        if (snap.isActive)
            activeIndex = i;
    }

    if (m_session->queueCount() == 0) return;

    m_session->setViewedQueueIndex(activeIndex);
    m_session->setPlayingQueueIndex(activeIndex);

    // Defer playback init so UI renders first
    QTimer::singleShot(100, this, [this, activeIndex]() {
        emit playbackRestoreRequested(activeIndex);
    });
}

void QueueManager::setLibrary(Library *library)
{
    m_library = library;
}