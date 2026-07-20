#include "userdatamanager.h"
#include <algorithm>
#include <sqlite3.h>

UserDataManager::UserDataManager()
{
    m_userData = new UserData();
}

bool UserDataManager::open(const std::string &dataDir)
{
    m_dataDir = dataDir;
    if (!m_userData->open(dataDir)) return false;

    m_userData->onPlaylistsChanged = [this]() {
        if (onPlaylistsChanged) onPlaylistsChanged();
    };
    m_userData->onFavoritesChanged = [this]() {
        if (onIsFavoriteChanged) onIsFavoriteChanged();
    };

    return true;
}

void UserDataManager::setLibrary(Library *library)
{
    m_library = library;
}

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

bool UserDataManager::isFavorite(const std::string &path) const
{
    return m_userData->isFavorite(path);
}

void UserDataManager::toggleFavorite(const std::string &path)
{
    bool current = m_userData->isFavorite(path);
    m_userData->setFavorite(path, !current);
}

std::unordered_set<std::string> UserDataManager::allFavoritePaths() const
{
    return m_userData->allFavoritePaths();
}

// ---------------------------------------------------------------------------
// Play stats
// ---------------------------------------------------------------------------

void UserDataManager::incrementPlayCount(const std::string &path)
{
    m_userData->incrementPlayCount(path);
}

void UserDataManager::applyUserData(Track &track) const
{
    m_userData->applyUserData(track);
}

void UserDataManager::applyUserData(std::vector<Track> &tracks) const
{
    m_userData->applyUserData(tracks);
}

// ---------------------------------------------------------------------------
// Playlists
// ---------------------------------------------------------------------------

std::vector<Natsuyume::CorePlaylistInfo> UserDataManager::allPlaylists() const
{
    std::vector<Natsuyume::CorePlaylistInfo> result;
    for (const PlaylistInfo &p : m_userData->allPlaylists()) {
        Natsuyume::CorePlaylistInfo info;
        info.id   = p.id;
        info.name = p.name;
        result.push_back(std::move(info));
    }
    return result;
}

int UserDataManager::createPlaylist(const std::string &name)
{
    return m_userData->createPlaylist(name);
}

void UserDataManager::deletePlaylist(int playlistId)
{
    m_userData->deletePlaylist(playlistId);
}

void UserDataManager::renamePlaylist(int playlistId, const std::string &name)
{
    m_userData->renamePlaylist(playlistId, name);
}

void UserDataManager::setPlaylistImage(int playlistId,
                                       const std::string &imagePath)
{
    m_userData->setPlaylistImage(playlistId, imagePath);
}

void UserDataManager::addTrackToPlaylist(int playlistId,
                                         const std::string &path)
{
    m_userData->addTrackToPlaylist(playlistId, path);
}

void UserDataManager::removeTrackFromPlaylist(int playlistId,
                                              const std::string &path)
{
    m_userData->removeTrackFromPlaylist(playlistId, path);
}

void UserDataManager::moveTrackInPlaylist(int playlistId, int from, int to)
{
    m_userData->moveTrackInPlaylist(playlistId, from, to);
}

