#include "library.h"
#include <sqlite3.h>
#include <chrono>
#include <filesystem>
#include <stdexcept>

// ---------------------------------------------------------------------------
// SQLite RAII statement wrapper
// ---------------------------------------------------------------------------
struct Stmt {
    sqlite3_stmt *s = nullptr;
    ~Stmt() { if (s) sqlite3_finalize(s); }
    operator sqlite3_stmt *() { return s; }
};

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

Library::Library() = default;

Library::~Library()
{
    if (m_db) sqlite3_close(m_db);
}

bool Library::open(const std::string &dataDir)
{
    std::filesystem::create_directories(dataDir);
    std::string dbPath = dataDir + "/library.db";

    if (sqlite3_open(dbPath.c_str(), &m_db) != SQLITE_OK)
        return false;

    createSchema();
    populateCache();
    return true;
}

// ---------------------------------------------------------------------------
// Schema
// ---------------------------------------------------------------------------

bool Library::exec(const std::string &sql) const
{
    char *err = nullptr;
    int rc = sqlite3_exec(m_db, sql.c_str(), nullptr, nullptr, &err);
    if (err) sqlite3_free(err);
    return rc == SQLITE_OK;
}

void Library::createSchema()
{
    exec("PRAGMA journal_mode=WAL");
    exec("PRAGMA foreign_keys=ON");

    exec(R"(
        CREATE TABLE IF NOT EXISTS tracks (
            path          TEXT PRIMARY KEY,
            title         TEXT NOT NULL,
            artist        TEXT NOT NULL,
            album         TEXT NOT NULL,
            album_artist  TEXT NOT NULL DEFAULT '',
            composer      TEXT NOT NULL DEFAULT '',
            genre         TEXT NOT NULL DEFAULT '',
            track_number  INTEGER NOT NULL DEFAULT 0,
            disc_number   INTEGER NOT NULL DEFAULT 1,
            year          INTEGER NOT NULL DEFAULT 0,
            duration      INTEGER NOT NULL DEFAULT 0,
            date_added    INTEGER NOT NULL DEFAULT 0,
            last_modified INTEGER NOT NULL DEFAULT 0
        )
    )");

    exec(R"(
        CREATE TABLE IF NOT EXISTS saved_queues (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            name           TEXT    NOT NULL,
            position       INTEGER NOT NULL,
            track_index    INTEGER NOT NULL DEFAULT 0,
            track_position INTEGER NOT NULL DEFAULT 0,
            was_playing    INTEGER NOT NULL DEFAULT 0,
            is_active      INTEGER NOT NULL DEFAULT 0
        )
    )");

    exec(R"(
        CREATE TABLE IF NOT EXISTS saved_queue_tracks (
            queue_id INTEGER NOT NULL,
            path     TEXT    NOT NULL,
            position INTEGER NOT NULL,
            FOREIGN KEY (queue_id) REFERENCES saved_queues(id) ON DELETE CASCADE
        )
    )");
}

void Library::populateCache()
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT path, last_modified FROM tracks",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return;

    std::unique_lock lock(m_cacheLock);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        std::string path = reinterpret_cast<const char *>(
            sqlite3_column_text(stmt, 0));
        int64_t lm = sqlite3_column_int64(stmt, 1);
        m_pathCache[path] = lm;
    }
}

// ---------------------------------------------------------------------------
// Sort helpers
// ---------------------------------------------------------------------------

std::string Library::albumSortColumn(AlbumSort sort)
{
    switch (sort) {
    case AlbumSort::Name:        return "album";
    case AlbumSort::Artist:      return "artist";
    case AlbumSort::AlbumArtist: return "album_artist";
    case AlbumSort::Year:        return "MAX(year)";
    case AlbumSort::SongCount:   return "COUNT(*)";
    case AlbumSort::Duration:    return "SUM(duration)";
    case AlbumSort::Composer:    return "composer";
    case AlbumSort::DateAdded:   return "MAX(date_added)";
    }
    return "album";
}

