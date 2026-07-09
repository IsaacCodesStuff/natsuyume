#include "playercontroller.h"
#include <QTimer>

PlayerController::PlayerController(QObject *parent)
    : QObject{parent}
{
    m_session         = new QueueSession(this);
    m_queueManager    = new QueueManager(m_session, this);
    m_libraryManager  = new LibraryManager(this);
    m_playbackManager = new PlaybackManager(m_session, this);
    m_playlistManager = new PlaylistManager(m_session, this);

    // Wire library pointer into managers that need it
    m_queueManager->setLibrary(m_libraryManager->library());
    m_playbackManager->setLibrary(m_libraryManager->library());
    m_playlistManager->setLibrary(m_libraryManager->library());

    if (m_libraryManager->open()) {
        loadSettings();
        m_playlistManager->initialize(); // ← load favorites now that db is open
        loadQueues();
        QTimer::singleShot(2000, this, [this]() {
            m_libraryManager->rescanAllFolders();
        });
    } else {
        qWarning() << "PlayerController: failed to open library";
    }

    wireSignals();
}

// --- Setup ---

void PlayerController::setCoverImageProvider(CoverImageProvider *provider)
{
    m_playbackManager->setCoverImageProvider(provider);
}

void PlayerController::setAlbumCoverProvider(AlbumCoverProvider *provider)
{
    m_libraryManager->setAlbumCoverProvider(provider);
}

// --- Settings ---

void PlayerController::loadSettings()
{
    m_libraryManager->loadSettings();
    m_playbackManager->loadSettings();
    m_playlistManager->loadSettings();
}

void PlayerController::saveSettings()
{
    m_libraryManager->saveSettings();
    m_playbackManager->saveSettings();
    m_playlistManager->saveSettings();
}

// --- Signal wiring ---

