#include "librarymanager.h"
#include "metadata.h"
#include <QFile>
#include <QSettings>
#include <QThread>

LibraryManager::LibraryManager(QObject *parent)
    : QObject{parent}
{
    m_library = new Library(this);
    m_indexer = new FileIndexer(this);
    connectIndexerSignals();
}

LibraryManager::~LibraryManager()
{
    // m_library and m_indexer are parented to this, Qt cleans them up
}

// --- Initialization ---

bool LibraryManager::open()
{
    return m_library->open();
}

void LibraryManager::setAlbumCoverProvider(AlbumCoverProvider *provider)
{
    m_albumCoverProvider = provider;
    registerAlbumCovers();
}

Library *LibraryManager::library() const
{
    return m_library;
}

// --- Settings ---

void LibraryManager::loadSettings()
{
    QSettings s;

    m_scanFolders = s.value("library/scanFolders").toStringList();

    m_albumSort = static_cast<Library::AlbumSort>(
        s.value("sort/albumSort", 0).toInt());
    m_albumSortAscending = s.value("sort/albumSortAscending", true).toBool();

    m_trackSort = static_cast<Library::TrackSort>(
        s.value("sort/trackSort", 0).toInt());
    m_trackSortAscending = s.value("sort/trackSortAscending", true).toBool();

    m_artistSort = static_cast<Library::ArtistSort>(
        s.value("sort/artistSort", 0).toInt());
    m_artistSortAscending = s.value("sort/artistSortAscending", true).toBool();

    emit scanFoldersChanged();
    emit albumSortChanged();
    emit trackSortChanged();
    emit artistSortChanged();
}

void LibraryManager::saveSettings()
{
    QSettings s;
    s.setValue("library/scanFolders",        m_scanFolders);
    s.setValue("sort/albumSort",             static_cast<int>(m_albumSort));
    s.setValue("sort/albumSortAscending",    m_albumSortAscending);
    s.setValue("sort/trackSort",             static_cast<int>(m_trackSort));
    s.setValue("sort/trackSortAscending",    m_trackSortAscending);
    s.setValue("sort/artistSort",            static_cast<int>(m_artistSort));
    s.setValue("sort/artistSortAscending",   m_artistSortAscending);
}

// --- Library access ---

QStringList LibraryManager::allAlbums() const
{
    return m_library->allAlbums(m_albumSort, m_albumSortAscending);
}

QStringList LibraryManager::allArtists() const
{
    return m_library->allArtists();
}

QStringList LibraryManager::allArtistsSorted() const
{
    return m_library->allArtists(m_artistSort, m_artistSortAscending);
}

QStringList LibraryManager::albumsForArtist(const QString &artist) const
{
    return m_library->albumsForArtist(artist);
}

QVariantList LibraryManager::tracksForAlbum(const QString &album) const
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

QVariantList LibraryManager::tracksForArtist(const QString &artist) const
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

QString LibraryManager::albumCoverPath(const QString &album) const
{
    QList<Track> tracks = m_library->tracksByAlbum(album);
    if (tracks.isEmpty()) return "";
    return tracks.first().path;
}

// --- Scanning ---

void LibraryManager::scanFolder(const QString &folderPath)
{
    const QStringList paths = m_library->allTrackPaths();
    qDebug() << "allTrackPaths returned" << paths.size();

    for (const auto &p : paths)
        qDebug() << p;
    QSet<QString> known(paths.begin(), paths.end());
    m_indexer->setKnownPaths(known);
    m_indexer->scanFolder(folderPath);
}

void LibraryManager::cancelScan()
{
    m_indexer->cancel();
}

void LibraryManager::rescanAllFolders()
{
    if (m_scanFolders.isEmpty()) return;

    QThread *cleanupThread = QThread::create([this]() {
        const QStringList paths = m_library->allTrackPaths();
        for (const QString &path : paths) {
            if (!QFile::exists(path)) {
                QMetaObject::invokeMethod(this, [this, path]() {
                    m_library->removeTrack(path);
                }, Qt::QueuedConnection);
            }
        }
    });

    connect(cleanupThread, &QThread::finished, this,
            [this, cleanupThread]() {
                cleanupThread->deleteLater();
                scanFoldersSequentially(0);
            });

    cleanupThread->start();
}

