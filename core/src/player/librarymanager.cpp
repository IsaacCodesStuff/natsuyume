#include "librarymanager.h"
#include <filesystem>
#include <sqlite3.h>
#include <thread>

namespace fs = std::filesystem;

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

LibraryManager::LibraryManager()
{
    m_library = new Library();
    m_indexer = new FileIndexer();
    connectIndexerCallbacks();
}

LibraryManager::~LibraryManager()
{
    delete m_indexer;
    delete m_library;
}

bool LibraryManager::open(const std::string &dataDir)
{
    m_dataDir = dataDir;
    if (!m_library->open(dataDir)) return false;
    m_library->onLibraryChanged = [this]() {
        post([this]() { if (onLibraryChanged) onLibraryChanged(); });
    };
    loadSettings();
    return true;
}

// ---------------------------------------------------------------------------
// Thread-safe callback queue
// ---------------------------------------------------------------------------

void LibraryManager::post(std::function<void()> fn)
{
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_pendingCallbacks.push(std::move(fn));
}

void LibraryManager::drainCallbacks()
{
    std::queue<std::function<void()>> local;
    {
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        std::swap(local, m_pendingCallbacks);
    }
    while (!local.empty()) {
        local.front()();
        local.pop();
    }
}

// ---------------------------------------------------------------------------
// Settings (SQLite key-value table in userdata.db)
// ---------------------------------------------------------------------------

void LibraryManager::loadSettings()
{
    std::string dbPath = m_dataDir + "/userdata.db";
    sqlite3 *db = nullptr;
    if (sqlite3_open(dbPath.c_str(), &db) != SQLITE_OK) return;

    auto readInt = [&](const char *key, int fallback) -> int {
        sqlite3_stmt *stmt = nullptr;
        int result = fallback;
        if (sqlite3_prepare_v2(db,
                "SELECT value FROM settings WHERE key = ?",
                -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                const char *v = reinterpret_cast<const char *>(
                    sqlite3_column_text(stmt, 0));
                if (v) result = std::stoi(v);
            }
            sqlite3_finalize(stmt);
        }
        return result;
    };

    auto readStr = [&](const char *key, const char *fallback) -> std::string {
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

    // Ensure settings table exists
    sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS settings "
        "(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
        nullptr, nullptr, nullptr);

    // Scan folders stored as pipe-delimited string
    std::string foldersStr = readStr("library/scanFolders", "");
    m_scanFolders.clear();
    if (!foldersStr.empty()) {
        size_t start = 0, pos;
        while ((pos = foldersStr.find('|', start)) != std::string::npos) {
            m_scanFolders.push_back(foldersStr.substr(start, pos - start));
            start = pos + 1;
        }
        if (start < foldersStr.size())
            m_scanFolders.push_back(foldersStr.substr(start));
    }

    m_albumSort          = static_cast<Library::AlbumSort>(
                               readInt("sort/albumSort", 0));
    m_albumSortAscending = readInt("sort/albumSortAscending", 1) != 0;
    m_trackSort          = static_cast<Library::TrackSort>(
                               readInt("sort/trackSort", 0));
    m_trackSortAscending = readInt("sort/trackSortAscending", 1) != 0;
    m_artistSort         = static_cast<Library::ArtistSort>(
                               readInt("sort/artistSort", 0));
    m_artistSortAscending = readInt("sort/artistSortAscending", 1) != 0;

    sqlite3_close(db);

    if (onScanFoldersChanged) onScanFoldersChanged();
    if (onAlbumSortChanged)   onAlbumSortChanged();
    if (onTrackSortChanged)   onTrackSortChanged();
    if (onArtistSortChanged)  onArtistSortChanged();
}

