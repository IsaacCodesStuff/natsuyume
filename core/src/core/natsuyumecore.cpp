#include "natsuyumecore.h"

#include "queuesession.h"
#include "queuemanager.h"
#include "playbackmanager.h"
#include "userdatamanager.h"
#include "librarymanager.h"
#include "library.h"

#include <unistd.h>
#include <poll.h>

namespace Natsuyume {

// ---------------------------------------------------------------------------
// toCoreTrack — internal helper (Track → CoreTrack)
// ---------------------------------------------------------------------------

static CoreTrack toCoreTrack(const Track &t)
{
    CoreTrack c;
    c.path             = t.path;
    c.title            = t.title;
    c.artist           = t.artist;
    c.album            = t.album;
    c.albumArtist      = t.albumArtist;
    c.composer         = t.composer;
    c.genre            = t.genre;
    c.trackNumber      = t.trackNumber;
    c.discNumber       = t.discNumber;
    c.year             = t.year;
    c.duration         = t.duration;
    c.dateAdded        = t.dateAdded;
    c.dateLastPlayed   = t.dateLastPlayed;
    c.playCount        = t.playCount;
    c.isFavorite       = t.isFavorite;
    c.coverArtData     = t.coverArtData;
    c.coverArtMimeType = t.coverArtMimeType;
    c.lyrics           = t.lyrics;
    c.lastModified     = t.lastModified;
    return c;
}

static std::vector<CoreTrack> toCoreTrackList(const std::vector<Track> &tracks)
{
    std::vector<CoreTrack> result;
    result.reserve(tracks.size());
    for (const Track &t : tracks)
        result.push_back(toCoreTrack(t));
    return result;
}

// ---------------------------------------------------------------------------
// Impl — plain struct, no QObject
// ---------------------------------------------------------------------------

struct NatsuyumeCore::Impl
{
    CoreCallbacks      *callbacks        = nullptr;
    std::string         dataDir;

    QueueSession       *session          = nullptr;
    QueueManager       *queueManager     = nullptr;
    PlaybackManager    *playbackManager  = nullptr;
    UserDataManager    *userDataManager  = nullptr;
    LibraryManager     *libraryManager   = nullptr;

    ~Impl()
    {
        delete libraryManager;
        delete userDataManager;
        delete playbackManager;
        delete queueManager;
        delete session;
    }

    bool init(CoreCallbacks *cb, const std::string &dir)
    {
        callbacks = cb;
        dataDir   = dir;

        session         = new QueueSession();
        queueManager    = new QueueManager(session);
        playbackManager = new PlaybackManager(session);
        userDataManager = new UserDataManager();
        libraryManager  = new LibraryManager();

        if (!libraryManager->open(dataDir))   return false;
        if (!userDataManager->open(dataDir))  return false;

        Library *lib = libraryManager->library();
        queueManager->setLibrary(lib);
        playbackManager->setLibrary(lib);
        userDataManager->setLibrary(lib);
        playbackManager->setUserDataManager(userDataManager);

        wireCallbacks();

        playbackManager->loadSettings(dataDir);
        libraryManager->loadSettings();
        userDataManager->loadSettings(dataDir);

        queueManager->loadQueues(playbackManager->volume());
        return true;
    }

    void shutdown()
    {
        playbackManager->saveSettings(dataDir);
        libraryManager->saveSettings();
        userDataManager->saveSettings(dataDir);
        queueManager->saveQueues(session->viewedQueueIndex());
    }

