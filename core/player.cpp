#include "player.h"
#include "metadata.h"
#include <QDateTime>

Player::Player(QObject *parent)
    : QObject{parent},
    m_activeQueueIndex(-1),
    m_volume(0.8f),
    m_albumCoverProvider(nullptr),
    m_scanProgress(0),
    m_scanTotal(0),
    m_albumSort(Library::AlbumSort::Name),
    m_albumSortAscending(true),
    m_trackSort(Library::TrackSort::TrackNumber),
    m_trackSortAscending(true)
{
    m_library = new Library(this);
    if (!m_library->open())
        qWarning() << "Player: failed to open library";

    m_indexer = new FileIndexer(this);

    connect(m_library, &Library::libraryChanged, this, [this]() {
        emit libraryChanged();
    });

    connect(m_indexer, &FileIndexer::scanStarted, this, [this](int total) {
        m_scanProgress = 0;
        m_scanTotal    = total;
        emit scanningChanged();
        emit scanProgressChanged();
    });

    connect(m_indexer, &FileIndexer::scanProgress, this, [this](int scanned, int total, const QString &currentFile) {
        m_scanProgress = scanned;
        m_scanTotal    = total;
        m_scanningFile = currentFile;
        emit scanProgressChanged();
    });

    connect(m_indexer, &FileIndexer::scanFinished, this, [this]() {
        m_scanProgress = m_scanTotal;
        emit scanningChanged();
        emit scanProgressChanged();
        emit libraryChanged();
        if (m_albumCoverProvider)
            registerAlbumCovers(m_albumCoverProvider);
    });

    connect(m_indexer, &FileIndexer::scanCancelled, this, [this]() {
        m_scanProgress = 0;
        m_scanTotal    = 0;
        emit scanningChanged();
        emit scanProgressChanged();
    });

    connect(m_indexer, &FileIndexer::scanningChanged, this, [this]() {
        emit scanningChanged();
    });

    connect(m_library, &Library::libraryChanged, this, [this]() {
        emit libraryChanged();
    });

    connect(m_indexer, &FileIndexer::trackFound, this, [this](const Track &track) {
        m_library->addTrack(track);
    }, Qt::QueuedConnection);

    connect(m_library, &Library::playlistsChanged,
            this, &Player::playlistsChanged);

    m_playlistSort          = Library::TrackSort::TrackNumber;
    m_playlistSortAscending = true;
}

Player::~Player()
{
    qDeleteAll(m_queues);
    m_queues.clear();
}

// --- Internal helpers ---

Queue *Player::activeQueue() const
{
    if (m_activeQueueIndex < 0 || m_activeQueueIndex >= m_queues.size())
        return nullptr;
    return m_queues.at(m_activeQueueIndex);
}

