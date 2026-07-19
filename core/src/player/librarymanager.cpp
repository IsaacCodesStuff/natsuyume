#include "librarymanager.h"
#include "metadata.h"
#include <QFile>
#include <QSettings>
#include <QMetaObject>
#include <thread>

LibraryManager::LibraryManager(QObject *parent)
    : QObject{parent}
{
    m_library = new Library(this);
    m_indexer = new FileIndexer();
    connectIndexerCallbacks();
}

LibraryManager::~LibraryManager()
{
    delete m_indexer;
}

bool LibraryManager::open()
{
    return m_library->open();
}

Library *LibraryManager::library() const
{
    return m_library;
}

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
    s.setValue("library/scanFolders",       m_scanFolders);
    s.setValue("sort/albumSort",            static_cast<int>(m_albumSort));
    s.setValue("sort/albumSortAscending",   m_albumSortAscending);
    s.setValue("sort/trackSort",            static_cast<int>(m_trackSort));
    s.setValue("sort/trackSortAscending",   m_trackSortAscending);
    s.setValue("sort/artistSort",           static_cast<int>(m_artistSort));
    s.setValue("sort/artistSortAscending",  m_artistSortAscending);
}

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

void LibraryManager::scanFolder(const QString &folderPath)
{
    const QStringList paths = m_library->allTrackPaths();
    std::unordered_map<std::string, qint64> known;
    for (const QString &p : paths)
        known[p.toStdString()] = m_library->lastModifiedFor(p);
    m_indexer->setKnownPaths(known);
    m_indexer->scanFolder(folderPath.toStdString());
}

void LibraryManager::cancelScan()
{
    m_indexer->cancel();
}

void LibraryManager::rescanAllFolders()
{
    if (m_scanFolders.isEmpty()) return;

    // Convert to std types on the main thread before handing off
    const QStringList qtPaths = m_library->allTrackPaths();
    std::vector<std::string> paths;
    paths.reserve(qtPaths.size());
    for (const QString &p : qtPaths)
        paths.push_back(p.toStdString());

    std::thread([this, paths]() {
        try {
            for (const std::string &path : paths) {
                namespace fs = std::filesystem;
                if (!fs::exists(path)) {
                    QString qpath = QString::fromStdString(path);
                    QMetaObject::invokeMethod(this, [this, qpath]() {
                        m_library->removeTrack(qpath);
                    }, Qt::QueuedConnection);
                }
            }
            QMetaObject::invokeMethod(this, [this]() {
                scanFoldersSequentially(0);
            }, Qt::QueuedConnection);
        } catch (const std::exception &e) {
            qWarning() << "rescanAllFolders thread error:" << e.what();
        } catch (...) {
            qWarning() << "rescanAllFolders thread: unknown error";
        }
    }).detach();
}

void LibraryManager::scanFoldersSequentially(int index)
{
    if (index >= m_scanFolders.size()) return;

    m_indexer->onScanFinished([this, index]() {
        QMetaObject::invokeMethod(this, [this, index]() {
            m_indexer->onScanFinished([this]() {
                QMetaObject::invokeMethod(this, [this]() {
                    m_scanProgress = m_scanTotal;
                    emit scanningChanged();
                    emit scanProgressChanged();
                    emit libraryChanged();
                }, Qt::QueuedConnection);
            });
            scanFoldersSequentially(index + 1);
        }, Qt::QueuedConnection);
    });

    scanFolder(m_scanFolders.at(index));
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
    // Don't remove tracks — they'll be cleaned up naturally
    // on the next rescan when the cleanup thread finds missing files
}

QStringList LibraryManager::scanFolders()  const { return m_scanFolders; }
bool        LibraryManager::isScanning()   const { return m_indexer->isScanning(); }
int         LibraryManager::scanProgress() const { return m_scanProgress; }
int         LibraryManager::scanTotal()    const { return m_scanTotal; }
QString     LibraryManager::scanningFile() const { return m_scanningFile; }

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

void LibraryManager::connectIndexerCallbacks()
{
    m_indexer->onScanStarted([this](int total) {
        QMetaObject::invokeMethod(this, [this, total]() {
            m_scanProgress = 0;
            m_scanTotal    = total;
            emit scanningChanged();
            emit scanProgressChanged();
        }, Qt::QueuedConnection);
    });

    m_indexer->onScanProgress([this](int scanned, int total, const std::string &currentFile) {
        QMetaObject::invokeMethod(this, [this, scanned, total,
                                         file = QString::fromStdString(currentFile)]() mutable {
            m_scanProgress = scanned;
            m_scanTotal    = total;
            m_scanningFile = file;
            emit scanProgressChanged();
        }, Qt::QueuedConnection);
    });

    m_indexer->onScanFinished([this]() {
        QMetaObject::invokeMethod(this, [this]() {
            m_scanProgress = m_scanTotal;
            emit scanningChanged();
            emit scanProgressChanged();
            emit libraryChanged();
        }, Qt::QueuedConnection);
    });

    m_indexer->onScanCancelled([this]() {
        QMetaObject::invokeMethod(this, [this]() {
            m_scanProgress = 0;
            m_scanTotal    = 0;
            emit scanningChanged();
            emit scanProgressChanged();
        }, Qt::QueuedConnection);
    });

    m_indexer->onScanningChanged([this](bool) {
        QMetaObject::invokeMethod(this, [this]() {
            emit scanningChanged();
        }, Qt::QueuedConnection);
    });

    m_indexer->onTracksFound([this](const std::vector<Track> &tracks) {
        QMetaObject::invokeMethod(this, [this, tracks]() {
            m_library->addTracks(QList<Track>(tracks.begin(), tracks.end()));
            emit libraryChanged();
        }, Qt::QueuedConnection);
    });

    connect(m_library, &Library::libraryChanged, this, [this]() {
        emit libraryChanged();
    });
}