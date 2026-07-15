#include "natsuyumecore.h"

// Internal Qt-based managers — hidden from the public header via pImpl
#include "queuesession.h"
#include "queuemanager.h"
#include "playbackmanager.h"
#include "playlistmanager.h"
#include "librarymanager.h"
#include "library.h"

#include <QObject>
#include <QBuffer>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QList>

namespace Natsuyume {

// ---------------------------------------------------------------------------
// Helpers: convert between Qt and Core types
// ---------------------------------------------------------------------------

static CoreTrack toCoreTrack(const Track &t)
{
    CoreTrack c;
    c.path        = t.path.toStdString();
    c.title       = t.title.toStdString();
    c.artist      = t.artist.toStdString();
    c.album       = t.album.toStdString();
    c.albumArtist = t.albumArtist.toStdString();
    c.composer    = t.composer.toStdString();
    c.genre       = t.genre.toStdString();
    c.trackNumber = t.trackNumber;
    c.discNumber  = t.discNumber;
    c.year        = t.year;
    c.duration    = t.duration;
    c.dateAdded      = t.dateAdded;
    c.dateLastPlayed = t.dateLastPlayed;
    c.playCount   = t.playCount;
    c.isFavorite  = t.isFavorite;
    c.lyrics      = t.lyrics.toStdString();
    c.lastModified = t.lastModified;

    // Cover art: convert QImage to raw JPEG bytes
    if (!t.coverArt.isNull()) {
        QByteArray buf;
        QBuffer qbuf(&buf);
        qbuf.open(QIODevice::WriteOnly);
        t.coverArt.save(&qbuf, "JPEG");
        c.coverArtData.assign(
            reinterpret_cast<const uint8_t *>(buf.constData()),
            reinterpret_cast<const uint8_t *>(buf.constData()) + buf.size());
        c.coverArtMimeType = "image/jpeg";
    }

    return c;
}

static std::vector<CoreTrack> toCoreTrackList(const QList<Track> &tracks)
{
    std::vector<CoreTrack> result;
    result.reserve(tracks.size());
    for (const Track &t : tracks)
        result.push_back(toCoreTrack(t));
    return result;
}

static std::vector<std::string> toStdStringVec(const QStringList &list)
{
    std::vector<std::string> result;
    result.reserve(list.size());
    for (const QString &s : list)
        result.push_back(s.toStdString());
    return result;
}

static QStringList toQStringList(const std::vector<std::string> &vec)
{
    QStringList result;
    result.reserve(static_cast<int>(vec.size()));
    for (const std::string &s : vec)
        result.append(QString::fromStdString(s));
    return result;
}

// ---------------------------------------------------------------------------
// Impl — owns all Qt managers; hidden behind pImpl
// ---------------------------------------------------------------------------

struct NatsuyumeCore::Impl : public QObject
{
    Q_OBJECT
public:
    CoreCallbacks *callbacks = nullptr;   // non-owning pointer to Core::callbacks

    QueueSession    *session         = nullptr;
    QueueManager    *queueManager    = nullptr;
    PlaybackManager *playbackManager = nullptr;
    PlaylistManager *playlistManager = nullptr;
    LibraryManager  *libraryManager  = nullptr;

    explicit Impl(QObject *parent = nullptr) : QObject(parent) {}

    void init(CoreCallbacks *cb)
    {
        callbacks = cb;

        session         = new QueueSession(this);
        queueManager    = new QueueManager(session, this);
        playbackManager = new PlaybackManager(session, this);
        playlistManager = new PlaylistManager(session, this);
        libraryManager  = new LibraryManager(this);

        libraryManager->open();

        Library *lib = libraryManager->library();
        queueManager->setLibrary(lib);
        playbackManager->setLibrary(lib);
        playlistManager->setLibrary(lib);
        playlistManager->initialize();

        wireSignals();

        playbackManager->loadSettings();
        libraryManager->loadSettings();
        playlistManager->loadSettings();

        queueManager->loadQueues(playbackManager->volume());
    }