QString Player::generateQueueName() const
{
    QList<int> usedNumbers;
    for (Queue *q : m_queues) {
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

void Player::connectQueueSignals(Queue *queue)
{
    connect(queue, &Queue::trackChanged, this, [this]() {
        emit trackChanged();
        rebuildLyricLines();       // ← add
        emit metadataChanged();
        emit isFavoriteChanged();
        pushCoverArt();

        // Reset play count credit for new track
        m_playCountCredited  = false;
        m_creditThresholdMs  = 0;
        if (activeQueue()) {
            qint64 dur = activeQueue()->trackAt(
                activeQueue()->currentTrackIndex()).duration;
            m_creditThresholdMs = qint64(dur * 0.10);  // 10% threshold
        }
    });

    connect(queue->playback(), &Playback::readyToPlay, this, [this]() {
        rebuildLyricLines();       // ← add
        emit metadataChanged();
        emit isFavoriteChanged();
        pushCoverArt();
    });

    connect(queue, &Queue::queueChanged, this, [this]() {
        emit trackChanged();
    });

    connect(queue, &Queue::repeatModeChanged, this, [this]() {
        emit repeatModeChanged();
    });

    connect(queue, &Queue::shuffleChanged, this, [this]() {
        emit shuffleChanged();
    });

    connect(queue->playback(), &Playback::playbackStateChanged, this, [this]() {
        emit isPlayingChanged();
    });

    connect(queue->playback(), &Playback::durationChanged, this, [this]() {
        emit durationChanged();
    });

    connect(queue->playback(), &Playback::positionChanged, this, [this]() {
        emit positionChanged();

        // ── Play count tracking ────────────────────────────────
        if (!m_playCountCredited && m_creditThresholdMs > 0) {
            if (activeQueue() && activeQueue()->position() >= m_creditThresholdMs) {
                m_playCountCredited = true;
                QString path = activeQueue()->trackAt(
                                                activeQueue()->currentTrackIndex()).path;
                qint64 now = QDateTime::currentSecsSinceEpoch();
                m_library->incrementPlayCount(path);
                for (Queue *q : m_queues)
                    q->updateTrackStats(path, now,
                                        activeQueue()->trackAt(
                                                         activeQueue()->currentTrackIndex()).playCount + 1);
                emit metadataChanged();
            }
        }
    });
}

// --- Playback getters ---

bool Player::isPlaying() const
{
    Queue *q = activeQueue();
    return q ? q->isPlaying() : false;
}

qint64 Player::position() const
{
    Queue *q = activeQueue();
    return q ? q->position() : 0;
}

qint64 Player::duration() const
{
    Queue *q = activeQueue();
    return q ? q->duration() : 0;
}

float Player::volume() const { return m_volume; }

// --- Metadata getters ---

QString Player::trackTitle() const
{
    Queue *q = activeQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).title : "";
}

QString Player::trackArtist() const
{
    Queue *q = activeQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).artist : "";
}

QString Player::trackAlbum() const
{
    Queue *q = activeQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).album : "";
}

bool Player::hasCoverArt() const
{
    Queue *q = activeQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).hasCoverArt() : false;
}

QString Player::rawLyrics() const
{
    return m_rawLyrics;
}

QVariantList Player::lyricLines() const
{
    QVariantList result;
    for (const LrcLine &line : m_lyricLines) {
        QVariantMap map;
        map["timestamp"] = line.timestamp;
        map["text"]      = line.text;
        result << map;
    }
    return result;
}

// --- Track navigation getters ---

int Player::trackIndex() const
{
    Queue *q = activeQueue();
    return q ? q->currentTrackIndex() : -1;
}

int Player::trackCount() const
{
    Queue *q = activeQueue();
    return q ? q->trackCount() : 0;
}

bool Player::hasPrevious() const
{
    Queue *q = activeQueue();
    return q ? q->hasPrevious() : false;
}

bool Player::hasNext() const
{
    Queue *q = activeQueue();
    return q ? q->hasNext() : false;
}

// --- Multi-queue getters ---

int Player::queueCount() const { return m_queues.size(); }
int Player::activeQueueIndex() const { return m_activeQueueIndex; }

QStringList Player::queueNames() const
{
    QStringList names;
    for (Queue *q : m_queues)
        names.append(q->name());
    return names;
}

// --- Repeat getter ---

int Player::repeatMode() const
{
    Queue *q = activeQueue();
    return q ? static_cast<int>(q->repeatMode()) : 0;
}

// --- Shuffle getter ---

bool Player::isShuffled() const
{
    Queue *q = activeQueue();
    return q ? q->isShuffled() : false;
}

// --- Favorites getter ---

bool Player::isFavorite() const
{
    Queue *q = activeQueue();
    if (!q || q->currentTrackIndex() < 0)
        return false;
    return m_favorites.contains(q->trackAt(q->currentTrackIndex()).path);
}

// --- Library getters ---

QStringList Player::allAlbums() const
{
    return m_library->allAlbums(m_albumSort, m_albumSortAscending);
}

QStringList Player::allArtists() const
{
    return m_library->allArtists();
}

bool Player::isScanning() const
{
    return m_indexer->isScanning();
}

int Player::scanProgress() const { return m_scanProgress; }
int Player::scanTotal() const    { return m_scanTotal; }

// --- Library actions ---

