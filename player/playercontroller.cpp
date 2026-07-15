#include "playercontroller.h"
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QImage>

using namespace Natsuyume;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static QStringList toQStringList(const std::vector<std::string> &v)
{
    QStringList r;
    r.reserve(static_cast<int>(v.size()));
    for (const auto &s : v) r.append(QString::fromStdString(s));
    return r;
}

static std::vector<std::string> toStdVec(const QStringList &list)
{
    std::vector<std::string> r;
    r.reserve(list.size());
    for (const QString &s : list) r.push_back(s.toStdString());
    return r;
}

static QVariantMap coreTrackToVariantMap(const CoreTrack &t)
{
    QVariantMap m;
    m["path"]        = QString::fromStdString(t.path);
    m["title"]       = QString::fromStdString(t.title);
    m["artist"]      = QString::fromStdString(t.artist);
    m["album"]       = QString::fromStdString(t.album);
    m["albumArtist"] = QString::fromStdString(t.albumArtist);
    m["composer"]    = QString::fromStdString(t.composer);
    m["genre"]       = QString::fromStdString(t.genre);
    m["trackNumber"] = t.trackNumber;
    m["discNumber"]  = t.discNumber;
    m["year"]        = t.year;
    m["duration"]    = static_cast<qlonglong>(t.duration);
    m["playCount"]   = t.playCount;
    m["isFavorite"]  = t.isFavorite;
    return m;
}

// ---------------------------------------------------------------------------
// Constructor
// ---------------------------------------------------------------------------

PlayerController::PlayerController(NatsuyumeCore *core, QObject *parent)
    : QObject(parent)
    , m_core(core)
{
    wireCallbacks();
}

void PlayerController::wireCallbacks()
{
    auto &cb = m_core->callbacks;

    cb.onPlaybackStateChanged = [this](bool) {
        emit isPlayingChanged();
    };
    cb.onPositionChanged = [this](int64_t) {
        emit positionChanged();
    };
    cb.onDurationChanged = [this](int64_t) {
        emit durationChanged();
    };
    cb.onVolumeChanged = [this](float) {
        emit volumeChanged();
    };
    cb.onTrackChanged = [this](const CoreTrack &track) {
        m_currentTrack = track;
        emit metadataChanged();
        emit playingTrackChanged();
        emit trackChanged();
        emit isFavoriteChanged();

        // Push cover art to image provider
        if (m_coverImageProvider) {
            if (!track.coverArtData.empty()) {
                QImage img;
                img.loadFromData(
                    reinterpret_cast<const uchar *>(track.coverArtData.data()),
                    static_cast<int>(track.coverArtData.size()));
                m_coverImageProvider->updateCover(img);
            } else {
                m_coverImageProvider->updateCover(QImage{});
            }
            emit coverArtChanged();
        }
    };
    cb.onMetadataChanged = [this]() {
        emit metadataChanged();
    };
    cb.onQueueChanged = [this]() {
        emit trackChanged();
    };
    cb.onQueuesChanged = [this]() {
        emit queuesChanged();
    };
    cb.onRepeatModeChanged = [this]() {
        emit repeatModeChanged();
    };
    cb.onShuffleChanged = [this]() {
        emit shuffleChanged();
    };
    cb.onStopAfterCurrentChanged = [this]() {
        emit stopAfterCurrentChanged();
    };
    cb.onLibraryChanged = [this]() {
        emit libraryChanged();

        // Refresh album covers when library updates
        if (m_albumCoverProvider) {
            const auto albums = m_core->allAlbums();
            for (const auto &album : albums) {
                QString qAlbum = QString::fromStdString(album);
                if (m_albumCoverProvider->hasAlbum(qAlbum)) continue;
                std::string coverPath = m_core->albumCoverPath(album);
                if (!coverPath.empty())
                    m_albumCoverProvider->registerAlbum(
                        qAlbum, QString::fromStdString(coverPath));
            }
        }
    };
    cb.onScanningChanged = [this](bool) {
        emit scanningChanged();
    };
    cb.onScanProgressChanged = [this](int, int, const std::string &) {
        emit scanProgressChanged();
    };
    cb.onPlaylistsChanged = [this]() {
        emit playlistsChanged();
    };
    cb.onFavoriteChanged = [this](bool) {
        emit isFavoriteChanged();
    };
    cb.onAbRepeatChanged = [this]() {
        emit abRepeatChanged();
    };
    cb.onAlbumSortChanged = [this]() {
        emit albumSortChanged();
        emit libraryChanged();
    };
    cb.onTrackSortChanged = [this]() {
        emit trackSortChanged();
    };
    cb.onPlaylistSortChanged = [this]() {
        emit playlistSortChanged();
    };
    cb.onScanFoldersChanged = [this]() {
        emit scanFoldersChanged();
    };
    cb.onPlayCountThresholdChanged = [this]() {
        emit playCountThresholdChanged();
    };
}

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