std::string Library::trackSortColumn(TrackSort sort)
{
    switch (sort) {
    case TrackSort::TrackNumber:  return "disc_number, track_number";
    case TrackSort::Title:        return "title";
    case TrackSort::Artist:       return "artist";
    case TrackSort::AlbumArtist:  return "album_artist";
    case TrackSort::Year:         return "year";
    case TrackSort::Duration:     return "duration";
    case TrackSort::Genre:        return "genre";
    case TrackSort::Composer:     return "composer";
    case TrackSort::Filename:     return "path";
    case TrackSort::DateAdded:    return "date_added";
    default:                      return "disc_number, track_number";
    }
}

// ---------------------------------------------------------------------------
// Track helpers
// ---------------------------------------------------------------------------

Track Library::trackFromStmt(sqlite3_stmt *stmt)
{
    auto col = [&](int i) -> std::string {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, i));
        return v ? v : "";
    };

    Track t(col(0));
    t.title       = col(1);
    t.artist      = col(2);
    t.album       = col(3);
    t.albumArtist = col(4);
    t.composer    = col(5);
    t.genre       = col(6);
    t.trackNumber = sqlite3_column_int(stmt, 7);
    t.discNumber  = sqlite3_column_int(stmt, 8);
    t.year        = sqlite3_column_int(stmt, 9);
    t.duration    = sqlite3_column_int64(stmt, 10);
    t.dateAdded   = sqlite3_column_int64(stmt, 11);
    return t;
}

static int64_t nowSeconds()
{
    return std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
}

// ---------------------------------------------------------------------------
// Track writing
// ---------------------------------------------------------------------------

void Library::addTrack(const Track &track)
{
    Stmt stmt;
    const char *sql = R"(
        INSERT OR REPLACE INTO tracks (
            path, title, artist, album, album_artist,
            composer, genre, track_number, disc_number,
            year, duration, date_added, last_modified
        ) VALUES (
            ?,?,?,?,?,?,?,?,?,?,?,?,?
        )
    )";

    if (sqlite3_prepare_v2(m_db, sql, -1, &stmt.s, nullptr) != SQLITE_OK)
        return;

    sqlite3_bind_text(stmt, 1,  track.path.c_str(),        -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2,  track.title.c_str(),       -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3,  track.artist.c_str(),      -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 4,  track.album.c_str(),       -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 5,  track.albumArtist.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 6,  track.composer.c_str(),    -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 7,  track.genre.c_str(),       -1, SQLITE_TRANSIENT);
    sqlite3_bind_int (stmt, 8,  track.trackNumber);
    sqlite3_bind_int (stmt, 9,  track.discNumber);
    sqlite3_bind_int (stmt, 10, track.year);
    sqlite3_bind_int64(stmt, 11, track.duration);
    sqlite3_bind_int64(stmt, 12, nowSeconds());
    sqlite3_bind_int64(stmt, 13, track.lastModified);

    sqlite3_step(stmt);

    {
        std::unique_lock lock(m_cacheLock);
        m_pathCache[track.path] = track.lastModified;
    }

    if (onLibraryChanged) onLibraryChanged();
}