void Player::scanFolder(const QString &folderPath)
{
    // Build snapshot of known paths on main thread
    QSet<QString> known;
    for (const Track &t : m_library->allTracks())
        known.insert(t.path);
    m_indexer->setKnownPaths(known);
    m_indexer->scanFolder(folderPath);
}

void Player::cancelScan()
{
    m_indexer->cancel();
}

QVariantList Player::tracksForAlbum(const QString &album) const
{
    QVariantList result;
    for (const Track &t : m_library->tracksByAlbum(album, m_trackSort, m_trackSortAscending)) {
        QVariantMap map;
        map["path"]        = t.path;
        map["title"]       = t.title;
        map["artist"]      = t.artist;
        map["album"]       = t.album;
        map["albumArtist"] = t.albumArtist;
        map["composer"]    = t.composer;
        map["genre"]       = t.genre;
        map["trackNumber"] = t.trackNumber;
        map["discNumber"]  = t.discNumber;
        map["year"]        = t.year;
        map["duration"]    = t.duration;
        map["playCount"]   = t.playCount;
        result.append(map);
    }
    return result;
}

QVariantList Player::tracksForArtist(const QString &artist) const
{
    QVariantList result;
    for (const Track &t : m_library->tracksByArtist(artist)) {
        QVariantMap map;
        map["path"]   = t.path;
        map["title"]  = t.title;
        map["artist"] = t.artist;
        map["album"]  = t.album;
        result.append(map);
    }
    return result;
}

QString Player::scanningFile() const { return m_scanningFile; }

QString Player::albumCoverPath(const QString &album) const
{
    QList<Track> tracks = m_library->tracksByAlbum(album);
    if (tracks.isEmpty()) return "";
    return tracks.first().path;
}

// --- Volume ---

void Player::setVolume(float volume)
{
    m_volume = volume;
    for (Queue *q : std::as_const(m_queues))
        q->setVolume(volume);
    emit volumeChanged();
}

// --- Playback actions ---

void Player::play()
{
    if (Queue *q = activeQueue()) q->play();
}

void Player::pause()
{
    if (Queue *q = activeQueue()) q->pause();
}

void Player::seekTo(qint64 positionMs)
{
    if (Queue *q = activeQueue()) q->seekTo(positionMs);
}

void Player::playNext()
{
    if (Queue *q = activeQueue()) q->playNext();
}

void Player::playPrevious()
{
    if (Queue *q = activeQueue()) q->playPrevious();
}

// --- Repeat / shuffle ---

void Player::cycleRepeatMode()
{
    if (Queue *q = activeQueue()) q->cycleRepeatMode();
}

void Player::toggleShuffle()
{
    if (Queue *q = activeQueue()) q->toggleShuffle();
}

// --- Multi-queue actions ---

void Player::openFilesInNewQueue(const QStringList &filePaths,
                                 const QString &name)
{
    if (filePaths.isEmpty())
        return;

    if (Queue *current = activeQueue())
        current->saveState();

    QString queueName = name.isEmpty() ? generateQueueName() : name;
    Queue *newQueue = new Queue(queueName, this);
    newQueue->setVolume(m_volume);
    connectQueueSignals(newQueue);

    for (const QString &path : filePaths)
        newQueue->addTrack(path);

    m_queues.append(newQueue);
    m_activeQueueIndex = m_queues.size() - 1;

    if (m_coverImageProvider) {
        m_coverImageProvider->updateCover(QImage());
        emit coverArtChanged();
    }

    emit queuesChanged();
    emit trackChanged();
    rebuildLyricLines();       // ← add
    emit metadataChanged();
    emit isPlayingChanged();
    emit positionChanged();
    emit durationChanged();
    emit isFavoriteChanged();
}

void Player::addTrackToActiveQueue(const QString &filePath)
{
    if (Queue *q = activeQueue())
        q->addTrack(filePath);
}