void PlayerController::setCoverImageProvider(CoverImageProvider *provider)
{
    m_coverImageProvider = provider;
}

void PlayerController::setAlbumCoverProvider(AlbumCoverProvider *provider)
{
    m_albumCoverProvider = provider;

    // Register any albums already in the library
    for (const auto &album : m_core->allAlbums()) {
        QString qAlbum = QString::fromStdString(album);
        if (m_albumCoverProvider->hasAlbum(qAlbum)) continue;
        std::string coverPath = m_core->albumCoverPath(album);
        if (!coverPath.empty())
            m_albumCoverProvider->registerAlbum(
                qAlbum, QString::fromStdString(coverPath));
    }
}

// ---------------------------------------------------------------------------
// Playback
// ---------------------------------------------------------------------------

bool   PlayerController::isPlaying() const { return m_core->isPlaying(); }
qint64 PlayerController::position()  const { return m_core->position(); }
qint64 PlayerController::duration()  const { return m_core->duration(); }
float  PlayerController::volume()    const { return m_core->volume(); }

void PlayerController::play()                   { m_core->play(); }
void PlayerController::pause()                  { m_core->pause(); }
void PlayerController::seekTo(qint64 ms)        { m_core->seekTo(ms); }
void PlayerController::playNext()               { m_core->playNext(); }
void PlayerController::playPrevious()           { m_core->playPrevious(); }
void PlayerController::cycleRepeatMode()        { m_core->cycleRepeatMode(); }
void PlayerController::toggleShuffle()          { m_core->toggleShuffle(); }
void PlayerController::toggleStopAfterCurrent() { m_core->toggleStopAfterCurrent(); }
void PlayerController::setVolume(float v)       { m_core->setVolume(v); }

// ---------------------------------------------------------------------------
// Metadata — served from m_currentTrack cache
// ---------------------------------------------------------------------------

QString PlayerController::trackTitle()  const { return QString::fromStdString(m_currentTrack.title); }
QString PlayerController::trackArtist() const { return QString::fromStdString(m_currentTrack.artist); }
QString PlayerController::trackAlbum()  const { return QString::fromStdString(m_currentTrack.album); }
QString PlayerController::trackPath()   const { return QString::fromStdString(m_currentTrack.path); }
bool    PlayerController::hasCoverArt() const { return m_currentTrack.hasCoverArt(); }

// Lyrics still live in PlaybackManager for now — accessed via core's Impl
// These delegate through the core's internal playback manager
QString      PlayerController::rawLyrics()      const { return QString::fromStdString(m_currentTrack.lyrics); }
QVariantList PlayerController::lyricLines()     const { return {}; } // TODO: expose via CoreTrack in 0.6.1
bool         PlayerController::lyricsAreSynced() const { return false; } // TODO: expose via CoreTrack in 0.6.1

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------

int  PlayerController::playingTrackIndex() const { return m_core->playingTrackIndex(); }
int  PlayerController::playingTrackCount() const { return m_core->playingTrackCount(); }
bool PlayerController::hasPrevious()       const { return m_core->hasPrevious(); }
bool PlayerController::hasNext()           const { return m_core->hasNext(); }
int  PlayerController::viewedTrackIndex()  const { return m_core->viewedTrackIndex(); }
int  PlayerController::viewedTrackCount()  const { return m_core->viewedTrackCount(); }

// ---------------------------------------------------------------------------
// Multi-queue
// ---------------------------------------------------------------------------

int         PlayerController::queueCount()        const { return m_core->queueCount(); }
int         PlayerController::activeQueueIndex()   const { return m_core->activeQueueIndex(); }
int         PlayerController::playingQueueIndex()  const { return m_core->playingQueueIndex(); }
QStringList PlayerController::queueNames()         const { return toQStringList(m_core->queueNames()); }

// ---------------------------------------------------------------------------
// Repeat / shuffle
// ---------------------------------------------------------------------------

int  PlayerController::repeatMode() const { return m_core->repeatMode(); }
bool PlayerController::isShuffled() const { return m_core->isShuffled(); }

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

bool PlayerController::isFavorite() const { return m_core->isFavorite(); }
void PlayerController::toggleFavorite()   { m_core->toggleFavorite(); }

// ---------------------------------------------------------------------------
// Track list
// ---------------------------------------------------------------------------

QVariantList PlayerController::trackList() const
{
    QVariantList result;
    for (const CoreTrack &t : m_core->trackList())
        result.append(coreTrackToVariantMap(t));
    return result;
}