    // -----------------------------------------------------------------------
    // Wire all std::function callbacks — replaces wireSignals()/connect()
    // -----------------------------------------------------------------------
    void wireCallbacks()
    {
        // --- PlaybackManager → CoreCallbacks ---
        playbackManager->onIsPlayingChanged = [this]() {
            if (callbacks->onPlaybackStateChanged)
                callbacks->onPlaybackStateChanged(
                    playbackManager->isPlaying());
        };
        playbackManager->onPositionChanged = [this]() {
            if (callbacks->onPositionChanged)
                callbacks->onPositionChanged(playbackManager->position());
        };
        playbackManager->onDurationChanged = [this]() {
            if (callbacks->onDurationChanged)
                callbacks->onDurationChanged(playbackManager->duration());
        };
        playbackManager->onVolumeChanged = [this]() {
            if (callbacks->onVolumeChanged)
                callbacks->onVolumeChanged(playbackManager->volume());
        };
        playbackManager->onMetadataChanged = [this]() {
            if (callbacks->onMetadataChanged)
                callbacks->onMetadataChanged();
        };
        playbackManager->onRepeatModeChanged = [this]() {
            if (callbacks->onRepeatModeChanged)
                callbacks->onRepeatModeChanged();
        };
        playbackManager->onShuffleChanged = [this]() {
            if (callbacks->onShuffleChanged)
                callbacks->onShuffleChanged();
        };
        playbackManager->onStopAfterCurrentChanged = [this]() {
            if (callbacks->onStopAfterCurrentChanged)
                callbacks->onStopAfterCurrentChanged();
        };
        playbackManager->onPlayingTrackChanged = [this]() {
            if (callbacks->onTrackChanged) {
                Queue *q = session->playingQueue();
                if (q && q->currentTrackIndex() >= 0)
                    callbacks->onTrackChanged(
                        toCoreTrack(q->trackAt(q->currentTrackIndex())));
            }
            if (callbacks->onQueueChanged)
                callbacks->onQueueChanged();
        };
        playbackManager->onIsFavoriteChanged = [this]() {
            if (callbacks->onFavoriteChanged) {
                Queue *q = session->playingQueue();
                bool fav = false;
                if (q && q->currentTrackIndex() >= 0)
                    fav = userDataManager->isFavorite(
                        q->trackAt(q->currentTrackIndex()).path);
                callbacks->onFavoriteChanged(fav);
            }
        };
        playbackManager->onAbRepeatChanged = [this]() {
            if (callbacks->onAbRepeatChanged)
                callbacks->onAbRepeatChanged();
        };

        // --- QueueSession → CoreCallbacks ---
        session->onQueuesChanged = [this]() {
            if (callbacks->onQueuesChanged)
                callbacks->onQueuesChanged();
        };
        session->onViewedQueueChanged = [this]() {
            if (callbacks->onQueueChanged)
                callbacks->onQueueChanged();
        };

        // --- QueueManager → PlaybackManager wiring ---
        queueManager->onPlaybackTransferRequested = [this](int newIndex) {
            playbackManager->destroyPlayback(session->playingQueueIndex());
            session->setPlayingQueueIndex(newIndex);
            playbackManager->initPlayback(newIndex);
        };
        queueManager->onPlaybackDestroyRequested = [this](int index) {
            playbackManager->destroyPlayback(index);
        };
        queueManager->onPlaybackInitRequested = [this](int index) {
            session->setPlayingQueueIndex(index);
            playbackManager->initPlayback(index);
        };
        queueManager->onPlaybackInitNewRequested = [this](int index) {
            session->setPlayingQueueIndex(index);
            playbackManager->initPlayback(index);
        };
        queueManager->onPlaybackRestoreRequested = [this](int index) {
            session->setPlayingQueueIndex(index);
            playbackManager->restorePlaybackState(index);
        };

        // --- UserDataManager → CoreCallbacks ---
        userDataManager->onPlaylistsChanged = [this]() {
            if (callbacks->onPlaylistsChanged)
                callbacks->onPlaylistsChanged();
        };
        userDataManager->onPlaylistSortChanged = [this]() {
            if (callbacks->onPlaylistSortChanged)
                callbacks->onPlaylistSortChanged();
        };
        userDataManager->onIsFavoriteChanged = [this]() {
            if (callbacks->onFavoriteChanged) {
                Queue *q = session->playingQueue();
                bool fav = false;
                if (q && q->currentTrackIndex() >= 0)
                    fav = userDataManager->isFavorite(
                        q->trackAt(q->currentTrackIndex()).path);
                callbacks->onFavoriteChanged(fav);
            }
        };
        userDataManager->onOpenInNewQueueRequested =
            [this](const std::vector<std::string> &paths,
                   const std::string &name) {
                queueManager->openFilesInNewQueue(paths, name, false);
            };

        // --- LibraryManager → CoreCallbacks ---
        libraryManager->onLibraryChanged = [this]() {
            if (callbacks->onLibraryChanged)
                callbacks->onLibraryChanged();
        };
        libraryManager->onScanningChanged = [this]() {
            if (callbacks->onScanningChanged)
                callbacks->onScanningChanged(libraryManager->isScanning());
        };
        libraryManager->onScanProgressChanged =
            [this](int current, int total, const std::string &file) {
                if (callbacks->onScanProgressChanged)
                    callbacks->onScanProgressChanged(current, total, file);
            };
        libraryManager->onAlbumSortChanged = [this]() {
            if (callbacks->onAlbumSortChanged)
                callbacks->onAlbumSortChanged();
        };
        libraryManager->onTrackSortChanged = [this]() {
            if (callbacks->onTrackSortChanged)
                callbacks->onTrackSortChanged();
        };
        libraryManager->onScanFoldersChanged = [this]() {
            if (callbacks->onScanFoldersChanged)
                callbacks->onScanFoldersChanged();
        };
    }
};

// ---------------------------------------------------------------------------
// NatsuyumeCore public implementation
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
    // dataDir must be set via setDataDir() before calling init()
    return m_impl->init(&callbacks, m_impl->dataDir);
}

