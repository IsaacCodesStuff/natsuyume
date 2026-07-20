#include "userdata.h"
#include <chrono>
#include <filesystem>

// ---------------------------------------------------------------------------
// RAII statement wrapper (same pattern as library.cpp)
// ---------------------------------------------------------------------------
struct Stmt {
    sqlite3_stmt *s = nullptr;
    ~Stmt() { if (s) sqlite3_finalize(s); }
    operator sqlite3_stmt *() { return s; }
};

static int64_t nowSeconds()
{
    return std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

UserData::UserData() = default;

UserData::~UserData()
{
    if (m_db) sqlite3_close(m_db);
}

bool UserData::open(const std::string &dataDir)
{
    std::filesystem::create_directories(dataDir);
    std::string dbPath = dataDir + "/userdata.db";

    if (sqlite3_open(dbPath.c_str(), &m_db) != SQLITE_OK)
        return false;

    createSchema();
    return true;
}

bool UserData::exec(const std::string &sql) const
{
    char *err = nullptr;
    int rc = sqlite3_exec(m_db, sql.c_str(), nullptr, nullptr, &err);
    if (err) sqlite3_free(err);
    return rc == SQLITE_OK;
}

// ---------------------------------------------------------------------------
// Schema
// ---------------------------------------------------------------------------

void UserData::createSchema()
{
    exec("PRAGMA journal_mode=WAL");
    exec("PRAGMA foreign_keys=ON");

    exec(R"(
        CREATE TABLE IF NOT EXISTS user_track_data (
            path             TEXT PRIMARY KEY,
            play_count       INTEGER NOT NULL DEFAULT 0,
            date_last_played INTEGER NOT NULL DEFAULT 0,
            is_favorite      INTEGER NOT NULL DEFAULT 0
        )
    )");

    exec(R"(
        CREATE TABLE IF NOT EXISTS favorite_paths (
            path TEXT PRIMARY KEY
        )
    )");

    exec(R"(
        CREATE TABLE IF NOT EXISTS playlists (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT NOT NULL UNIQUE,
            image_path TEXT NOT NULL DEFAULT ''
        )
    )");

    exec(R"(
        CREATE TABLE IF NOT EXISTS playlist_tracks (
            playlist_id INTEGER NOT NULL,
            path        TEXT    NOT NULL,
            position    INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, path),
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
        )
    )");

    exec(R"(
        CREATE TABLE IF NOT EXISTS artist_images (
            artist     TEXT PRIMARY KEY,
            image_path TEXT NOT NULL DEFAULT ''
        )
    )");
}

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

void UserData::setFavorite(const std::string &path, bool favorite)
{
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db,
                "INSERT OR IGNORE INTO user_track_data (path) VALUES (?)",
                -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
        }
    }
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db,
                "UPDATE user_track_data SET is_favorite = ? WHERE path = ?",
                -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int (stmt, 1, favorite ? 1 : 0);
            sqlite3_bind_text(stmt, 2, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
        }
    }
    {
        Stmt stmt;
        const char *sql = favorite
            ? "INSERT OR IGNORE INTO favorite_paths (path) VALUES (?)"
            : "DELETE FROM favorite_paths WHERE path = ?";
        if (sqlite3_prepare_v2(m_db, sql, -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
        }
    }
    if (onFavoritesChanged) onFavoritesChanged();
}

bool UserData::isFavorite(const std::string &path) const
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT is_favorite FROM user_track_data WHERE path = ?",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return false;
    sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) == SQLITE_ROW)
        return sqlite3_column_int(stmt, 0) == 1;
    return false;
}

std::unordered_set<std::string> UserData::allFavoritePaths() const
{
    std::unordered_set<std::string> result;
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db,
                "SELECT path FROM user_track_data WHERE is_favorite = 1",
                -1, &stmt.s, nullptr) == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                const char *v = reinterpret_cast<const char *>(
                    sqlite3_column_text(stmt, 0));
                if (v) result.insert(v);
            }
        }
    }
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db,
                "SELECT path FROM favorite_paths",
                -1, &stmt.s, nullptr) == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                const char *v = reinterpret_cast<const char *>(
                    sqlite3_column_text(stmt, 0));
                if (v) result.insert(v);
            }
        }
    }
    return result;
}