void Library::addTracks(const std::vector<Track> &tracks)
{
    exec("BEGIN TRANSACTION");

    const char *insertSql = R"(
        INSERT OR IGNORE INTO tracks (
            path, title, artist, album, album_artist,
            composer, genre, track_number, disc_number,
            year, duration, date_added, last_modified
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
    )";

    const char *updateSql = R"(
        UPDATE tracks SET
            title        = ?, artist       = ?, album        = ?,
            album_artist = ?, composer     = ?, genre        = ?,
            track_number = ?, disc_number  = ?, year         = ?,
            duration     = ?
        WHERE path = ?
        AND (
            title IS NOT ? OR artist IS NOT ? OR album IS NOT ? OR
            album_artist IS NOT ? OR composer IS NOT ? OR genre IS NOT ? OR
            track_number IS NOT ? OR disc_number IS NOT ? OR
            year IS NOT ? OR duration IS NOT ?
        )
    )";

    std::unordered_map<std::string, bool> seen;

    for (const Track &track : tracks) {
        if (seen.count(track.path)) continue;
        seen[track.path] = true;

        // INSERT OR IGNORE
        {
            Stmt stmt;
            if (sqlite3_prepare_v2(m_db, insertSql, -1, &stmt.s, nullptr) == SQLITE_OK) {
                sqlite3_bind_text(stmt, 1,  track.path.c_str(),        -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 2,  track.title.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 3,  track.artist.c_str(),      -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 4,  track.album.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 5,  track.albumArtist.c_str(), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 6,  track.composer.c_str(),    -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 7,  track.genre.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_int (stmt, 8,  track.trackNumber);
                sqlite3_bind_int (stmt, 9,  track.discNumber);
                sqlite3_bind_int (stmt, 10, track.year);
                sqlite3_bind_int64(stmt, 11, track.duration);
                sqlite3_bind_int64(stmt, 12, nowSeconds());
                sqlite3_bind_int64(stmt, 13, track.lastModified);
                sqlite3_step(stmt);

                if (sqlite3_changes(m_db) > 0) {
                    std::unique_lock lock(m_cacheLock);
                    m_pathCache[track.path] = track.lastModified;
                    continue; // new row inserted, skip update
                }
            }
        }

        // Conditional UPDATE for existing rows
        {
            Stmt stmt;
            if (sqlite3_prepare_v2(m_db, updateSql, -1, &stmt.s, nullptr) == SQLITE_OK) {
                // SET bindings
                sqlite3_bind_text(stmt, 1,  track.title.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 2,  track.artist.c_str(),      -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 3,  track.album.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 4,  track.albumArtist.c_str(), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 5,  track.composer.c_str(),    -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 6,  track.genre.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_int (stmt, 7,  track.trackNumber);
                sqlite3_bind_int (stmt, 8,  track.discNumber);
                sqlite3_bind_int (stmt, 9,  track.year);
                sqlite3_bind_int64(stmt, 10, track.duration);
                // WHERE path
                sqlite3_bind_text(stmt, 11, track.path.c_str(),        -1, SQLITE_TRANSIENT);
                // WHERE IS NOT comparisons (same order as SET)
                sqlite3_bind_text(stmt, 12, track.title.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 13, track.artist.c_str(),      -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 14, track.album.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 15, track.albumArtist.c_str(), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 16, track.composer.c_str(),    -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(stmt, 17, track.genre.c_str(),       -1, SQLITE_TRANSIENT);
                sqlite3_bind_int (stmt, 18, track.trackNumber);
                sqlite3_bind_int (stmt, 19, track.discNumber);
                sqlite3_bind_int (stmt, 20, track.year);
                sqlite3_bind_int64(stmt, 21, track.duration);
                sqlite3_step(stmt);
            }
        }
    }

    exec("COMMIT");
    if (onLibraryChanged) onLibraryChanged();
}

void Library::removeTrack(const std::string &path)
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "DELETE FROM tracks WHERE path = ?",
            -1, &stmt.s, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_step(stmt);
    }
    {
        std::unique_lock lock(m_cacheLock);
        m_pathCache.erase(path);
    }
    if (onLibraryChanged) onLibraryChanged();
}

void Library::clear()
{
    exec("DELETE FROM tracks");
    {
        std::unique_lock lock(m_cacheLock);
        m_pathCache.clear();
    }
    if (onLibraryChanged) onLibraryChanged();
}

// ---------------------------------------------------------------------------
// Track reading
// ---------------------------------------------------------------------------

std::vector<Track> Library::allTracks() const
{
    std::vector<Track> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added
        FROM tracks ORDER BY title
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW)
        result.push_back(trackFromStmt(stmt));
    return result;
}