// ---------------------------------------------------------------------------
// Library
// ---------------------------------------------------------------------------

QStringList PlayerController::allAlbums()    const { return toQStringList(m_core->allAlbums()); }
QStringList PlayerController::allArtists()   const { return toQStringList(m_core->allArtists()); }
bool        PlayerController::isScanning()   const { return m_core->isScanning(); }
int         PlayerController::scanProgress() const { return m_core->scanProgress(); }
int         PlayerController::scanTotal()    const { return m_core->scanTotal(); }
QString     PlayerController::scanningFile() const { return QString::fromStdString(m_core->scanningFile()); }

void PlayerController::scanFolder(const QString &path)     { m_core->scanFolder(path.toStdString()); }
void PlayerController::cancelScan()                        { m_core->cancelScan(); }
void PlayerController::addScanFolder(const QString &path)  { m_core->addScanFolder(path.toStdString()); }
void PlayerController::removeScanFolder(const QString &path) { m_core->removeScanFolder(path.toStdString()); }
void PlayerController::rescanAllFolders()                  { m_core->rescanAllFolders(); }

QVariantList PlayerController::tracksForAlbum(const QString &album) const
{
    QVariantList result;
    for (const CoreTrack &t : m_core->tracksForAlbum(album.toStdString()))
        result.append(coreTrackToVariantMap(t));
    return result;
}

QVariantList PlayerController::tracksForArtist(const QString &artist) const
{
    QVariantList result;
    for (const CoreTrack &t : m_core->tracksForArtist(artist.toStdString()))
        result.append(coreTrackToVariantMap(t));
    return result;
}

QStringList PlayerController::albumsForArtist(const QString &artist) const
{
    return toQStringList(m_core->albumsForArtist(artist.toStdString()));
}

QStringList PlayerController::allArtistsSorted() const
{
    return toQStringList(m_core->allArtistsSorted());
}

QString PlayerController::albumCoverPath(const QString &album) const
{
    return QString::fromStdString(m_core->albumCoverPath(album.toStdString()));
}

// ---------------------------------------------------------------------------
// Sort
// ---------------------------------------------------------------------------

int  PlayerController::albumSort()             const { return m_core->albumSort(); }
bool PlayerController::albumSortAscending()    const { return m_core->albumSortAscending(); }
int  PlayerController::trackSort()             const { return m_core->trackSort(); }
bool PlayerController::trackSortAscending()    const { return m_core->trackSortAscending(); }
int  PlayerController::artistSort()            const { return m_core->artistSort(); }
bool PlayerController::artistSortAscending()   const { return m_core->artistSortAscending(); }
int  PlayerController::playlistSort()          const { return m_core->playlistSort(); }
bool PlayerController::playlistSortAscending() const { return m_core->playlistSortAscending(); }

void PlayerController::setAlbumSort(int s)              { m_core->setAlbumSort(s); }
void PlayerController::setAlbumSortAscending(bool a)    { m_core->setAlbumSortAscending(a); }
void PlayerController::setTrackSort(int s)              { m_core->setTrackSort(s); }
void PlayerController::setTrackSortAscending(bool a)    { m_core->setTrackSortAscending(a); }
void PlayerController::setArtistSort(int s)             { m_core->setArtistSort(s); }
void PlayerController::setArtistSortAscending(bool a)   { m_core->setArtistSortAscending(a); }
void PlayerController::setPlaylistSort(int s)           { m_core->setPlaylistSort(s); }
void PlayerController::setPlaylistSortAscending(bool a) { m_core->setPlaylistSortAscending(a); }

// ---------------------------------------------------------------------------
// Queue operations
// ---------------------------------------------------------------------------

void PlayerController::openFilesInNewQueue(const QStringList &paths,
                                           const QString &name, bool shuffle)
{
    m_core->openFilesInNewQueue(toStdVec(paths), name.toStdString(), shuffle);
}
void PlayerController::addPathsToNewQueue(const QStringList &paths, const QString &name)
{
    m_core->addPathsToNewQueue(toStdVec(paths), name.toStdString());
}
void PlayerController::addPathsToQueue(int index, const QStringList &paths)
{
    m_core->addPathsToQueue(index, toStdVec(paths));
}
void PlayerController::closeQueue(int i)                { m_core->closeQueue(i); }
void PlayerController::renameQueue(int i, const QString &n) { m_core->renameQueue(i, n.toStdString()); }
void PlayerController::moveQueue(int f, int t)          { m_core->moveQueue(f, t); }
void PlayerController::viewQueue(int i)                 { m_core->viewQueue(i); }
void PlayerController::addTrackToQueue(const QString &p) { m_core->addTrackToQueue(p.toStdString()); }
void PlayerController::addAlbumToQueue(const QString &a) { m_core->addAlbumToQueue(a.toStdString()); }
void PlayerController::removeTrackAt(int i)             { m_core->removeTrackAt(i); }
void PlayerController::moveTrack(int f, int t)          { m_core->moveTrack(f, t); }
void PlayerController::sortActiveQueue(int s, bool a)   { m_core->sortActiveQueue(s, a); }
void PlayerController::reverseActiveQueue()             { m_core->reverseActiveQueue(); }
void PlayerController::jumpToTrack(int i)               { m_core->jumpToTrack(i); }
void PlayerController::jumpToTrackByPath(const QString &p) { m_core->jumpToTrackByPath(p.toStdString()); }
void PlayerController::saveQueues()                     { m_core->saveQueues(); }
void PlayerController::loadQueues()                     { m_core->loadQueues(); }