void NatsuyumeCore::setDataDir(const std::string &dir)
{
    m_impl->dataDir = dir;
}

void NatsuyumeCore::shutdown()
{
    m_impl->shutdown();
}

// --- Playback ---

void NatsuyumeCore::play()                   { m_impl->playbackManager->play(); }
void NatsuyumeCore::pause()                  { m_impl->playbackManager->pause(); }
void NatsuyumeCore::seekTo(int64_t ms)       { m_impl->playbackManager->seekTo(ms); }
void NatsuyumeCore::playNext()               { m_impl->playbackManager->playNext(); }
void NatsuyumeCore::playPrevious()           { m_impl->playbackManager->playPrevious(); }
void NatsuyumeCore::cycleRepeatMode()        { m_impl->playbackManager->cycleRepeatMode(); }
void NatsuyumeCore::toggleShuffle()          { m_impl->playbackManager->toggleShuffle(); }
void NatsuyumeCore::toggleStopAfterCurrent() { m_impl->playbackManager->toggleStopAfterCurrent(); }
void NatsuyumeCore::setVolume(float v)       { m_impl->playbackManager->setVolume(v); }

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
    return m_impl->userDataManager->isFavorite(
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
    m_impl->queueManager->openFilesInNewQueue(paths, name, shuffle);
}

void NatsuyumeCore::addPathsToNewQueue(const std::vector<std::string> &paths,
                                       const std::string &name)
{
    m_impl->queueManager->addPathsToNewQueue(paths, name);
}

void NatsuyumeCore::addPathsToQueue(int index,
                                    const std::vector<std::string> &paths)
{
    m_impl->queueManager->addPathsToQueue(index, paths);
}

void NatsuyumeCore::closeQueue(int index)  { m_impl->queueManager->closeQueue(index); }
void NatsuyumeCore::renameQueue(int index, const std::string &name)
                                           { m_impl->queueManager->renameQueue(index, name); }
void NatsuyumeCore::moveQueue(int f, int t){ m_impl->queueManager->moveQueue(f, t); }
void NatsuyumeCore::viewQueue(int index)   { m_impl->queueManager->viewQueue(index); }

void NatsuyumeCore::addTrackToQueue(const std::string &path)
{
    m_impl->queueManager->addTrackToQueue(path);
}

void NatsuyumeCore::addAlbumToQueue(const std::string &album)
{
    m_impl->queueManager->addAlbumToQueue(
        album,
        static_cast<Library::TrackSort>(m_impl->libraryManager->trackSort()),
        m_impl->libraryManager->trackSortAscending());
}

void NatsuyumeCore::removeTrackAt(int index)    { m_impl->queueManager->removeTrackAt(index); }
void NatsuyumeCore::moveTrack(int f, int t)     { m_impl->queueManager->moveTrack(f, t); }
void NatsuyumeCore::sortActiveQueue(int s, bool a) { m_impl->queueManager->sortQueue(s, a); }
void NatsuyumeCore::reverseActiveQueue()        { m_impl->queueManager->reverseQueue(); }
void NatsuyumeCore::jumpToTrack(int index)      { m_impl->queueManager->jumpToTrack(index); }
void NatsuyumeCore::jumpToTrackByPath(const std::string &path)
                                                { m_impl->queueManager->jumpToTrackByPath(path); }

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
    return m_impl->queueManager->queueNames();
}

int64_t NatsuyumeCore::queueTotalDuration() const
{
    return m_impl->queueManager->queueTotalDuration();
}

bool NatsuyumeCore::isAlbumActiveQueue(const std::string &album) const
{
    return m_impl->queueManager->isAlbumActiveQueue(
        album,
        static_cast<Library::TrackSort>(m_impl->libraryManager->trackSort()),
        m_impl->libraryManager->trackSortAscending());
}

std::vector<CoreTrack> NatsuyumeCore::trackList() const
{
    Queue *q = m_impl->session->viewedQueue();
    if (!q) return {};
    return toCoreTrackList(q->tracks());
}