void PlayerController::wireSignals()
{
    // --- QueueManager → PlaybackManager (cross-manager, via PlayerController) ---
    connect(m_queueManager, &QueueManager::playbackInitNewRequested,
            this, [this](int index) {
                m_playbackManager->initPlayback(index);
                emit positionChanged();
                emit durationChanged();
            });

    connect(m_queueManager, &QueueManager::playbackInitRequested,
            this, [this](int index) {
                m_playbackManager->initPlayback(index);
                // Do NOT call restorePlaybackState here — jumpToTrack handles
                // loading the specific track itself via loadTrackAt.
                // restorePlaybackState is only for app startup queue restoration.
            });

    connect(m_queueManager, &QueueManager::playbackRestoreRequested,
            this, [this](int index) {
                m_playbackManager->initPlayback(index);
                m_playbackManager->restorePlaybackState(index);
                // resetPlayCountState() removed — Queue::restoreCompleted handles it
            });

    connect(m_queueManager, &QueueManager::playbackDestroyRequested,
            this, [this](int index) {
                m_playbackManager->destroyPlayback(index);
                // Reset position and duration immediately so QML doesn't show stale values
                emit positionChanged();
                emit durationChanged();
            });

    // --- PlaylistManager → QueueManager ---
    connect(m_playlistManager, &PlaylistManager::openInNewQueueRequested,
            this, [this](const QStringList &paths, const QString &name) {
                m_queueManager->openFilesInNewQueue(paths, name);
            });

    // --- QueueSession → PlayerController signals ---
    connect(m_session, &QueueSession::queuesChanged, this, [this]() {
        emit queuesChanged();
        emit trackChanged();
    });

    connect(m_session, &QueueSession::viewedQueueChanged, this, [this]() {
        emit trackChanged();
    });

    connect(m_session, &QueueSession::playingQueueChanged, this, [this]() {
        emit queuesChanged();
        emit isPlayingChanged();
        emit positionChanged();
        emit durationChanged();
    });

    // --- PlaybackManager → PlayerController signals ---
    connect(m_playbackManager, &PlaybackManager::isPlayingChanged,
            this, &PlayerController::isPlayingChanged);
    connect(m_playbackManager, &PlaybackManager::positionChanged,
            this, &PlayerController::positionChanged);
    connect(m_playbackManager, &PlaybackManager::durationChanged,
            this, &PlayerController::durationChanged);
    connect(m_playbackManager, &PlaybackManager::volumeChanged,
            this, &PlayerController::volumeChanged);
    connect(m_playbackManager, &PlaybackManager::metadataChanged,
            this, &PlayerController::metadataChanged);
    connect(m_playbackManager, &PlaybackManager::coverArtChanged,
            this, &PlayerController::coverArtChanged);
    connect(m_playbackManager, &PlaybackManager::repeatModeChanged,
            this, &PlayerController::repeatModeChanged);
    connect(m_playbackManager, &PlaybackManager::shuffleChanged,
            this, &PlayerController::shuffleChanged);
    connect(m_playbackManager, &PlaybackManager::stopAfterCurrentChanged,
            this, &PlayerController::stopAfterCurrentChanged);
    connect(m_playbackManager, &PlaybackManager::playingTrackChanged,
            this, [this]() {
                emit playingTrackChanged();
                // Only emit trackChanged if viewed and playing queues are the same —
                // otherwise the viewed queue counter updates incorrectly from playing queue state
                if (m_session->viewedQueueIndex() == m_session->playingQueueIndex())
                    emit trackChanged();
            });
    connect(m_playbackManager, &PlaybackManager::isFavoriteChanged,
            this, &PlayerController::isFavoriteChanged);

    // --- LibraryManager → PlayerController signals ---
    connect(m_libraryManager, &LibraryManager::libraryChanged,
            this, &PlayerController::libraryChanged);
    connect(m_libraryManager, &LibraryManager::scanningChanged,
            this, &PlayerController::scanningChanged);
    connect(m_libraryManager, &LibraryManager::scanProgressChanged,
            this, &PlayerController::scanProgressChanged);
    connect(m_libraryManager, &LibraryManager::albumSortChanged,
            this, &PlayerController::albumSortChanged);
    connect(m_libraryManager, &LibraryManager::trackSortChanged,
            this, &PlayerController::trackSortChanged);
    connect(m_libraryManager, &LibraryManager::artistSortChanged,
            this, &PlayerController::artistSortChanged);
    connect(m_libraryManager, &LibraryManager::scanFoldersChanged,
            this, &PlayerController::scanFoldersChanged);

    // --- PlaylistManager → PlayerController signals ---
    connect(m_playlistManager, &PlaylistManager::playlistsChanged,
            this, &PlayerController::playlistsChanged);
    connect(m_playlistManager, &PlaylistManager::playlistSortChanged,
            this, &PlayerController::playlistSortChanged);
    connect(m_playlistManager, &PlaylistManager::isFavoriteChanged,
            this, &PlayerController::isFavoriteChanged);
    connect(m_playlistManager, &PlaylistManager::addToPlaylistRequested,
            this, &PlayerController::addToPlaylistRequested);
    connect(m_playlistManager, &PlaylistManager::addAlbumToPlaylistRequested,
            this, &PlayerController::addAlbumToPlaylistRequested);
    connect(m_playbackManager, &PlaybackManager::abRepeatChanged,
            this, &PlayerController::abRepeatChanged);
}

// --- Playback getters ---

bool   PlayerController::isPlaying() const { return m_playbackManager->isPlaying(); }
qint64 PlayerController::position()  const { return m_playbackManager->position(); }
qint64 PlayerController::duration()  const { return m_playbackManager->duration(); }
float  PlayerController::volume()    const { return m_playbackManager->volume(); }

// --- Metadata getters ---

QString PlayerController::trackTitle()  const { return m_playbackManager->trackTitle(); }
QString PlayerController::trackArtist() const { return m_playbackManager->trackArtist(); }
QString PlayerController::trackAlbum()  const { return m_playbackManager->trackAlbum(); }
QString PlayerController::trackPath()   const { return m_playbackManager->trackPath(); }
bool    PlayerController::hasCoverArt() const { return m_playbackManager->hasCoverArt(); }

// --- Lyrics getters ---