// ---------------------------------------------------------------------------
// Play stats
// ---------------------------------------------------------------------------

void UserData::incrementPlayCount(const std::string &path)
{
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db,
                "INSERT OR IGNORE INTO user_track_data (path) VALUES (?)",
                -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
        }
    }
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            UPDATE user_track_data
            SET play_count = play_count + 1,
                date_last_played = ?
            WHERE path = ?
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, nowSeconds());
            sqlite3_bind_text (stmt, 2, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
        }
    }
    if (onStatsChanged) onStatsChanged();
}

int UserData::playCount(const std::string &path) const
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT play_count FROM user_track_data WHERE path = ?",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return 0;
    sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
    return sqlite3_step(stmt) == SQLITE_ROW ? sqlite3_column_int(stmt, 0) : 0;
}

int64_t UserData::dateLastPlayed(const std::string &path) const
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT date_last_played FROM user_track_data WHERE path = ?",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return 0;
    sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
    return sqlite3_step(stmt) == SQLITE_ROW
               ? sqlite3_column_int64(stmt, 0) : 0;
}

// ---------------------------------------------------------------------------
// Merging
// ---------------------------------------------------------------------------

void UserData::applyUserData(Track &track) const
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT play_count, date_last_played, is_favorite
        FROM user_track_data WHERE path = ?
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return;

    sqlite3_bind_text(stmt, 1, track.path.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        track.playCount      = sqlite3_column_int  (stmt, 0);
        track.dateLastPlayed = sqlite3_column_int64(stmt, 1);
        track.isFavorite     = sqlite3_column_int  (stmt, 2) == 1;
    }
}

void UserData::applyUserData(std::vector<Track> &tracks) const
{
    for (Track &t : tracks)
        applyUserData(t);
}

// ---------------------------------------------------------------------------
// Playlists
// ---------------------------------------------------------------------------

int UserData::createPlaylist(const std::string &name)
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "INSERT INTO playlists (name) VALUES (?)",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return -1;

    sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) != SQLITE_DONE)
        return -1;

    int id = static_cast<int>(sqlite3_last_insert_rowid(m_db));
    if (onPlaylistsChanged) onPlaylistsChanged();
    return id;
}

void UserData::deletePlaylist(int playlistId)
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "DELETE FROM playlists WHERE id = ?",
            -1, &stmt.s, nullptr) == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, playlistId);
        sqlite3_step(stmt);
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
}

void UserData::renamePlaylist(int playlistId, const std::string &name)
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "UPDATE playlists SET name = ? WHERE id = ?",
            -1, &stmt.s, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int (stmt, 2, playlistId);
        sqlite3_step(stmt);
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
}

void UserData::setPlaylistImage(int playlistId, const std::string &imagePath)
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "UPDATE playlists SET image_path = ? WHERE id = ?",
            -1, &stmt.s, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, imagePath.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int (stmt, 2, playlistId);
        sqlite3_step(stmt);
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
}

void UserData::addTrackToPlaylist(int playlistId, const std::string &path)
{
    int nextPos = 0;
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            SELECT COALESCE(MAX(position), -1)
            FROM playlist_tracks WHERE playlist_id = ?
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, playlistId);
            if (sqlite3_step(stmt) == SQLITE_ROW)
                nextPos = sqlite3_column_int(stmt, 0) + 1;
        }
    }
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            INSERT OR IGNORE INTO playlist_tracks (playlist_id, path, position)
            VALUES (?,?,?)
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int (stmt, 1, playlistId);
            sqlite3_bind_text(stmt, 2, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int (stmt, 3, nextPos);
            sqlite3_step(stmt);
        }
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
}

void UserData::removeTrackFromPlaylist(int playlistId, const std::string &path)
{
    int removedPos = -1;
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            SELECT position FROM playlist_tracks
            WHERE playlist_id = ? AND path = ?
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int (stmt, 1, playlistId);
            sqlite3_bind_text(stmt, 2, path.c_str(), -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) == SQLITE_ROW)
                removedPos = sqlite3_column_int(stmt, 0);
        }
    }
    if (removedPos < 0) return;
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            DELETE FROM playlist_tracks
            WHERE playlist_id = ? AND path = ?
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int (stmt, 1, playlistId);
            sqlite3_bind_text(stmt, 2, path.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(stmt);
        }
    }
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            UPDATE playlist_tracks SET position = position - 1
            WHERE playlist_id = ? AND position > ?
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, playlistId);
            sqlite3_bind_int(stmt, 2, removedPos);
            sqlite3_step(stmt);
        }
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
}