std::vector<std::string> Library::allTrackPaths() const
{
    std::vector<std::string> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT path FROM tracks",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        if (v) result.push_back(v);
    }
    return result;
}

Track Library::trackByPath(const std::string &path) const
{
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added
        FROM tracks WHERE path = ?
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return Track();

    sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) == SQLITE_ROW)
        return trackFromStmt(stmt);
    return Track();
}

std::vector<Track> Library::tracksByAlbum(const std::string &album,
                                           TrackSort sort,
                                           bool ascending) const
{
    std::vector<Track> result;
    std::string sql =
        "SELECT path, title, artist, album, album_artist, "
        "       composer, genre, track_number, disc_number, "
        "       year, duration, date_added "
        "FROM tracks WHERE album = ? ORDER BY " +
        trackSortColumn(sort) + (ascending ? " ASC" : " DESC");

    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, sql.c_str(), -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    sqlite3_bind_text(stmt, 1, album.c_str(), -1, SQLITE_TRANSIENT);
    while (sqlite3_step(stmt) == SQLITE_ROW)
        result.push_back(trackFromStmt(stmt));
    return result;
}

std::vector<Track> Library::tracksByArtist(const std::string &artist) const
{
    std::vector<Track> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added
        FROM tracks WHERE artist = ?
        ORDER BY disc_number, track_number
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    sqlite3_bind_text(stmt, 1, artist.c_str(), -1, SQLITE_TRANSIENT);
    while (sqlite3_step(stmt) == SQLITE_ROW)
        result.push_back(trackFromStmt(stmt));
    return result;
}

std::vector<std::string> Library::allAlbums(AlbumSort sort, bool ascending) const
{
    std::vector<std::string> result;
    std::string sql =
        "SELECT album FROM tracks GROUP BY album ORDER BY " +
        albumSortColumn(sort) + (ascending ? " ASC" : " DESC");

    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, sql.c_str(), -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        if (v) result.push_back(v);
    }
    return result;
}

std::vector<std::string> Library::allArtists() const
{
    std::vector<std::string> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db,
            "SELECT DISTINCT artist FROM tracks ORDER BY artist",
            -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        if (v) result.push_back(v);
    }
    return result;
}

std::vector<std::string> Library::allArtists(ArtistSort sort, bool ascending) const
{
    std::vector<std::string> result;
    std::string sortCol;
    switch (sort) {
    case ArtistSort::SongCount: sortCol = "COUNT(*)";        break;
    case ArtistSort::Duration:  sortCol = "SUM(duration)";   break;
    case ArtistSort::DateAdded: sortCol = "MAX(date_added)"; break;
    default:                    sortCol = "artist";          break;
    }

    std::string sql =
        "SELECT artist FROM tracks GROUP BY artist ORDER BY " +
        sortCol + (ascending ? " ASC" : " DESC");

    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, sql.c_str(), -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        if (v) result.push_back(v);
    }
    return result;
}

bool Library::containsPath(const std::string &path) const
{
    std::shared_lock lock(m_cacheLock);
    return m_pathCache.count(path) > 0;
}

int64_t Library::lastModifiedFor(const std::string &path) const
{
    std::shared_lock lock(m_cacheLock);
    auto it = m_pathCache.find(path);
    return it != m_pathCache.end() ? it->second : 0;
}

std::vector<std::string> Library::albumsForArtist(const std::string &artist) const
{
    std::vector<std::string> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT DISTINCT album FROM tracks
        WHERE artist = ? ORDER BY album ASC
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    sqlite3_bind_text(stmt, 1, artist.c_str(), -1, SQLITE_TRANSIENT);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *v = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
        if (v) result.push_back(v);
    }
    return result;
}

// ---------------------------------------------------------------------------
// Queue persistence
// ---------------------------------------------------------------------------