QString      PlayerController::rawLyrics()       const { return m_playbackManager->rawLyrics(); }
QVariantList PlayerController::lyricLines()      const { return m_playbackManager->lyricLines(); }
bool         PlayerController::lyricsAreSynced() const { return m_playbackManager->lyricsAreSynced(); }

// --- Playing-queue track navigation ---

int  PlayerController::playingTrackIndex() const { return m_playbackManager->playingTrackIndex(); }
int  PlayerController::playingTrackCount() const { return m_playbackManager->playingTrackCount(); }
bool PlayerController::hasPrevious()       const { return m_playbackManager->hasPrevious(); }
bool PlayerController::hasNext()           const { return m_playbackManager->hasNext(); }

// --- Viewed-queue track navigation ---

int PlayerController::viewedTrackIndex() const { return m_session->viewedQueue() ? m_session->viewedQueue()->currentTrackIndex() : -1; }
int PlayerController::viewedTrackCount() const { return m_session->viewedQueue() ? m_session->viewedQueue()->trackCount() : 0; }

// --- Multi-queue getters ---

int         PlayerController::queueCount()        const { return m_session->queueCount(); }
int         PlayerController::activeQueueIndex()  const { return m_session->viewedQueueIndex(); }
int         PlayerController::playingQueueIndex() const { return m_session->playingQueueIndex(); }
QStringList PlayerController::queueNames()        const { return m_queueManager->queueNames(); }

// --- Repeat / shuffle ---

int  PlayerController::repeatMode() const { return m_playbackManager->repeatMode(); }
bool PlayerController::isShuffled() const { return m_playbackManager->isShuffled(); }

// --- Favorites ---

bool PlayerController::isFavorite() const
{
    return m_playlistManager->isFavorite(m_playbackManager->trackPath());
}

// --- Track list ---

QVariantList PlayerController::trackList() const { return m_queueManager->trackList(); }

// --- Library getters ---

QStringList PlayerController::allAlbums()    const { return m_libraryManager->allAlbums(); }
QStringList PlayerController::allArtists()   const { return m_libraryManager->allArtists(); }
bool        PlayerController::isScanning()   const { return m_libraryManager->isScanning(); }
int         PlayerController::scanProgress() const { return m_libraryManager->scanProgress(); }
int         PlayerController::scanTotal()    const { return m_libraryManager->scanTotal(); }
QString     PlayerController::scanningFile() const { return m_libraryManager->scanningFile(); }

// --- Sort getters ---

int  PlayerController::albumSort()          const { return m_libraryManager->albumSort(); }
bool PlayerController::albumSortAscending() const { return m_libraryManager->albumSortAscending(); }
int  PlayerController::trackSort()          const { return m_libraryManager->trackSort(); }
bool PlayerController::trackSortAscending() const { return m_libraryManager->trackSortAscending(); }
int  PlayerController::playlistSort()          const { return m_playlistManager->playlistSort(); }
bool PlayerController::playlistSortAscending() const { return m_playlistManager->playlistSortAscending(); }

// --- Settings getters ---

QStringList PlayerController::scanFolders()        const { return m_libraryManager->scanFolders(); }
int         PlayerController::playCountThreshold() const { return m_playbackManager->playCountThreshold(); }
bool        PlayerController::stopAfterCurrent()   const { return m_playbackManager->stopAfterCurrent(); }
qint64      PlayerController::queueTotalDuration() const { return m_queueManager->queueTotalDuration(); }

// --- Playlists getter ---

QVariantList PlayerController::allPlaylists() const { return m_playlistManager->allPlaylists(); }

// --- Invokables: Playback ---

void PlayerController::play()                      { m_playbackManager->play(); }
void PlayerController::pause()                     { m_playbackManager->pause(); }
void PlayerController::seekTo(qint64 positionMs)   { m_playbackManager->seekTo(positionMs); }
void PlayerController::playNext()                  { m_playbackManager->playNext(); }
void PlayerController::playPrevious()              { m_playbackManager->playPrevious(); }
void PlayerController::cycleRepeatMode()           { m_playbackManager->cycleRepeatMode(); }
void PlayerController::toggleShuffle()             { m_playbackManager->toggleShuffle(); }
void PlayerController::toggleStopAfterCurrent()    { m_playbackManager->toggleStopAfterCurrent(); }
void PlayerController::setVolume(float volume)     { m_playbackManager->setVolume(volume); }