void UserDataManager::sortPlaylist(int playlistId)
{
    if (!m_library) return;

    auto paths = m_userData->playlistTrackPaths(playlistId);
    std::vector<Track> tracks;
    tracks.reserve(paths.size());

    for (const auto &path : paths) {
        Track t = m_library->trackByPath(path);
        if (t.isValid()) tracks.push_back(t);
    }

    Library::TrackSort sort = m_playlistSort;
    bool ascending          = m_playlistSortAscending;

    std::sort(tracks.begin(), tracks.end(),
              [sort, ascending](const Track &a, const Track &b) {
                  bool result = false;
                  switch (sort) {
                  case Library::TrackSort::Title:
                      result = a.title < b.title; break;
                  case Library::TrackSort::Artist:
                      result = a.artist < b.artist; break;
                  case Library::TrackSort::Year:
                      result = a.year < b.year; break;
                  case Library::TrackSort::Duration:
                      result = a.duration < b.duration; break;
                  case Library::TrackSort::TrackNumber:
                  default:
                      result = (a.discNumber != b.discNumber)
                                   ? a.discNumber < b.discNumber
                                   : a.trackNumber < b.trackNumber;
                      break;
                  }
                  return ascending ? result : !result;
              });

    // Rewrite positions directly via SQLite3 C API
    sqlite3 *db = m_userData->db();
    sqlite3_exec(db, "BEGIN TRANSACTION", nullptr, nullptr, nullptr);

    for (int i = 0; i < (int)tracks.size(); ++i) {
        sqlite3_stmt *stmt = nullptr;
        if (sqlite3_prepare_v2(db, R"(
            UPDATE playlist_tracks SET position = ?
            WHERE playlist_id = ? AND path = ?
        )", -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int (stmt, 1, i);
            sqlite3_bind_int (stmt, 2, playlistId);
            sqlite3_bind_text(stmt, 3, tracks[i].path.c_str(),
                              -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    sqlite3_exec(db, "COMMIT", nullptr, nullptr, nullptr);
    if (onPlaylistsChanged) onPlaylistsChanged();
}

int UserDataManager::saveQueueAsPlaylist(const std::string &name,
                                         const std::vector<std::string> &paths)
{
    return m_userData->saveQueueAsPlaylist(name, paths);
}

std::vector<Track> UserDataManager::tracksForPlaylist(int playlistId) const
{
    if (!m_library) return {};

    auto paths = m_userData->playlistTrackPaths(playlistId);
    std::vector<Track> result;
    result.reserve(paths.size());

    for (const auto &path : paths) {
        Track t = m_library->trackByPath(path);
        if (t.isValid()) {
            m_userData->applyUserData(t);
            result.push_back(std::move(t));
        }
    }
    return result;
}

void UserDataManager::openPlaylistInNewQueue(int playlistId,
                                             const std::string &name)
{
    auto paths = m_userData->playlistTrackPaths(playlistId);
    if (!paths.empty() && onOpenInNewQueueRequested)
        onOpenInNewQueueRequested(paths, name);
}

// ---------------------------------------------------------------------------
// Playlist sort
// ---------------------------------------------------------------------------

int  UserDataManager::playlistSort()          const
{
    return static_cast<int>(m_playlistSort);
}

bool UserDataManager::playlistSortAscending() const
{
    return m_playlistSortAscending;
}

void UserDataManager::setPlaylistSort(int sort)
{
    m_playlistSort = static_cast<Library::TrackSort>(sort);
    if (onPlaylistSortChanged) onPlaylistSortChanged();
    saveSettings(m_dataDir);
}

void UserDataManager::setPlaylistSortAscending(bool ascending)
{
    m_playlistSortAscending = ascending;
    if (onPlaylistSortChanged) onPlaylistSortChanged();
    saveSettings(m_dataDir);
}

// ---------------------------------------------------------------------------
// Artist images
// ---------------------------------------------------------------------------

void UserDataManager::setArtistImage(const std::string &artist,
                                     const std::string &imagePath)
{
    m_userData->setArtistImage(artist, imagePath);
}

std::string UserDataManager::artistImage(const std::string &artist) const
{
    return m_userData->artistImage(artist);
}

// ---------------------------------------------------------------------------
// Clear operations
// ---------------------------------------------------------------------------

void UserDataManager::clearUserData()  { m_userData->clearAll(); }
void UserDataManager::clearLibrary()   { if (m_library) m_library->clear(); }

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

void UserDataManager::loadSettings(const std::string &dataDir)
{
    m_dataDir = dataDir;
    std::string dbPath = dataDir + "/userdata.db";
    sqlite3 *db = nullptr;
    if (sqlite3_open(dbPath.c_str(), &db) != SQLITE_OK) return;

    sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS settings "
        "(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
        nullptr, nullptr, nullptr);

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
                if (v) try { result = std::stoi(v); } catch (...) {}
            }
            sqlite3_finalize(stmt);
        }
        return result;
    };

    m_playlistSort = static_cast<Library::TrackSort>(
        readInt("sort/playlistSort", 0));
    m_playlistSortAscending = readInt("sort/playlistSortAscending", 1) != 0;

    sqlite3_close(db);
    if (onPlaylistSortChanged) onPlaylistSortChanged();
}

void UserDataManager::saveSettings(const std::string &dataDir)
{
    std::string dbPath = dataDir + "/userdata.db";
    sqlite3 *db = nullptr;
    if (sqlite3_open(dbPath.c_str(), &db) != SQLITE_OK) return;

    sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS settings "
        "(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
        nullptr, nullptr, nullptr);

    auto write = [&](const char *key, const std::string &value) {
        sqlite3_stmt *stmt = nullptr;
        if (sqlite3_prepare_v2(db,
                "INSERT INTO settings (key,value) VALUES(?,?) "
                "ON CONFLICT(key) DO UPDATE SET value=?",
                -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 2, value.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 3, value.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    };

    write("sort/playlistSort",
          std::to_string(static_cast<int>(m_playlistSort)));
    write("sort/playlistSortAscending",
          std::to_string(m_playlistSortAscending ? 1 : 0));

    sqlite3_close(db);
}

// ---------------------------------------------------------------------------
// Raw playlists
// ---------------------------------------------------------------------------

std::vector<PlaylistInfo> UserDataManager::rawPlaylists() const
{
    return m_userData->allPlaylists();
}