void LibraryManager::scanFoldersSequentially(int index)
{
    if (index >= m_scanFolders.size()) return;

    const QString &folder = m_scanFolders.at(index);

    // Connect to scanFinished to trigger next folder
    QMetaObject::Connection *conn = new QMetaObject::Connection;
    *conn = connect(m_indexer, &FileIndexer::scanFinished, this,
                    [this, index, conn]() {
                        disconnect(*conn);
                        delete conn;
                        scanFoldersSequentially(index + 1);
                    });

    scanFolder(folder);
}

void LibraryManager::addScanFolder(const QString &path)
{
    if (m_scanFolders.contains(path)) return;
    m_scanFolders.append(path);
    emit scanFoldersChanged();
    saveSettings();
    scanFolder(path);
}

void LibraryManager::removeScanFolder(const QString &path)
{
    m_scanFolders.removeAll(path);
    emit scanFoldersChanged();
    saveSettings();
    m_library->removeTracksFromFolder(path);
}

QStringList LibraryManager::scanFolders()  const { return m_scanFolders; }
bool        LibraryManager::isScanning()   const { return m_indexer->isScanning(); }
int         LibraryManager::scanProgress() const { return m_scanProgress; }
int         LibraryManager::scanTotal()    const { return m_scanTotal; }
QString     LibraryManager::scanningFile() const { return m_scanningFile; }

// --- Sort ---

int  LibraryManager::albumSort()          const { return static_cast<int>(m_albumSort); }
bool LibraryManager::albumSortAscending() const { return m_albumSortAscending; }

void LibraryManager::setAlbumSort(int sort)
{
    m_albumSort = static_cast<Library::AlbumSort>(sort);
    emit albumSortChanged();
    emit libraryChanged();
    saveSettings();
}

void LibraryManager::setAlbumSortAscending(bool ascending)
{
    m_albumSortAscending = ascending;
    emit albumSortChanged();
    emit libraryChanged();
    saveSettings();
}

int  LibraryManager::trackSort()          const { return static_cast<int>(m_trackSort); }
bool LibraryManager::trackSortAscending() const { return m_trackSortAscending; }

void LibraryManager::setTrackSort(int sort)
{
    m_trackSort = static_cast<Library::TrackSort>(sort);
    emit trackSortChanged();
    saveSettings();
}

void LibraryManager::setTrackSortAscending(bool ascending)
{
    m_trackSortAscending = ascending;
    emit trackSortChanged();
    saveSettings();
}

int  LibraryManager::artistSort()          const { return static_cast<int>(m_artistSort); }
bool LibraryManager::artistSortAscending() const { return m_artistSortAscending; }

void LibraryManager::setArtistSort(int sort)
{
    m_artistSort = static_cast<Library::ArtistSort>(sort);
    emit artistSortChanged();
    saveSettings();
}

void LibraryManager::setArtistSortAscending(bool ascending)
{
    m_artistSortAscending = ascending;
    emit artistSortChanged();
    saveSettings();
}

// --- Private helpers ---

void LibraryManager::registerAlbumCovers()
{
    if (!m_albumCoverProvider) return;
    QStringList albums = m_library->allAlbums();
    for (const QString &album : std::as_const(albums)) {
        if (m_albumCoverProvider->hasAlbum(album)) continue;
        QList<Track> tracks = m_library->tracksByAlbum(album);
        if (!tracks.isEmpty())
            m_albumCoverProvider->registerAlbum(album, tracks.first().path);
    }
}

void LibraryManager::connectIndexerSignals()
{
    qDebug() << "connectIndexerSignals called" << this;
    connect(m_indexer, &FileIndexer::scanStarted, this, [this](int total) {
        m_scanProgress = 0;
        m_scanTotal    = total;
        emit scanningChanged();
        emit scanProgressChanged();
    });

    connect(m_indexer, &FileIndexer::scanProgress, this,
            [this](int scanned, int total, const QString &currentFile) {
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
        registerAlbumCovers();
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

    connect(m_indexer, &FileIndexer::tracksFound, this, [this](const QList<Track> &tracks) {
        qDebug() << "tracksFound received:" << tracks.size() << "tracks - connection count should be 1";
        m_library->addTracks(tracks);
    }, Qt::QueuedConnection);

    connect(m_library, &Library::libraryChanged, this, [this]() {
        emit libraryChanged();
    });
}