void Player::switchToQueue(int index)
{
    if (index < 0 || index >= m_queues.size()) return;
    if (index == m_activeQueueIndex) return;

    if (Queue *current = activeQueue())
        current->saveState();

    m_activeQueueIndex = index;

    // Clear cover immediately before new queue restores
    if (m_coverImageProvider) {
        m_coverImageProvider->updateCover(QImage());
        emit coverArtChanged();
    }

    m_queues.at(index)->restoreState();

    emit queuesChanged();
    emit isPlayingChanged();
    emit positionChanged();
    emit durationChanged();
    rebuildLyricLines();       // ← add
    emit metadataChanged();
    emit trackChanged();
    emit isFavoriteChanged();
}

void Player::closeQueue(int index)
{
    if (index < 0 || index >= m_queues.size())
        return;

    bool deletingActive = (index == m_activeQueueIndex);

    Queue *toDelete = m_queues.takeAt(index);
    toDelete->pause();
    toDelete->deleteLater();

    if (m_queues.isEmpty()) {
        m_activeQueueIndex = -1;
    } else if (m_activeQueueIndex >= m_queues.size()) {
        m_activeQueueIndex = m_queues.size() - 1;
    } else if (index < m_activeQueueIndex) {
        m_activeQueueIndex--;
    }

    // Only restore state if we deleted the active queue
    // and need to switch to a different one
    if (!deletingActive) {
        // Active queue is still playing — don't touch it
        emit queuesChanged();
        emit trackChanged();
        rebuildLyricLines();       // ← add
        emit metadataChanged();
        emit isPlayingChanged();
        emit positionChanged();
        emit durationChanged();
        emit isFavoriteChanged();
        return;
    }

    // We deleted the active queue — restore the new active one
    if (Queue *q = activeQueue())
        q->restoreState();

    emit queuesChanged();
    emit isPlayingChanged();
    emit positionChanged();
    emit durationChanged();
    rebuildLyricLines();       // ← add
    emit metadataChanged();
    emit trackChanged();
    emit isFavoriteChanged();
}

void Player::renameQueue(int index, const QString &name)
{
    if (index < 0 || index >= m_queues.size()) return;
    m_queues.at(index)->setName(name);
    emit queuesChanged();
}

// --- Favorites ---

void Player::toggleFavorite()
{
    Queue *q = activeQueue();
    if (!q || q->currentTrackIndex() < 0) return;

    QString path = q->trackAt(q->currentTrackIndex()).path;
    if (m_favorites.contains(path))
        m_favorites.removeAll(path);
    else
        m_favorites.append(path);

    emit isFavoriteChanged();
}

// --- Track Lists ---

void Player::jumpToTrack(int index)
{
    if (Queue *q = activeQueue())
        q->loadTrackAt(index);
}