bool PlayerController::isAlbumActiveQueue(const QString &album) const
{
    return m_core->isAlbumActiveQueue(album.toStdString());
}

QVariantMap PlayerController::trackInfoByPath(const QString &path) const
{
    return coreTrackToVariantMap(m_core->trackInfoByPath(path.toStdString()));
}

qint64 PlayerController::queueTotalDuration() const { return m_core->queueTotalDuration(); }

// ---------------------------------------------------------------------------
// Playlists
// ---------------------------------------------------------------------------

QVariantList PlayerController::allPlaylists() const
{
    QVariantList result;
    for (const CorePlaylistInfo &p : m_core->allPlaylists()) {
        QVariantMap m;
        m["id"]   = p.id;
        m["name"] = QString::fromStdString(p.name);
        result.append(m);
    }
    return result;
}

int  PlayerController::createPlaylist(const QString &name)
{
    return m_core->createPlaylist(name.toStdString());
}
void PlayerController::deletePlaylist(int id)           { m_core->deletePlaylist(id); }
void PlayerController::renamePlaylist(int id, const QString &name)
{
    m_core->renamePlaylist(id, name.toStdString());
}
void PlayerController::addTrackToPlaylist(int id, const QString &path)
{
    m_core->addTrackToPlaylist(id, path.toStdString());
}
void PlayerController::removeTrackFromPlaylist(int id, const QString &path)
{
    m_core->removeTrackFromPlaylist(id, path.toStdString());
}
void PlayerController::moveTrackInPlaylist(int id, int f, int t)
{
    m_core->moveTrackInPlaylist(id, f, t);
}
void PlayerController::sortPlaylist(int id)             { m_core->sortPlaylist(id); }
int  PlayerController::saveQueueAsPlaylist(const QString &name)
{
    return m_core->saveQueueAsPlaylist(name.toStdString());
}
QVariantList PlayerController::tracksForPlaylist(int id) const
{
    QVariantList result;
    for (const CoreTrack &t : m_core->tracksForPlaylist(id))
        result.append(coreTrackToVariantMap(t));
    return result;
}
void PlayerController::openPlaylistInNewQueue(int id, const QString &name)
{
    m_core->openPlaylistInNewQueue(id, name.toStdString());
}
void PlayerController::requestAddToPlaylist(const QString &path)
{
    emit addToPlaylistRequested(path);
}
void PlayerController::requestAddAlbumToPlaylist(const QString &album)
{
    emit addAlbumToPlaylistRequested(album);
}
void PlayerController::requestAddToQueue(const QString &path)
{
    emit addToQueueRequested(QStringList{path});
}
void PlayerController::requestAddAlbumToQueue(const QString &album)
{
    // Resolve album tracks and emit paths
    QStringList paths;
    for (const CoreTrack &t : m_core->tracksForAlbum(album.toStdString()))
        paths.append(QString::fromStdString(t.path));
    emit addToQueueRequested(paths);
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

QStringList PlayerController::scanFolders()        const { return toQStringList(m_core->scanFolders()); }
int         PlayerController::playCountThreshold() const { return m_core->playCountThreshold(); }
bool        PlayerController::stopAfterCurrent()   const { return m_core->stopAfterCurrent(); }

void PlayerController::setPlayCountThreshold(int p) { m_core->setPlayCountThreshold(p); }
void PlayerController::saveSettings()               { m_core->saveSettings(); }

// ---------------------------------------------------------------------------
// A-B repeat
// ---------------------------------------------------------------------------

bool   PlayerController::abRepeatActive() const { return m_core->abRepeatActive(); }
qint64 PlayerController::pointA()         const { return m_core->pointA(); }
qint64 PlayerController::pointB()         const { return m_core->pointB(); }
void   PlayerController::setPointA()            { m_core->setPointA(); }
void   PlayerController::setPointB()            { m_core->setPointB(); }
void   PlayerController::clearAbRepeat()        { m_core->clearAbRepeat(); }