void UserData::moveTrackInPlaylist(int playlistId, int from, int to)
{
    if (from == to) return;

    // Temporarily set to -1 to avoid constraint conflicts
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            UPDATE playlist_tracks SET position = -1
            WHERE playlist_id = ? AND position = ?
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, playlistId);
            sqlite3_bind_int(stmt, 2, from);
            sqlite3_step(stmt);
        }
    }
    {
        Stmt stmt;
        const char *sql = (from < to)
            ? "UPDATE playlist_tracks SET position = position - 1 WHERE playlist_id = ? AND position > ? AND position <= ?"
            : "UPDATE playlist_tracks SET position = position + 1 WHERE playlist_id = ? AND position >= ? AND position < ?";
        if (sqlite3_prepare_v2(m_db, sql, -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, playlistId);
            sqlite3_bind_int(stmt, 2, from);
            sqlite3_bind_int(stmt, 3, to);
            sqlite3_step(stmt);
        }
    }
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            UPDATE playlist_tracks SET position = ?
            WHERE playlist_id = ? AND position = -1
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, to);
            sqlite3_bind_int(stmt, 2, playlistId);
            sqlite3_step(stmt);
        }
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
}

void UserData::sortPlaylist(int playlistId,
                            Library::TrackSort sort, bool ascending)
{
    // Intentionally unimplemented here — handled by UserDataManager::sortPlaylist
    (void)playlistId; (void)sort; (void)ascending;
}

int UserData::saveQueueAsPlaylist(const std::string &name,
                                  const std::vector<std::string> &paths)
{
    int id = createPlaylist(name);
    if (id < 0) return -1;

    for (int i = 0; i < (int)paths.size(); ++i) {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            INSERT OR IGNORE INTO playlist_tracks (playlist_id, path, position)
            VALUES (?,?,?)
        )", -1, &stmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int (stmt, 1, id);
            sqlite3_bind_text(stmt, 2, paths[i].c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int (stmt, 3, i);
            sqlite3_step(stmt);
        }
    }
    if (onPlaylistsChanged) onPlaylistsChanged();
    return id;
}

std::vector<PlaylistInfo> UserData::allPlaylists() const
{
    std::vector<PlaylistInfo> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT id, name, image_path FROM playlists ORDER BY name ASC",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        PlaylistInfo info;
        info.id   = sqlite3_column_int(stmt, 0);
        const char *n = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
        const char *p = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
        info.name      = n ? n : "";
        info.imagePath = p ? p : "";
        result.push_back(std::move(info));
    }
    return result;
}

std::vector<std::string> UserData::playlistTrackPaths(int playlistId) const
{
    std::vector<std::string> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT path FROM playlist_tracks
        WHERE playlist_id = ? ORDER BY position ASC
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    sqlite3_bind_int(stmt, 1, playlistId);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        if (v) result.push_back(v);
    }
    return result;
}

// ---------------------------------------------------------------------------
// Artist images
// ---------------------------------------------------------------------------

void UserData::setArtistImage(const std::string &artist,
                              const std::string &imagePath)
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        INSERT INTO artist_images (artist, image_path) VALUES (?,?)
        ON CONFLICT(artist) DO UPDATE SET image_path = ?
    )", -1, &stmt.s, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, artist.c_str(),    -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, imagePath.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 3, imagePath.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_step(stmt);
    }
}

std::string UserData::artistImage(const std::string &artist) const
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT image_path FROM artist_images WHERE artist = ?",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return "";
    sqlite3_bind_text(stmt, 1, artist.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        return v ? v : "";
    }
    return "";
}

// ---------------------------------------------------------------------------
// Nuclear reset
// ---------------------------------------------------------------------------

void UserData::clearAll()
{
    exec("DELETE FROM user_track_data");
    exec("DELETE FROM favorite_paths");
    exec("DELETE FROM playlists");
    exec("DELETE FROM artist_images");
    if (onPlaylistsChanged) onPlaylistsChanged();
    if (onFavoritesChanged) onFavoritesChanged();
    if (onStatsChanged)     onStatsChanged();
}