QVariantList Player::trackList() const
{
    QVariantList list;
    Queue *q = activeQueue();
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

void Player::removeTrackAt(int index)
{
    if (Queue *q = activeQueue())
        q->removeTrack(index);
}

void Player::setCoverImageProvider(CoverImageProvider *provider)
{
    m_coverImageProvider = provider;
}

void Player::pushCoverArt()
{
    if (!m_coverImageProvider) return;

    Queue *q = activeQueue();
    if (!q || q->currentTrackIndex() < 0) {
        m_coverImageProvider->updateCover(QImage());
        emit coverArtChanged();
        return;
    }

    Track t = q->trackAt(q->currentTrackIndex());

    // Only push if we actually have cover art
    if (!t.coverArt.isNull()) {
        m_coverImageProvider->updateCover(t.coverArt);
        emit coverArtChanged();
    }
}

void Player::registerAlbumCovers(AlbumCoverProvider *provider)
{
    QStringList albums = m_library->allAlbums();
    for (const QString &album : std::as_const(albums)) {
        // Skip already registered albums
        if (provider->hasAlbum(album))
            continue;
        QList<Track> tracks = m_library->tracksByAlbum(album);
        if (!tracks.isEmpty())
            provider->registerAlbum(album, tracks.first().path);
    }
}

void Player::setAlbumCoverProvider(AlbumCoverProvider *provider)
{
    m_albumCoverProvider = provider;
    registerAlbumCovers(provider);
}

// --- Sort getters ---

int Player::albumSort() const
{
    return static_cast<int>(m_albumSort);
}

bool Player::albumSortAscending() const
{
    return m_albumSortAscending;
}

int Player::trackSort() const
{
    return static_cast<int>(m_trackSort);
}

bool Player::trackSortAscending() const
{
    return m_trackSortAscending;
}

// --- Sort setters ---

void Player::setAlbumSort(int sort)
{
    m_albumSort = static_cast<Library::AlbumSort>(sort);
    emit albumSortChanged();
    emit libraryChanged();
}

void Player::setAlbumSortAscending(bool ascending)
{
    m_albumSortAscending = ascending;
    emit albumSortChanged();
    emit libraryChanged();
}

void Player::setTrackSort(int sort)
{
    m_trackSort = static_cast<Library::TrackSort>(sort);
    qDebug() << "trackSort changed to" << sort;
    emit trackSortChanged();
}

void Player::setTrackSortAscending(bool ascending)
{
    m_trackSortAscending = ascending;
    emit trackSortChanged();
}
void Player::moveTrack(int from, int to)
{
    if (Queue *q = activeQueue())
        q->moveTrack(from, to);
}

bool Player::isAlbumActiveQueue(const QString &album) const
{
    Queue *q = activeQueue();
    if (!q || q->trackCount() == 0) return false;
    if (q->name() != album) return false;

    // Also verify track count matches — if tracks were deleted
    // treat it as a different queue and reload fresh
    QList<Track> albumTracks = m_library->tracksByAlbum(
        album,
        m_trackSort,
        m_trackSortAscending
        );

    return q->trackCount() == albumTracks.size();
}

void Player::jumpToTrackByPath(const QString &path)
{
    Queue *q = activeQueue();
    if (!q) return;
    for (int i = 0; i < q->trackCount(); i++) {
        if (q->trackAt(i).path == path) {
            q->loadTrackAt(i);
            return;
        }
    }
    // Path not found in queue — add it and play
    q->addTrack(path);
    q->loadTrackAt(q->trackCount() - 1);
}

void Player::addAlbumToQueue(const QString &album)
{
    Queue *q = activeQueue();
    if (!q) return;

    QList<Track> tracks = m_library->tracksByAlbum(
        album,
        m_trackSort,
        m_trackSortAscending
        );

    for (const Track &t : std::as_const(tracks))
        q->addTrack(t.path);
}

void Player::addTrackToQueue(const QString &path)
{
    Queue *q = activeQueue();
    if (!q) return;
    q->addTrack(path);
}

QVariantMap Player::trackInfoByPath(const QString &path) const
{
    QVariantMap map;

    // Check active queue first — it may have tracks not in library
    Queue *q = activeQueue();
    if (q) {
        for (int i = 0; i < q->trackCount(); i++) {
            Track t = q->trackAt(i);
            if (t.path == path) {
                map["path"]        = t.path;
                map["title"]       = t.title;
                map["artist"]      = t.artist;
                map["album"]       = t.album;
                map["albumArtist"] = t.albumArtist;
                map["composer"]    = t.composer;
                map["genre"]       = t.genre;
                map["trackNumber"] = t.trackNumber;
                map["discNumber"]  = t.discNumber;
                map["year"]        = t.year;
                map["duration"]    = t.duration;
                map["playCount"]   = t.playCount;
                map["dateAdded"]   = t.dateAdded;
                map["dateLastPlayed"] = t.dateLastPlayed;
                return map;
            }
        }
    }

    // Fall back to library
    QList<Track> tracks = m_library->allTracks();
    for (const Track &t : std::as_const(tracks)) {
        if (t.path == path) {
            map["path"]        = t.path;
            map["title"]       = t.title;
            map["artist"]      = t.artist;
            map["album"]       = t.album;
            map["albumArtist"] = t.albumArtist;
            map["composer"]    = t.composer;
            map["genre"]       = t.genre;
            map["trackNumber"] = t.trackNumber;
            map["discNumber"]  = t.discNumber;
            map["year"]        = t.year;
            map["duration"]    = t.duration;
            map["playCount"]   = t.playCount;
            map["dateAdded"]   = t.dateAdded;
            map["dateLastPlayed"] = t.dateLastPlayed;
            return map;
        }
    }

    return map;
}

void Player::rebuildLyricLines()
{
    m_lyricLines.clear();
    if (!activeQueue()) return;

    Track current = activeQueue()->trackAt(activeQueue()->currentTrackIndex());
    qDebug() << "rebuildLyricLines: path =" << current.path;
    if (current.path.isEmpty()) return;

    Track fresh = Metadata::read(current.path);
    qDebug() << "rebuildLyricLines: lyrics length =" << fresh.lyrics.length();
    qDebug() << "rebuildLyricLines: isLrc =" << LrcParser::isLrc(fresh.lyrics);
    qDebug() << "rebuildLyricLines: first 100 chars =" << fresh.lyrics.left(100);

    m_rawLyrics = fresh.lyrics;

    if (LrcParser::isLrc(fresh.lyrics))
        m_lyricLines = LrcParser::parse(fresh.lyrics);

    qDebug() << "rebuildLyricLines: parsed line count =" << m_lyricLines.size();
}

QStringList Player::albumsForArtist(const QString &artist) const
{
    return m_library->albumsForArtist(artist);
}

QVariantList Player::allPlaylists() const
{
    QVariantList result;
    for (const PlaylistInfo &p : m_library->allPlaylists()) {
        QVariantMap map;
        map["id"]   = p.id;
        map["name"] = p.name;
        result << map;
    }
    return result;
}

int Player::createPlaylist(const QString &name)
{
    return m_library->createPlaylist(name);
}

void Player::deletePlaylist(int playlistId)
{
    m_library->deletePlaylist(playlistId);
}

void Player::renamePlaylist(int playlistId, const QString &name)
{
    m_library->renamePlaylist(playlistId, name);
}

void Player::addTrackToPlaylist(int playlistId, const QString &path)
{
    m_library->addTrackToPlaylist(playlistId, path);
}

void Player::removeTrackFromPlaylist(int playlistId, const QString &path)
{
    m_library->removeTrackFromPlaylist(playlistId, path);
}

void Player::moveTrackInPlaylist(int playlistId, int from, int to)
{
    m_library->moveTrackInPlaylist(playlistId, from, to);
}

int Player::saveQueueAsPlaylist(const QString &name)
{
    if (!activeQueue()) return -1;
    QStringList paths;
    for (const Track &t : activeQueue()->tracks())
        paths << t.path;
    return m_library->saveQueueAsPlaylist(name, paths);
}

QVariantList Player::tracksForPlaylist(int playlistId) const
{
    QVariantList result;
    for (const Track &t : m_library->tracksForPlaylist(playlistId)) {
        QVariantMap map;
        map["path"]     = t.path;
        map["title"]    = t.title;
        map["artist"]   = t.artist;
        map["album"]    = t.album;
        map["duration"] = t.duration;
        result << map;
    }
    return result;
}

void Player::openPlaylistInNewQueue(int playlistId, const QString &name)
{
    QList<Track> tracks = m_library->tracksForPlaylist(playlistId);
    QStringList paths;
    for (const Track &t : tracks)
        paths << t.path;
    if (!paths.isEmpty())
        openFilesInNewQueue(paths, name);
}

void Player::requestAddToPlaylist(const QString &path)
{
    emit addToPlaylistRequested(path);
}

void Player::requestAddAlbumToPlaylist(const QString &albumName)
{
    emit addAlbumToPlaylistRequested(albumName);
}

int  Player::playlistSort()          const { return static_cast<int>(m_playlistSort); }
bool Player::playlistSortAscending() const { return m_playlistSortAscending; }

void Player::setPlaylistSort(int sort)
{
    m_playlistSort = static_cast<Library::TrackSort>(sort);
    emit playlistSortChanged();
}

void Player::setPlaylistSortAscending(bool ascending)
{
    m_playlistSortAscending = ascending;
    emit playlistSortChanged();
}

void Player::sortPlaylist(int playlistId)
{
    m_library->sortPlaylist(playlistId, m_playlistSort, m_playlistSortAscending);
}