// --- Invokables: Queue ---

void PlayerController::openFilesInNewQueue(const QStringList &paths,
                                           const QString &name, bool shuffle)
{
    m_queueManager->openFilesInNewQueue(paths, name, shuffle);
}

void PlayerController::addPathsToNewQueue(const QStringList &paths, const QString &name)
{
    m_queueManager->addPathsToNewQueue(paths, name);
}

void PlayerController::addPathsToQueue(int queueIndex, const QStringList &paths)
{
    m_queueManager->addPathsToQueue(queueIndex, paths);
}

void PlayerController::closeQueue(int index)              { m_queueManager->closeQueue(index); }
void PlayerController::renameQueue(int index, const QString &name) { m_queueManager->renameQueue(index, name); }
void PlayerController::moveQueue(int from, int to)        { m_queueManager->moveQueue(from, to); }
void PlayerController::viewQueue(int index)               { m_queueManager->viewQueue(index); }
void PlayerController::switchToQueue(int index)           { m_queueManager->viewQueue(index); } // deprecated alias
void PlayerController::addTrackToActiveQueue(const QString &path) { m_queueManager->addTrackToQueue(path); }
void PlayerController::addTrackToQueue(const QString &path)       { m_queueManager->addTrackToQueue(path); }

void PlayerController::addAlbumToQueue(const QString &album)
{
    m_queueManager->addAlbumToQueue(
        album,
        static_cast<Library::TrackSort>(m_libraryManager->trackSort()),
        m_libraryManager->trackSortAscending()
        );
}

void PlayerController::removeTrackAt(int index)           { m_queueManager->removeTrackAt(index); }
void PlayerController::moveTrack(int from, int to)        { m_queueManager->moveTrack(from, to); }
void PlayerController::sortActiveQueue(int sort, bool ascending) { m_queueManager->sortQueue(sort, ascending); }
void PlayerController::reverseActiveQueue()               { m_queueManager->reverseQueue(); }
void PlayerController::jumpToTrack(int index)             { m_queueManager->jumpToTrack(index); }
void PlayerController::jumpToTrackByPath(const QString &path) { m_queueManager->jumpToTrackByPath(path); }

void PlayerController::saveQueues()
{
    m_queueManager->saveQueues(m_session->viewedQueueIndex());
}

void PlayerController::loadQueues()
{
    m_queueManager->loadQueues(m_playbackManager->volume());
}

bool PlayerController::isAlbumActiveQueue(const QString &album) const
{
    return m_queueManager->isAlbumActiveQueue(
        album,
        static_cast<Library::TrackSort>(m_libraryManager->trackSort()),
        m_libraryManager->trackSortAscending()
        );
}

QVariantMap PlayerController::trackInfoByPath(const QString &path) const
{
    return m_queueManager->trackInfoByPath(path);
}

// --- Invokables: Library ---

void         PlayerController::scanFolder(const QString &path)    { m_libraryManager->scanFolder(path); }
void         PlayerController::cancelScan()                       { m_libraryManager->cancelScan(); }
void         PlayerController::addScanFolder(const QString &path) { m_libraryManager->addScanFolder(path); }
void         PlayerController::removeScanFolder(const QString &path) { m_libraryManager->removeScanFolder(path); }
void         PlayerController::rescanAllFolders()                 { m_libraryManager->rescanAllFolders(); }
QVariantList PlayerController::tracksForAlbum(const QString &album)   const { return m_libraryManager->tracksForAlbum(album); }
QVariantList PlayerController::tracksForArtist(const QString &artist) const { return m_libraryManager->tracksForArtist(artist); }
QStringList  PlayerController::albumsForArtist(const QString &artist) const { return m_libraryManager->albumsForArtist(artist); }
QStringList  PlayerController::allArtistsSorted()                     const { return m_libraryManager->allArtistsSorted(); }
QString      PlayerController::albumCoverPath(const QString &album)   const { return m_libraryManager->albumCoverPath(album); }
void         PlayerController::setAlbumSort(int sort)                 { m_libraryManager->setAlbumSort(sort); }
void         PlayerController::setAlbumSortAscending(bool ascending)  { m_libraryManager->setAlbumSortAscending(ascending); }
void         PlayerController::setTrackSort(int sort)                 { m_libraryManager->setTrackSort(sort); }
void         PlayerController::setTrackSortAscending(bool ascending)  { m_libraryManager->setTrackSortAscending(ascending); }
void         PlayerController::setArtistSort(int sort)                { m_libraryManager->setArtistSort(sort); }
void         PlayerController::setArtistSortAscending(bool ascending) { m_libraryManager->setArtistSortAscending(ascending); }
int          PlayerController::artistSort()          const            { return m_libraryManager->artistSort(); }
bool         PlayerController::artistSortAscending() const            { return m_libraryManager->artistSortAscending(); }