void LibraryManager::saveSettings()
{
    std::string dbPath = m_dataDir + "/userdata.db";
    sqlite3 *db = nullptr;
    if (sqlite3_open(dbPath.c_str(), &db) != SQLITE_OK) return;

    sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS settings "
        "(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
        nullptr, nullptr, nullptr);

    auto write = [&](const char *key, const std::string &value) {
        sqlite3_stmt *stmt = nullptr;
        if (sqlite3_prepare_v2(db,
                "INSERT INTO settings (key, value) VALUES (?,?) "
                "ON CONFLICT(key) DO UPDATE SET value=?",
                -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, key,          -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 2, value.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 3, value.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    };

    // Serialize scan folders as pipe-delimited
    std::string foldersStr;
    for (size_t i = 0; i < m_scanFolders.size(); ++i) {
        if (i > 0) foldersStr += '|';
        foldersStr += m_scanFolders[i];
    }

    write("library/scanFolders",      foldersStr);
    write("sort/albumSort",           std::to_string(static_cast<int>(m_albumSort)));
    write("sort/albumSortAscending",  std::to_string(m_albumSortAscending ? 1 : 0));
    write("sort/trackSort",           std::to_string(static_cast<int>(m_trackSort)));
    write("sort/trackSortAscending",  std::to_string(m_trackSortAscending ? 1 : 0));
    write("sort/artistSort",          std::to_string(static_cast<int>(m_artistSort)));
    write("sort/artistSortAscending", std::to_string(m_artistSortAscending ? 1 : 0));

    sqlite3_close(db);
}

// ---------------------------------------------------------------------------
// Library access
// ---------------------------------------------------------------------------

Library *LibraryManager::library() const { return m_library; }

std::vector<std::string> LibraryManager::allAlbums() const
{
    return m_library->allAlbums(m_albumSort, m_albumSortAscending);
}

std::vector<std::string> LibraryManager::allArtists() const
{
    return m_library->allArtists();
}

std::vector<std::string> LibraryManager::allArtistsSorted() const
{
    return m_library->allArtists(m_artistSort, m_artistSortAscending);
}

std::vector<std::string> LibraryManager::albumsForArtist(const std::string &artist) const
{
    return m_library->albumsForArtist(artist);
}

std::vector<Track> LibraryManager::tracksForAlbum(const std::string &album) const
{
    return m_library->tracksByAlbum(album, m_trackSort, m_trackSortAscending);
}

std::vector<Track> LibraryManager::tracksForArtist(const std::string &artist) const
{
    return m_library->tracksByArtist(artist);
}

std::string LibraryManager::albumCoverPath(const std::string &album) const
{
    auto tracks = m_library->tracksByAlbum(album);
    return tracks.empty() ? "" : tracks.front().path;
}

// ---------------------------------------------------------------------------
// Scanning
// ---------------------------------------------------------------------------

void LibraryManager::scanFolder(const std::string &folderPath)
{
    auto paths = m_library->allTrackPaths();
    std::unordered_map<std::string, int64_t> known;
    for (const auto &p : paths)
        known[p] = m_library->lastModifiedFor(p);
    m_indexer->setKnownPaths(known);
    m_indexer->scanFolder(folderPath);
}

void LibraryManager::cancelScan()
{
    m_indexer->cancel();
}

void LibraryManager::rescanAllFolders()
{
    if (m_scanFolders.empty()) return;

    auto paths = m_library->allTrackPaths();

    std::thread([this, paths]() {
        try {
            for (const auto &path : paths) {
                if (!fs::exists(path)) {
                    post([this, path]() {
                        m_library->removeTrack(path);
                    });
                }
            }
            post([this]() {
                scanFoldersSequentially(0);
            });
        } catch (...) {}
    }).detach();
}

void LibraryManager::scanFoldersSequentially(int index)
{
    if (index >= (int)m_scanFolders.size()) return;

    m_indexer->onScanFinished([this, index]() {
        post([this, index]() {
            // Restore permanent finished callback then advance
            m_indexer->onScanFinished([this]() {
                post([this]() {
                    m_scanProgress = m_scanTotal;
                    if (onScanningChanged)     onScanningChanged();
                    if (onScanProgressChanged) onScanProgressChanged(
                        m_scanProgress, m_scanTotal, m_scanningFile);
                    if (onLibraryChanged)      onLibraryChanged();
                });
            });
            scanFoldersSequentially(index + 1);
        });
    });

    scanFolder(m_scanFolders.at(index));
}

void LibraryManager::addScanFolder(const std::string &path)
{
    for (const auto &f : m_scanFolders)
        if (f == path) return;
    m_scanFolders.push_back(path);
    if (onScanFoldersChanged) onScanFoldersChanged();
    saveSettings();
    scanFolder(path);
}

void LibraryManager::removeScanFolder(const std::string &path)
{
    m_scanFolders.erase(
        std::remove(m_scanFolders.begin(), m_scanFolders.end(), path),
        m_scanFolders.end());
    if (onScanFoldersChanged) onScanFoldersChanged();
    saveSettings();
}

std::vector<std::string> LibraryManager::scanFolders()  const { return m_scanFolders; }
bool        LibraryManager::isScanning()   const { return m_indexer->isScanning(); }
int         LibraryManager::scanProgress() const { return m_scanProgress; }
int         LibraryManager::scanTotal()    const { return m_scanTotal; }
std::string LibraryManager::scanningFile() const { return m_scanningFile; }

// ---------------------------------------------------------------------------
// Sort
// ---------------------------------------------------------------------------

int  LibraryManager::albumSort()          const { return static_cast<int>(m_albumSort); }
bool LibraryManager::albumSortAscending() const { return m_albumSortAscending; }

void LibraryManager::setAlbumSort(int sort)
{
    m_albumSort = static_cast<Library::AlbumSort>(sort);
    if (onAlbumSortChanged) onAlbumSortChanged();
    if (onLibraryChanged)   onLibraryChanged();
    saveSettings();
}

void LibraryManager::setAlbumSortAscending(bool ascending)
{
    m_albumSortAscending = ascending;
    if (onAlbumSortChanged) onAlbumSortChanged();
    if (onLibraryChanged)   onLibraryChanged();
    saveSettings();
}

int  LibraryManager::trackSort()          const { return static_cast<int>(m_trackSort); }
bool LibraryManager::trackSortAscending() const { return m_trackSortAscending; }

void LibraryManager::setTrackSort(int sort)
{
    m_trackSort = static_cast<Library::TrackSort>(sort);
    if (onTrackSortChanged) onTrackSortChanged();
    saveSettings();
}

void LibraryManager::setTrackSortAscending(bool ascending)
{
    m_trackSortAscending = ascending;
    if (onTrackSortChanged) onTrackSortChanged();
    saveSettings();
}

int  LibraryManager::artistSort()          const { return static_cast<int>(m_artistSort); }
bool LibraryManager::artistSortAscending() const { return m_artistSortAscending; }

void LibraryManager::setArtistSort(int sort)
{
    m_artistSort = static_cast<Library::ArtistSort>(sort);
    if (onArtistSortChanged) onArtistSortChanged();
    saveSettings();
}

void LibraryManager::setArtistSortAscending(bool ascending)
{
    m_artistSortAscending = ascending;
    if (onArtistSortChanged) onArtistSortChanged();
    saveSettings();
}

// ---------------------------------------------------------------------------
// Indexer callbacks
// ---------------------------------------------------------------------------

void LibraryManager::connectIndexerCallbacks()
{
    m_indexer->onScanStarted([this](int total) {
        post([this, total]() {
            m_scanProgress = 0;
            m_scanTotal    = total;
            if (onScanningChanged)     onScanningChanged();
            if (onScanProgressChanged) onScanProgressChanged(0, total, "");
        });
    });

    m_indexer->onScanProgress([this](int scanned, int total,
                                      const std::string &currentFile) {
        post([this, scanned, total, currentFile]() {
            m_scanProgress = scanned;
            m_scanTotal    = total;
            m_scanningFile = currentFile;
            if (onScanProgressChanged)
                onScanProgressChanged(scanned, total, currentFile);
        });
    });

    m_indexer->onScanFinished([this]() {
        post([this]() {
            m_scanProgress = m_scanTotal;
            if (onScanningChanged)     onScanningChanged();
            if (onScanProgressChanged) onScanProgressChanged(
                m_scanProgress, m_scanTotal, m_scanningFile);
            if (onLibraryChanged)      onLibraryChanged();
        });
    });

    m_indexer->onScanCancelled([this]() {
        post([this]() {
            m_scanProgress = 0;
            m_scanTotal    = 0;
            if (onScanningChanged)     onScanningChanged();
            if (onScanProgressChanged) onScanProgressChanged(0, 0, "");
        });
    });

    m_indexer->onScanningChanged([this](bool) {
        post([this]() {
            if (onScanningChanged) onScanningChanged();
        });
    });

    m_indexer->onTracksFound([this](const std::vector<Track> &tracks) {
        post([this, tracks]() {
            m_library->addTracks(tracks);
            if (onLibraryChanged) onLibraryChanged();
        });
    });
}