void Library::saveQueues(const std::vector<QueueSnapshot> &queues)
{
    exec("DELETE FROM saved_queues");

    for (int i = 0; i < (int)queues.size(); ++i) {
        const QueueSnapshot &snap = queues[i];

        Stmt stmt;
        if (sqlite3_prepare_v2(m_db, R"(
            INSERT INTO saved_queues
                (name, position, track_index, track_position, was_playing, is_active)
            VALUES (?,?,?,?,?,?)
        )", -1, &stmt.s, nullptr) != SQLITE_OK)
            continue;

        sqlite3_bind_text(stmt, 1, snap.name.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int (stmt, 2, i);
        sqlite3_bind_int (stmt, 3, snap.currentTrackIndex);
        sqlite3_bind_int64(stmt, 4, snap.currentPosition);
        sqlite3_bind_int (stmt, 5, snap.wasPlaying ? 1 : 0);
        sqlite3_bind_int (stmt, 6, snap.isActive   ? 1 : 0);
        sqlite3_step(stmt);

        int64_t queueId = sqlite3_last_insert_rowid(m_db);

        for (int j = 0; j < (int)snap.paths.size(); ++j) {
            Stmt tStmt;
            if (sqlite3_prepare_v2(m_db, R"(
                INSERT INTO saved_queue_tracks (queue_id, path, position)
                VALUES (?,?,?)
            )", -1, &tStmt.s, nullptr) != SQLITE_OK)
                continue;

            sqlite3_bind_int64(tStmt, 1, queueId);
            sqlite3_bind_text (tStmt, 2, snap.paths[j].c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int  (tStmt, 3, j);
            sqlite3_step(tStmt);
        }
    }
}

std::vector<QueueSnapshot> Library::loadQueues() const
{
    std::vector<QueueSnapshot> result;
    Stmt stmt;
    if (sqlite3_prepare_v2(m_db, R"(
        SELECT id, name, track_index, track_position, was_playing, is_active
        FROM saved_queues ORDER BY position ASC
    )", -1, &stmt.s, nullptr) != SQLITE_OK)
        return result;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        QueueSnapshot snap;
        int64_t queueId      = sqlite3_column_int64(stmt, 0);
        const char *name     = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
        snap.name            = name ? name : "";
        snap.currentTrackIndex = sqlite3_column_int(stmt, 2);
        snap.currentPosition = sqlite3_column_int64(stmt, 3);
        snap.wasPlaying      = sqlite3_column_int(stmt, 4) == 1;
        snap.isActive        = sqlite3_column_int(stmt, 5) == 1;

        Stmt tStmt;
        if (sqlite3_prepare_v2(m_db, R"(
            SELECT path FROM saved_queue_tracks
            WHERE queue_id = ? ORDER BY position ASC
        )", -1, &tStmt.s, nullptr) == SQLITE_OK) {
            sqlite3_bind_int64(tStmt, 1, queueId);
            while (sqlite3_step(tStmt) == SQLITE_ROW) {
                const char *p = reinterpret_cast<const char *>(
                    sqlite3_column_text(tStmt, 0));
                if (p) snap.paths.push_back(p);
            }
        }

        result.push_back(std::move(snap));
    }
    return result;
}

// ---------------------------------------------------------------------------
// Bulk operations
// ---------------------------------------------------------------------------

void Library::removeTracksFromFolder(const std::string &folderPath)
{
    std::vector<std::string> toRemove;
    {
        Stmt stmt;
        if (sqlite3_prepare_v2(m_db,
                "SELECT path FROM tracks WHERE path LIKE ?",
                -1, &stmt.s, nullptr) == SQLITE_OK) {
            std::string prefix = folderPath + "%";
            sqlite3_bind_text(stmt, 1, prefix.c_str(), -1, SQLITE_TRANSIENT);
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                const char *p = reinterpret_cast<const char *>(
                    sqlite3_column_text(stmt, 0));
                if (p) toRemove.push_back(p);
            }
        }
    }
    for (const auto &path : toRemove)
        removeTrack(path);
}

void Library::removeTrackIfMissing(const std::string &path)
{
    if (!std::filesystem::exists(path))
        removeTrack(path);
}