CoreTrack NatsuyumeCore::trackInfoByPath(const std::string &path) const
{
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrack(lib->trackByPath(path));
}

// --- Library ---

void NatsuyumeCore::scanFolder(const std::string &path)
                                           { m_impl->libraryManager->scanFolder(path); }
void NatsuyumeCore::cancelScan()           { m_impl->libraryManager->cancelScan(); }
void NatsuyumeCore::addScanFolder(const std::string &path)
                                           { m_impl->libraryManager->addScanFolder(path); }
void NatsuyumeCore::removeScanFolder(const std::string &path)
                                           { m_impl->libraryManager->removeScanFolder(path); }
void NatsuyumeCore::rescanAllFolders()     { m_impl->libraryManager->rescanAllFolders(); }
bool NatsuyumeCore::isScanning()    const  { return m_impl->libraryManager->isScanning(); }
int  NatsuyumeCore::scanProgress()  const  { return m_impl->libraryManager->scanProgress(); }
int  NatsuyumeCore::scanTotal()     const  { return m_impl->libraryManager->scanTotal(); }
std::string NatsuyumeCore::scanningFile() const
                                           { return m_impl->libraryManager->scanningFile(); }

// --- Library queries ---

std::vector<std::string> NatsuyumeCore::allAlbums() const
                                           { return m_impl->libraryManager->allAlbums(); }
std::vector<std::string> NatsuyumeCore::allArtists() const
                                           { return m_impl->libraryManager->allArtists(); }

std::vector<CoreTrack> NatsuyumeCore::tracksForAlbum(const std::string &album) const
{
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrackList(lib->tracksByAlbum(
        album,
        static_cast<Library::TrackSort>(m_impl->libraryManager->trackSort()),
        m_impl->libraryManager->trackSortAscending()));
}

std::vector<CoreTrack> NatsuyumeCore::tracksForArtist(const std::string &artist) const
{
    Library *lib = m_impl->libraryManager->library();
    return toCoreTrackList(lib->tracksByArtist(artist));
}

std::vector<std::string> NatsuyumeCore::albumsForArtist(const std::string &artist) const
                                           { return m_impl->libraryManager->albumsForArtist(artist); }
std::vector<std::string> NatsuyumeCore::allArtistsSorted() const
                                           { return m_impl->libraryManager->allArtistsSorted(); }
std::string NatsuyumeCore::albumCoverPath(const std::string &album) const
                                           { return m_impl->libraryManager->albumCoverPath(album); }

// --- Sort ---

int  NatsuyumeCore::albumSort()             const { return m_impl->libraryManager->albumSort(); }
bool NatsuyumeCore::albumSortAscending()    const { return m_impl->libraryManager->albumSortAscending(); }
int  NatsuyumeCore::trackSort()             const { return m_impl->libraryManager->trackSort(); }
bool NatsuyumeCore::trackSortAscending()    const { return m_impl->libraryManager->trackSortAscending(); }
int  NatsuyumeCore::artistSort()            const { return m_impl->libraryManager->artistSort(); }
bool NatsuyumeCore::artistSortAscending()   const { return m_impl->libraryManager->artistSortAscending(); }
int  NatsuyumeCore::playlistSort()          const { return m_impl->userDataManager->playlistSort(); }
bool NatsuyumeCore::playlistSortAscending() const { return m_impl->userDataManager->playlistSortAscending(); }

void NatsuyumeCore::setAlbumSort(int s)           { m_impl->libraryManager->setAlbumSort(s); }
void NatsuyumeCore::setAlbumSortAscending(bool a) { m_impl->libraryManager->setAlbumSortAscending(a); }
void NatsuyumeCore::setTrackSort(int s)           { m_impl->libraryManager->setTrackSort(s); }
void NatsuyumeCore::setTrackSortAscending(bool a) { m_impl->libraryManager->setTrackSortAscending(a); }
void NatsuyumeCore::setArtistSort(int s)          { m_impl->libraryManager->setArtistSort(s); }
void NatsuyumeCore::setArtistSortAscending(bool a){ m_impl->libraryManager->setArtistSortAscending(a); }
void NatsuyumeCore::setPlaylistSort(int s)        { m_impl->userDataManager->setPlaylistSort(s); }
void NatsuyumeCore::setPlaylistSortAscending(bool a){ m_impl->userDataManager->setPlaylistSortAscending(a); }

// --- Playlists ---

int  NatsuyumeCore::createPlaylist(const std::string &name)
                                           { return m_impl->userDataManager->createPlaylist(name); }