// --- Invokables: Playlists ---

int  PlayerController::createPlaylist(const QString &name)  { return m_playlistManager->createPlaylist(name); }
void PlayerController::deletePlaylist(int id)               { m_playlistManager->deletePlaylist(id); }
void PlayerController::renamePlaylist(int id, const QString &name) { m_playlistManager->renamePlaylist(id, name); }
void PlayerController::addTrackToPlaylist(int id, const QString &path)    { m_playlistManager->addTrackToPlaylist(id, path); }
void PlayerController::removeTrackFromPlaylist(int id, const QString &path) { m_playlistManager->removeTrackFromPlaylist(id, path); }
void PlayerController::moveTrackInPlaylist(int id, int from, int to)      { m_playlistManager->moveTrackInPlaylist(id, from, to); }
void PlayerController::sortPlaylist(int id)                 { m_playlistManager->sortPlaylist(id); }
int  PlayerController::saveQueueAsPlaylist(const QString &name) { return m_playlistManager->saveQueueAsPlaylist(name); }
QVariantList PlayerController::tracksForPlaylist(int id) const  { return m_playlistManager->tracksForPlaylist(id); }
void PlayerController::openPlaylistInNewQueue(int id, const QString &name) { m_playlistManager->openPlaylistInNewQueue(id, name); }
void PlayerController::requestAddToPlaylist(const QString &path)      { m_playlistManager->requestAddToPlaylist(path); }
void PlayerController::requestAddAlbumToPlaylist(const QString &name) { m_playlistManager->requestAddAlbumToPlaylist(name); }
void PlayerController::setPlaylistSort(int sort)               { m_playlistManager->setPlaylistSort(sort); }
void PlayerController::setPlaylistSortAscending(bool ascending){ m_playlistManager->setPlaylistSortAscending(ascending); }

void PlayerController::toggleFavorite()
{
    m_playlistManager->toggleFavorite(m_playbackManager->trackPath());
    emit isFavoriteChanged();
}

void PlayerController::setPlayCountThreshold(int percent)
{
    m_playbackManager->setPlayCountThreshold(percent);
    emit playCountThresholdChanged();
}

// --- Invokables: Queue requests ---

void PlayerController::requestAddToQueue(const QString &path)
{
    emit addToQueueRequested(QStringList{path});
}

void PlayerController::requestAddAlbumToQueue(const QString &album)
{
    QVariantList tracks = m_libraryManager->tracksForAlbum(album);
    QStringList paths;
    for (const QVariant &v : std::as_const(tracks))
        paths << v.toMap()["path"].toString();
    emit addToQueueRequested(paths);
}

bool   PlayerController::abRepeatActive() const { return m_playbackManager->abRepeatActive(); }
qint64 PlayerController::pointA()         const { return m_playbackManager->pointA(); }
qint64 PlayerController::pointB()         const { return m_playbackManager->pointB(); }
void   PlayerController::setPointA()            { m_playbackManager->setPointA(); }
void   PlayerController::setPointB()            { m_playbackManager->setPointB(); }
void   PlayerController::clearAbRepeat()        { m_playbackManager->clearAbRepeat(); }