    void shutdown()
    {
        playbackManager->saveSettings();
        libraryManager->saveSettings();
        playlistManager->saveSettings();
        queueManager->saveQueues(session->viewedQueueIndex());
    }

    // -----------------------------------------------------------------------
    // Wire Qt signals → CoreCallbacks
    // Every signal from every manager is bridged here.
    // -----------------------------------------------------------------------
    void wireSignals()
    {
        // --- PlaybackManager ---
        connect(playbackManager, &PlaybackManager::isPlayingChanged, this, [this]() {
            if (callbacks->onPlaybackStateChanged)
                callbacks->onPlaybackStateChanged(playbackManager->isPlaying());
        });
        connect(playbackManager, &PlaybackManager::positionChanged, this, [this]() {
            if (callbacks->onPositionChanged)
                callbacks->onPositionChanged(playbackManager->position());
        });
        connect(playbackManager, &PlaybackManager::durationChanged, this, [this]() {
            if (callbacks->onDurationChanged)
                callbacks->onDurationChanged(playbackManager->duration());
        });
        connect(playbackManager, &PlaybackManager::volumeChanged, this, [this]() {
            if (callbacks->onVolumeChanged)
                callbacks->onVolumeChanged(playbackManager->volume());
        });
        connect(playbackManager, &PlaybackManager::metadataChanged, this, [this]() {
            if (callbacks->onMetadataChanged)
                callbacks->onMetadataChanged();
        });
        connect(playbackManager, &PlaybackManager::coverArtChanged, this, [this]() {
            if (callbacks->onMetadataChanged)
                callbacks->onMetadataChanged();
        });
        connect(playbackManager, &PlaybackManager::repeatModeChanged, this, [this]() {
            if (callbacks->onRepeatModeChanged)
                callbacks->onRepeatModeChanged();
        });
        connect(playbackManager, &PlaybackManager::shuffleChanged, this, [this]() {
            if (callbacks->onShuffleChanged)
                callbacks->onShuffleChanged();
        });
        connect(playbackManager, &PlaybackManager::stopAfterCurrentChanged, this, [this]() {
            if (callbacks->onStopAfterCurrentChanged)
                callbacks->onStopAfterCurrentChanged();
        });
        connect(playbackManager, &PlaybackManager::playingTrackChanged, this, [this]() {
            if (callbacks->onTrackChanged) {
                // Build CoreTrack from current playing track
                Queue *q = session->playingQueue();
                if (q && q->currentTrackIndex() >= 0) {
                    Track t = q->trackAt(q->currentTrackIndex());
                    callbacks->onTrackChanged(toCoreTrack(t));
                }
            }
            if (callbacks->onQueueChanged)
                callbacks->onQueueChanged();
        });
        connect(playbackManager, &PlaybackManager::isFavoriteChanged, this, [this]() {
            if (callbacks->onFavoriteChanged) {
                Queue *q = session->playingQueue();
                if (q && q->currentTrackIndex() >= 0) {
                    QString path = q->trackAt(q->currentTrackIndex()).path;
                    callbacks->onFavoriteChanged(playlistManager->isFavorite(path));
                }
            }
        });
        connect(playbackManager, &PlaybackManager::abRepeatChanged, this, [this]() {
            if (callbacks->onAbRepeatChanged)
                callbacks->onAbRepeatChanged();
        });

        // --- QueueSession ---
        connect(session, &QueueSession::queuesChanged, this, [this]() {
            if (callbacks->onQueuesChanged)
                callbacks->onQueuesChanged();
        });
        connect(session, &QueueSession::viewedQueueChanged, this, [this]() {
            if (callbacks->onQueueChanged)
                callbacks->onQueueChanged();
        });

        // --- QueueManager → PlaybackManager wiring (unchanged from PlayerController) ---
        connect(queueManager, &QueueManager::playbackTransferRequested,
                this, [this](int newQueueIndex) {
                    playbackManager->destroyPlayback(session->playingQueueIndex());
                    session->setPlayingQueueIndex(newQueueIndex);
                    playbackManager->initPlayback(newQueueIndex);
                });
        connect(queueManager, &QueueManager::playbackDestroyRequested,
                this, [this](int queueIndex) {
                    playbackManager->destroyPlayback(queueIndex);
                });
        connect(queueManager, &QueueManager::playbackInitRequested,
                this, [this](int queueIndex) {
                    session->setPlayingQueueIndex(queueIndex);
                    playbackManager->initPlayback(queueIndex);
                });
        connect(queueManager, &QueueManager::playbackInitNewRequested,
                this, [this](int queueIndex) {
                    session->setPlayingQueueIndex(queueIndex);
                    playbackManager->initPlayback(queueIndex);
                });
        connect(queueManager, &QueueManager::playbackRestoreRequested,
                this, [this](int queueIndex) {
                    session->setPlayingQueueIndex(queueIndex);
                    playbackManager->restorePlaybackState(queueIndex);
                });

        // --- PlaylistManager ---
        connect(playlistManager, &PlaylistManager::playlistsChanged, this, [this]() {
            if (callbacks->onPlaylistsChanged)
                callbacks->onPlaylistsChanged();
        });
        connect(playlistManager, &PlaylistManager::playlistSortChanged, this, [this]() {
            if (callbacks->onPlaylistSortChanged)
                callbacks->onPlaylistSortChanged();
        });
        connect(playlistManager, &PlaylistManager::isFavoriteChanged, this, [this]() {
            if (callbacks->onFavoriteChanged) {
                Queue *q = session->playingQueue();
                bool fav = false;
                if (q && q->currentTrackIndex() >= 0)
                    fav = playlistManager->isFavorite(
                        q->trackAt(q->currentTrackIndex()).path);
                callbacks->onFavoriteChanged(fav);
            }
        });

        // --- LibraryManager ---
        connect(libraryManager, &LibraryManager::libraryChanged, this, [this]() {
            if (callbacks->onLibraryChanged)
                callbacks->onLibraryChanged();
        });
        connect(libraryManager, &LibraryManager::scanningChanged, this, [this]() {
            if (callbacks->onScanningChanged)
                callbacks->onScanningChanged(libraryManager->isScanning());
        });
        connect(libraryManager, &LibraryManager::scanProgressChanged, this, [this]() {
            if (callbacks->onScanProgressChanged)
                callbacks->onScanProgressChanged(
                    libraryManager->scanProgress(),
                    libraryManager->scanTotal(),
                    libraryManager->scanningFile().toStdString());
        });
        connect(libraryManager, &LibraryManager::albumSortChanged, this, [this]() {
            if (callbacks->onAlbumSortChanged)
                callbacks->onAlbumSortChanged();
        });
        connect(libraryManager, &LibraryManager::trackSortChanged, this, [this]() {
            if (callbacks->onTrackSortChanged)
                callbacks->onTrackSortChanged();
        });
        connect(libraryManager, &LibraryManager::scanFoldersChanged, this, [this]() {
            if (callbacks->onScanFoldersChanged)
                callbacks->onScanFoldersChanged();
        });
    }
};

// ---------------------------------------------------------------------------
// NatsuyumeCore — public implementation
// ---------------------------------------------------------------------------

NatsuyumeCore::NatsuyumeCore()
    : m_impl(new Impl())
{}

NatsuyumeCore::~NatsuyumeCore()
{
    delete m_impl;
}

bool NatsuyumeCore::init()
{
    m_impl->init(&callbacks);
    return true;
}

void NatsuyumeCore::shutdown()
{
    m_impl->shutdown();
}

// --- Playback ---

void NatsuyumeCore::play()                     { m_impl->playbackManager->play(); }
void NatsuyumeCore::pause()                    { m_impl->playbackManager->pause(); }
void NatsuyumeCore::seekTo(int64_t ms)         { m_impl->playbackManager->seekTo(ms); }
void NatsuyumeCore::playNext()                 { m_impl->playbackManager->playNext(); }
void NatsuyumeCore::playPrevious()             { m_impl->playbackManager->playPrevious(); }
void NatsuyumeCore::cycleRepeatMode()          { m_impl->playbackManager->cycleRepeatMode(); }
void NatsuyumeCore::toggleShuffle()            { m_impl->playbackManager->toggleShuffle(); }
void NatsuyumeCore::toggleStopAfterCurrent()   { m_impl->playbackManager->toggleStopAfterCurrent(); }
void NatsuyumeCore::setVolume(float v)         { m_impl->playbackManager->setVolume(v); }

bool    NatsuyumeCore::isPlaying()        const { return m_impl->playbackManager->isPlaying(); }
int64_t NatsuyumeCore::position()         const { return m_impl->playbackManager->position(); }
int64_t NatsuyumeCore::duration()         const { return m_impl->playbackManager->duration(); }
float   NatsuyumeCore::volume()           const { return m_impl->playbackManager->volume(); }
int     NatsuyumeCore::repeatMode()       const { return m_impl->playbackManager->repeatMode(); }
bool    NatsuyumeCore::isShuffled()       const { return m_impl->playbackManager->isShuffled(); }
bool    NatsuyumeCore::stopAfterCurrent() const { return m_impl->playbackManager->stopAfterCurrent(); }

// --- Current track ---

CoreTrack NatsuyumeCore::currentTrack() const
{
    Queue *q = m_impl->session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return {};
    return toCoreTrack(q->trackAt(q->currentTrackIndex()));
}

bool NatsuyumeCore::isFavorite() const
{
    Queue *q = m_impl->session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return false;
    return m_impl->playlistManager->isFavorite(
        q->trackAt(q->currentTrackIndex()).path);
}

// --- Playing-queue navigation ---

int  NatsuyumeCore::playingTrackIndex() const { return m_impl->playbackManager->playingTrackIndex(); }
int  NatsuyumeCore::playingTrackCount() const { return m_impl->playbackManager->playingTrackCount(); }
bool NatsuyumeCore::hasPrevious()       const { return m_impl->playbackManager->hasPrevious(); }
bool NatsuyumeCore::hasNext()           const { return m_impl->playbackManager->hasNext(); }

// --- Viewed-queue navigation ---

int NatsuyumeCore::viewedTrackIndex() const
{
    Queue *q = m_impl->session->viewedQueue();
    return q ? q->currentTrackIndex() : -1;
}

int NatsuyumeCore::viewedTrackCount() const
{
    Queue *q = m_impl->session->viewedQueue();
    return q ? q->trackCount() : 0;
}

// --- Queue operations ---

void NatsuyumeCore::openFilesInNewQueue(const std::vector<std::string> &paths,
                                        const std::string &name, bool shuffle)
{
    m_impl->queueManager->openFilesInNewQueue(toQStringList(paths),
                                              QString::fromStdString(name), shuffle);
}

void NatsuyumeCore::addPathsToNewQueue(const std::vector<std::string> &paths,
                                       const std::string &name)
{
    m_impl->queueManager->addPathsToNewQueue(toQStringList(paths),
                                             QString::fromStdString(name));
}

void NatsuyumeCore::addPathsToQueue(int index, const std::vector<std::string> &paths)
{
    m_impl->queueManager->addPathsToQueue(index, toQStringList(paths));
}

void NatsuyumeCore::closeQueue(int index)   { m_impl->queueManager->closeQueue(index); }
void NatsuyumeCore::renameQueue(int index, const std::string &name)
{
    m_impl->queueManager->renameQueue(index, QString::fromStdString(name));
}
void NatsuyumeCore::moveQueue(int from, int to) { m_impl->queueManager->moveQueue(from, to); }
void NatsuyumeCore::viewQueue(int index)        { m_impl->queueManager->viewQueue(index); }

void NatsuyumeCore::addTrackToQueue(const std::string &path)
{
    m_impl->queueManager->addTrackToQueue(QString::fromStdString(path));
}

void NatsuyumeCore::addAlbumToQueue(const std::string &album)
{
    m_impl->queueManager->addAlbumToQueue(
        QString::fromStdString(album),
        static_cast<Library::TrackSort>(m_impl->libraryManager->trackSort()),
        m_impl->libraryManager->trackSortAscending());
}

void NatsuyumeCore::removeTrackAt(int index)        { m_impl->queueManager->removeTrackAt(index); }
void NatsuyumeCore::moveTrack(int from, int to)     { m_impl->queueManager->moveTrack(from, to); }
void NatsuyumeCore::sortActiveQueue(int sort, bool ascending)
{
    m_impl->queueManager->sortQueue(sort, ascending);
}
void NatsuyumeCore::reverseActiveQueue()            { m_impl->queueManager->reverseQueue(); }
void NatsuyumeCore::jumpToTrack(int index)          { m_impl->queueManager->jumpToTrack(index); }
void NatsuyumeCore::jumpToTrackByPath(const std::string &path)
{
    m_impl->queueManager->jumpToTrackByPath(QString::fromStdString(path));
}
void NatsuyumeCore::saveQueues()
{
    m_impl->queueManager->saveQueues(m_impl->session->viewedQueueIndex());
}
void NatsuyumeCore::loadQueues()
{
    m_impl->queueManager->loadQueues(m_impl->playbackManager->volume());
}

// --- Queue state ---

int NatsuyumeCore::queueCount()        const { return m_impl->session->queueCount(); }
int NatsuyumeCore::activeQueueIndex()  const { return m_impl->session->viewedQueueIndex(); }
int NatsuyumeCore::playingQueueIndex() const { return m_impl->session->playingQueueIndex(); }

std::vector<std::string> NatsuyumeCore::queueNames() const
{
    return toStdStringVec(m_impl->queueManager->queueNames());
}

int64_t NatsuyumeCore::queueTotalDuration() const
{
    return m_impl->queueManager->queueTotalDuration();
}

bool NatsuyumeCore::isAlbumActiveQueue(const std::string &album) const
{
    return m_impl->queueManager->isAlbumActiveQueue(
        QString::fromStdString(album),
        static_cast<Library::TrackSort>(m_impl->libraryManager->trackSort()),
        m_impl->libraryManager->trackSortAscending());
}

std::vector<CoreTrack> NatsuyumeCore::trackList() const
{
    // QueueManager returns QVariantList for QML; bypass it and go direct
    Queue *q = m_impl->session->viewedQueue();
    if (!q) return {};
    return toCoreTrackList(q->tracks());
}

CoreTrack NatsuyumeCore::trackInfoByPath(const std::string &path) const
{
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrack(lib->trackByPath(QString::fromStdString(path)));
}

// --- Library ---

void NatsuyumeCore::scanFolder(const std::string &path)
{
    m_impl->libraryManager->scanFolder(QString::fromStdString(path));
}
void NatsuyumeCore::cancelScan()        { m_impl->libraryManager->cancelScan(); }
void NatsuyumeCore::addScanFolder(const std::string &path)
{
    m_impl->libraryManager->addScanFolder(QString::fromStdString(path));
}
void NatsuyumeCore::removeScanFolder(const std::string &path)
{
    m_impl->libraryManager->removeScanFolder(QString::fromStdString(path));
}
void NatsuyumeCore::rescanAllFolders()  { m_impl->libraryManager->rescanAllFolders(); }
bool NatsuyumeCore::isScanning()   const { return m_impl->libraryManager->isScanning(); }
int  NatsuyumeCore::scanProgress() const { return m_impl->libraryManager->scanProgress(); }
int  NatsuyumeCore::scanTotal()    const { return m_impl->libraryManager->scanTotal(); }
std::string NatsuyumeCore::scanningFile() const
{
    return m_impl->libraryManager->scanningFile().toStdString();
}

// --- Library queries ---

std::vector<std::string> NatsuyumeCore::allAlbums() const
{
    return toStdStringVec(m_impl->libraryManager->allAlbums());
}
std::vector<std::string> NatsuyumeCore::allArtists() const
{
    return toStdStringVec(m_impl->libraryManager->allArtists());
}
std::vector<CoreTrack> NatsuyumeCore::tracksForAlbum(const std::string &album) const
{
    // Go direct to Library to get Track objects, not QVariantList
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrackList(lib->tracksByAlbum(
        QString::fromStdString(album),
        static_cast<Library::TrackSort>(m_impl->libraryManager->trackSort()),
        m_impl->libraryManager->trackSortAscending()));
}
std::vector<CoreTrack> NatsuyumeCore::tracksForArtist(const std::string &artist) const
{
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrackList(lib->tracksByArtist(QString::fromStdString(artist)));
}
std::vector<std::string> NatsuyumeCore::albumsForArtist(const std::string &artist) const
{
    return toStdStringVec(
        m_impl->libraryManager->albumsForArtist(QString::fromStdString(artist)));
}
std::vector<std::string> NatsuyumeCore::allArtistsSorted() const
{
    return toStdStringVec(m_impl->libraryManager->allArtistsSorted());
}
std::string NatsuyumeCore::albumCoverPath(const std::string &album) const
{
    return m_impl->libraryManager->albumCoverPath(
                                     QString::fromStdString(album)).toStdString();
}

// --- Sort ---

int  NatsuyumeCore::albumSort()           const { return m_impl->libraryManager->albumSort(); }
bool NatsuyumeCore::albumSortAscending()  const { return m_impl->libraryManager->albumSortAscending(); }
int  NatsuyumeCore::trackSort()           const { return m_impl->libraryManager->trackSort(); }
bool NatsuyumeCore::trackSortAscending()  const { return m_impl->libraryManager->trackSortAscending(); }
int  NatsuyumeCore::artistSort()          const { return m_impl->libraryManager->artistSort(); }
bool NatsuyumeCore::artistSortAscending() const { return m_impl->libraryManager->artistSortAscending(); }
int  NatsuyumeCore::playlistSort()        const { return m_impl->playlistManager->playlistSort(); }
bool NatsuyumeCore::playlistSortAscending() const { return m_impl->playlistManager->playlistSortAscending(); }

void NatsuyumeCore::setAlbumSort(int s)              { m_impl->libraryManager->setAlbumSort(s); }
void NatsuyumeCore::setAlbumSortAscending(bool a)    { m_impl->libraryManager->setAlbumSortAscending(a); }
void NatsuyumeCore::setTrackSort(int s)              { m_impl->libraryManager->setTrackSort(s); }
void NatsuyumeCore::setTrackSortAscending(bool a)    { m_impl->libraryManager->setTrackSortAscending(a); }
void NatsuyumeCore::setArtistSort(int s)             { m_impl->libraryManager->setArtistSort(s); }
void NatsuyumeCore::setArtistSortAscending(bool a)   { m_impl->libraryManager->setArtistSortAscending(a); }
void NatsuyumeCore::setPlaylistSort(int s)           { m_impl->playlistManager->setPlaylistSort(s); }
void NatsuyumeCore::setPlaylistSortAscending(bool a) { m_impl->playlistManager->setPlaylistSortAscending(a); }

// --- Playlists ---

int  NatsuyumeCore::createPlaylist(const std::string &name)
{
    return m_impl->playlistManager->createPlaylist(QString::fromStdString(name));
}
void NatsuyumeCore::deletePlaylist(int id)       { m_impl->playlistManager->deletePlaylist(id); }
void NatsuyumeCore::renamePlaylist(int id, const std::string &name)
{
    m_impl->playlistManager->renamePlaylist(id, QString::fromStdString(name));
}
void NatsuyumeCore::addTrackToPlaylist(int id, const std::string &path)
{
    m_impl->playlistManager->addTrackToPlaylist(id, QString::fromStdString(path));
}
void NatsuyumeCore::removeTrackFromPlaylist(int id, const std::string &path)
{
    m_impl->playlistManager->removeTrackFromPlaylist(id, QString::fromStdString(path));
}
void NatsuyumeCore::moveTrackInPlaylist(int id, int from, int to)
{
    m_impl->playlistManager->moveTrackInPlaylist(id, from, to);
}
void NatsuyumeCore::sortPlaylist(int id)         { m_impl->playlistManager->sortPlaylist(id); }
int  NatsuyumeCore::saveQueueAsPlaylist(const std::string &name)
{
    return m_impl->playlistManager->saveQueueAsPlaylist(QString::fromStdString(name));
}
void NatsuyumeCore::openPlaylistInNewQueue(int id, const std::string &name)
{
    m_impl->playlistManager->openPlaylistInNewQueue(id, QString::fromStdString(name));
}

std::vector<CorePlaylistInfo> NatsuyumeCore::allPlaylists() const
{
    std::vector<CorePlaylistInfo> result;
    Library *lib = m_impl->libraryManager->library();
    for (const PlaylistInfo &p : lib->allPlaylists())
        result.push_back({p.id, p.name.toStdString()});
    return result;
}

std::vector<CoreTrack> NatsuyumeCore::tracksForPlaylist(int id) const
{
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrackList(lib->tracksForPlaylist(id));
}

int NatsuyumeCore::allSongsPlaylistId()  { return PlaylistManager::kAllSongsPlaylistId; }
int NatsuyumeCore::favoritesPlaylistId() { return PlaylistManager::kFavoritesPlaylistId; }

// --- Favorites ---

void NatsuyumeCore::toggleFavorite()
{
    Queue *q = m_impl->session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return;
    m_impl->playlistManager->toggleFavorite(
        q->trackAt(q->currentTrackIndex()).path);
}

// --- Settings ---

std::vector<std::string> NatsuyumeCore::scanFolders() const
{
    return toStdStringVec(m_impl->libraryManager->scanFolders());
}
int  NatsuyumeCore::playCountThreshold() const
{
    return m_impl->playbackManager->playCountThreshold();
}
void NatsuyumeCore::setPlayCountThreshold(int p)
{
    m_impl->playbackManager->setPlayCountThreshold(p);
}
void NatsuyumeCore::saveSettings()
{
    m_impl->playbackManager->saveSettings();
    m_impl->libraryManager->saveSettings();
    m_impl->playlistManager->saveSettings();
}

// --- A-B repeat ---

bool    NatsuyumeCore::abRepeatActive() const { return m_impl->playbackManager->abRepeatActive(); }
int64_t NatsuyumeCore::pointA()         const { return m_impl->playbackManager->pointA(); }
int64_t NatsuyumeCore::pointB()         const { return m_impl->playbackManager->pointB(); }
void    NatsuyumeCore::setPointA()            { m_impl->playbackManager->setPointA(); }
void    NatsuyumeCore::setPointB()            { m_impl->playbackManager->setPointB(); }
void    NatsuyumeCore::clearAbRepeat()        { m_impl->playbackManager->clearAbRepeat(); }

} // namespace Natsuyume

// Required because Impl uses Q_OBJECT and is defined in a .cpp
#include "natsuyumecore.moc"