void NatsuyumeCore::deletePlaylist(int id) { m_impl->userDataManager->deletePlaylist(id); }
void NatsuyumeCore::renamePlaylist(int id, const std::string &name)
                                           { m_impl->userDataManager->renamePlaylist(id, name); }
void NatsuyumeCore::addTrackToPlaylist(int id, const std::string &path)
                                           { m_impl->userDataManager->addTrackToPlaylist(id, path); }
void NatsuyumeCore::removeTrackFromPlaylist(int id, const std::string &path)
                                           { m_impl->userDataManager->removeTrackFromPlaylist(id, path); }
void NatsuyumeCore::moveTrackInPlaylist(int id, int f, int t)
                                           { m_impl->userDataManager->moveTrackInPlaylist(id, f, t); }
void NatsuyumeCore::sortPlaylist(int id)   { m_impl->userDataManager->sortPlaylist(id); }

int NatsuyumeCore::saveQueueAsPlaylist(const std::string &name)
{
    Queue *q = m_impl->session->viewedQueue();
    if (!q) return -1;
    std::vector<std::string> paths;
    for (const Track &t : q->tracks())
        paths.push_back(t.path);
    return m_impl->userDataManager->saveQueueAsPlaylist(name, paths);
}

void NatsuyumeCore::openPlaylistInNewQueue(int id, const std::string &name)
{
    m_impl->userDataManager->openPlaylistInNewQueue(id, name);
}

std::vector<CorePlaylistInfo> NatsuyumeCore::allPlaylists() const
{
    std::vector<CorePlaylistInfo> result;
    for (const PlaylistInfo &p : m_impl->userDataManager->rawPlaylists())
        result.push_back({ p.id, p.name });
    return result;
}

std::vector<CoreTrack> NatsuyumeCore::tracksForPlaylist(int id) const
{
    return toCoreTrackList(m_impl->userDataManager->tracksForPlaylist(id));
}

int NatsuyumeCore::allSongsPlaylistId()  { return UserDataManager::kAllSongsPlaylistId; }
int NatsuyumeCore::favoritesPlaylistId() { return UserDataManager::kFavoritesPlaylistId; }

// --- Favorites ---

void NatsuyumeCore::toggleFavorite()
{
    Queue *q = m_impl->session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return;
    m_impl->userDataManager->toggleFavorite(
        q->trackAt(q->currentTrackIndex()).path);
}

// --- Settings ---

std::vector<std::string> NatsuyumeCore::scanFolders() const
{
    return m_impl->libraryManager->scanFolders();
}

int  NatsuyumeCore::playCountThreshold() const
                                           { return m_impl->playbackManager->playCountThreshold(); }
void NatsuyumeCore::setPlayCountThreshold(int p)
                                           { m_impl->playbackManager->setPlayCountThreshold(p); }
void NatsuyumeCore::saveSettings()
{
    m_impl->playbackManager->saveSettings(m_impl->dataDir);
    m_impl->libraryManager->saveSettings();
    m_impl->userDataManager->saveSettings(m_impl->dataDir);
}

// --- Artist / playlist images ---

void NatsuyumeCore::setArtistImage(const std::string &artist,
                                   const std::string &imagePath)
{
    m_impl->userDataManager->setArtistImage(artist, imagePath);
}

std::string NatsuyumeCore::artistImage(const std::string &artist) const
{
    return m_impl->userDataManager->artistImage(artist);
}

void NatsuyumeCore::setPlaylistImage(int playlistId,
                                     const std::string &imagePath)
{
    m_impl->userDataManager->setPlaylistImage(playlistId, imagePath);
}

// --- Clear operations ---

void NatsuyumeCore::clearUserData() { m_impl->userDataManager->clearUserData(); }
void NatsuyumeCore::clearLibrary()  { m_impl->userDataManager->clearLibrary(); }

// --- A-B repeat ---

bool    NatsuyumeCore::abRepeatActive() const { return m_impl->playbackManager->abRepeatActive(); }
int64_t NatsuyumeCore::pointA()         const { return m_impl->playbackManager->pointA(); }
int64_t NatsuyumeCore::pointB()         const { return m_impl->playbackManager->pointB(); }
void    NatsuyumeCore::setPointA()            { m_impl->playbackManager->setPointA(); }
void    NatsuyumeCore::setPointB()            { m_impl->playbackManager->setPointB(); }
void    NatsuyumeCore::clearAbRepeat()        { m_impl->playbackManager->clearAbRepeat(); }

} // namespace Natsuyume