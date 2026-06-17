#include "library.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDateTime>
#include <QDebug>

Library::Library(QObject *parent)
    : QObject{parent}
{}

Library::~Library()
{
    if (m_db.isOpen())
        m_db.close();
}

bool Library::open()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);

    m_db = QSqlDatabase::addDatabase("QSQLITE", "natsuyume_library");
    m_db.setDatabaseName(dataPath + "/library.db");

    if (!m_db.open()) {
        qWarning() << "Library: failed to open database:" << m_db.lastError().text();
        qWarning() << "Library: database path:" << m_db.databaseName();
        return false;
    }

    createSchema();
    populateCache();
    return true;
}

void Library::createSchema()
{
    QSqlQuery q(m_db);

    // Enable WAL mode for better concurrent read performance
    q.exec("PRAGMA journal_mode=WAL");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS tracks (
            path            TEXT PRIMARY KEY,
            title           TEXT NOT NULL,
            artist          TEXT NOT NULL,
            album           TEXT NOT NULL,
            album_artist    TEXT NOT NULL DEFAULT '',
            composer        TEXT NOT NULL DEFAULT '',
            genre           TEXT NOT NULL DEFAULT '',
            track_number    INTEGER NOT NULL DEFAULT 0,
            disc_number     INTEGER NOT NULL DEFAULT 1,
            year            INTEGER NOT NULL DEFAULT 0,
            duration        INTEGER NOT NULL DEFAULT 0,
            date_added      INTEGER NOT NULL DEFAULT 0,
            date_last_played INTEGER NOT NULL DEFAULT 0,
            play_count      INTEGER NOT NULL DEFAULT 0
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlists (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name  TEXT NOT NULL UNIQUE
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlist_tracks (
            playlist_id  INTEGER NOT NULL,
            path         TEXT NOT NULL,
            position     INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, path),
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
        )
    )");

    q.exec("PRAGMA foreign_keys = ON");

    if (q.lastError().isValid())
        qWarning() << "Library: schema error:" << q.lastError().text();

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS saved_queues (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            name     TEXT NOT NULL,
            position INTEGER NOT NULL,
            track_index    INTEGER NOT NULL DEFAULT 0,
            track_position INTEGER NOT NULL DEFAULT 0,
            was_playing    INTEGER NOT NULL DEFAULT 0,
            is_active      INTEGER NOT NULL DEFAULT 0
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS saved_queue_tracks (
            queue_id INTEGER NOT NULL,
            path     TEXT NOT NULL,
            position INTEGER NOT NULL,
            FOREIGN KEY (queue_id) REFERENCES saved_queues(id) ON DELETE CASCADE
        )
    )");
}

void Library::populateCache()
{
    QSqlQuery q(m_db);
    q.exec("SELECT path FROM tracks");
    QWriteLocker locker(&m_cacheLock);
    while (q.next())
        m_pathCache.insert(q.value(0).toString());
}

void Library::addTrack(const Track &track)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT OR REPLACE INTO tracks (
            path, title, artist, album, album_artist,
            composer, genre, track_number, disc_number,
            year, duration, date_added, date_last_played, play_count
        ) VALUES (
            :path, :title, :artist, :album, :albumArtist,
            :composer, :genre, :trackNumber, :discNumber,
            :year, :duration, :dateAdded, :dateLastPlayed, :playCount
        )
    )");

    q.bindValue(":path",          track.path);
    q.bindValue(":title",         track.title);
    q.bindValue(":artist",        track.artist);
    q.bindValue(":album",         track.album);
    q.bindValue(":albumArtist",   track.albumArtist);
    q.bindValue(":composer",      track.composer);
    q.bindValue(":genre",         track.genre);
    q.bindValue(":trackNumber",   track.trackNumber);
    q.bindValue(":discNumber",    track.discNumber);
    q.bindValue(":year",          track.year);
    q.bindValue(":duration",      track.duration);
    q.bindValue(":dateAdded",     QDateTime::currentSecsSinceEpoch());
    q.bindValue(":dateLastPlayed", track.dateLastPlayed);
    q.bindValue(":playCount",     track.playCount);
    q.exec();

    if (q.lastError().isValid()) {
        qWarning() << "Library: addTrack error:" << q.lastError().text();
    } else {
        {
            QWriteLocker locker(&m_cacheLock);
            m_pathCache.insert(track.path);
        }
        emit libraryChanged();
    }
}

void Library::removeTrack(const QString &path)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM tracks WHERE path = :path");
    q.bindValue(":path", path);
    q.exec();
    {
        QWriteLocker locker(&m_cacheLock);
        m_pathCache.remove(path);
    }
    emit libraryChanged();
}

void Library::clear()
{
    QSqlQuery q(m_db);
    q.exec("DELETE FROM tracks");
    {
        QWriteLocker locker(&m_cacheLock);
        m_pathCache.clear();
    }
    emit libraryChanged();
}

// --- Internal helpers ---

QString Library::albumSortColumn(AlbumSort sort)
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

QString Library::trackSortColumn(TrackSort sort)
{
    switch (sort) {
    case TrackSort::TrackNumber:    return "disc_number, track_number";
    case TrackSort::Title:          return "title";
    case TrackSort::Artist:         return "artist";
    case TrackSort::AlbumArtist:    return "album_artist";
    case TrackSort::Year:           return "year";
    case TrackSort::Duration:       return "duration";
    case TrackSort::Genre:          return "genre";
    case TrackSort::Composer:       return "composer";
    case TrackSort::Filename:       return "path";
    case TrackSort::DateAdded:      return "date_added";
    case TrackSort::DateLastPlayed: return "date_last_played";
    case TrackSort::PlayCount:      return "play_count";
    }
    return "disc_number, track_number";
}

// --- Reading ---

static Track trackFromQuery(QSqlQuery &q)
{
    Track t(q.value(0).toString());
    t.title          = q.value(1).toString();
    t.artist         = q.value(2).toString();
    t.album          = q.value(3).toString();
    t.albumArtist    = q.value(4).toString();
    t.composer       = q.value(5).toString();
    t.genre          = q.value(6).toString();
    t.trackNumber    = q.value(7).toInt();
    t.discNumber     = q.value(8).toInt();
    t.year           = q.value(9).toInt();
    t.duration       = q.value(10).toLongLong();
    t.dateAdded      = q.value(11).toLongLong();
    t.dateLastPlayed = q.value(12).toLongLong();
    t.playCount      = q.value(13).toInt();
    return t;
}

QList<Track> Library::allTracks() const
{
    QList<Track> result;
    QSqlQuery q(m_db);
    q.exec(R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added, date_last_played, play_count
        FROM tracks ORDER BY title
    )");
    while (q.next())
        result.append(trackFromQuery(q));
    return result;
}

QStringList Library::allTrackPaths() const
{
    QStringList result;
    QSqlQuery q(m_db);
    q.exec("SELECT path FROM tracks");
    while (q.next())
        result.append(q.value(0).toString());
    return result;
}

Track Library::trackByPath(const QString &path) const
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added, date_last_played, play_count
        FROM tracks WHERE path = :path
    )");
    q.bindValue(":path", path);
    q.exec();
    if (q.next())
        return trackFromQuery(q);
    return Track();
}

QList<Track> Library::tracksByAlbum(const QString &album,
                                    TrackSort sort,
                                    bool ascending) const
{
    QList<Track> result;
    QSqlQuery q(m_db);

    QString sortCol = trackSortColumn(sort);
    QString dir     = ascending ? "ASC" : "DESC";

    q.prepare(QString(R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added, date_last_played, play_count
        FROM tracks
        WHERE album = :album
        ORDER BY %1 %2
    )").arg(sortCol, dir));

    q.bindValue(":album", album);
    q.exec();

    while (q.next())
        result.append(trackFromQuery(q));
    return result;
}

QList<Track> Library::tracksByArtist(const QString &artist) const
{
    QList<Track> result;
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT path, title, artist, album, album_artist,
               composer, genre, track_number, disc_number,
               year, duration, date_added, date_last_played, play_count
        FROM tracks
        WHERE artist = :artist
        ORDER BY disc_number, track_number
    )");
    q.bindValue(":artist", artist);
    q.exec();

    while (q.next())
        result.append(trackFromQuery(q));
    return result;
}

QStringList Library::allAlbums(AlbumSort sort, bool ascending) const
{
    QStringList result;
    QSqlQuery q(m_db);

    QString dir = ascending ? "ASC" : "DESC";
    QString sql;

    if (sort == AlbumSort::SongCount ||
        sort == AlbumSort::Duration  ||
        sort == AlbumSort::Year      ||
        sort == AlbumSort::DateAdded) {
        sql = QString(R"(
            SELECT album FROM tracks
            GROUP BY album
            ORDER BY %1 %2
        )").arg(albumSortColumn(sort), dir);
    } else {
        sql = QString(R"(
            SELECT album FROM tracks
            GROUP BY album
            ORDER BY %1 %2
        )").arg(albumSortColumn(sort), dir);
    }

    q.exec(sql);
    while (q.next())
        result.append(q.value(0).toString());
    return result;
}

QStringList Library::allArtists() const
{
    QStringList result;
    QSqlQuery q(m_db);
    q.exec("SELECT DISTINCT artist FROM tracks ORDER BY artist");
    while (q.next())
        result.append(q.value(0).toString());
    return result;
}

bool Library::containsPath(const QString &path) const
{
    QReadLocker locker(&m_cacheLock);
    return m_pathCache.contains(path);
}

// ── Playlist writing ───────────────────────────────────────────────────────

int Library::createPlaylist(const QString &name)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO playlists (name) VALUES (:name)");
    q.bindValue(":name", name);
    if (!q.exec()) {
        qWarning() << "Library: createPlaylist error:" << q.lastError().text();
        return -1;
    }
    emit playlistsChanged();
    return q.lastInsertId().toInt();
}

void Library::deletePlaylist(int playlistId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM playlists WHERE id = :id");
    q.bindValue(":id", playlistId);
    q.exec();
    emit playlistsChanged();
}

void Library::renamePlaylist(int playlistId, const QString &name)
{
    QSqlQuery q(m_db);
    q.prepare("UPDATE playlists SET name = :name WHERE id = :id");
    q.bindValue(":name", name);
    q.bindValue(":id",   playlistId);
    q.exec();
    emit playlistsChanged();
}

void Library::addTrackToPlaylist(int playlistId, const QString &path)
{
    QSqlQuery q(m_db);
    // Get current max position
    q.prepare("SELECT COALESCE(MAX(position), -1) FROM playlist_tracks WHERE playlist_id = :id");
    q.bindValue(":id", playlistId);
    q.exec();
    int nextPos = q.next() ? q.value(0).toInt() + 1 : 0;

    // INSERT OR IGNORE respects the PRIMARY KEY (playlist_id, path) — no duplicates
    q.prepare(R"(
        INSERT OR IGNORE INTO playlist_tracks (playlist_id, path, position)
        VALUES (:id, :path, :pos)
    )");
    q.bindValue(":id",   playlistId);
    q.bindValue(":path", path);
    q.bindValue(":pos",  nextPos);
    q.exec();
    emit playlistsChanged();
}

void Library::removeTrackFromPlaylist(int playlistId, const QString &path)
{
    QSqlQuery q(m_db);
    // Get position of the track being removed
    q.prepare("SELECT position FROM playlist_tracks WHERE playlist_id = :id AND path = :path");
    q.bindValue(":id",   playlistId);
    q.bindValue(":path", path);
    q.exec();
    if (!q.next()) return;
    int removedPos = q.value(0).toInt();

    // Delete it
    q.prepare("DELETE FROM playlist_tracks WHERE playlist_id = :id AND path = :path");
    q.bindValue(":id",   playlistId);
    q.bindValue(":path", path);
    q.exec();

    // Shift positions of tracks that came after it
    q.prepare(R"(
        UPDATE playlist_tracks
        SET position = position - 1
        WHERE playlist_id = :id AND position > :pos
    )");
    q.bindValue(":id",  playlistId);
    q.bindValue(":pos", removedPos);
    q.exec();
    emit playlistsChanged();
}

void Library::moveTrackInPlaylist(int playlistId, int from, int to)
{
    if (from == to) return;

    QSqlQuery q(m_db);

    // Use a temp position (-1) to avoid UNIQUE constraint conflicts during swap
    q.prepare(R"(
        UPDATE playlist_tracks SET position = -1
        WHERE playlist_id = :id AND position = :from
    )");
    q.bindValue(":id",   playlistId);
    q.bindValue(":from", from);
    q.exec();

    if (from < to) {
        // Shift everything between from+1 and to down by 1
        q.prepare(R"(
            UPDATE playlist_tracks SET position = position - 1
            WHERE playlist_id = :id AND position > :from AND position <= :to
        )");
    } else {
        // Shift everything between to and from-1 up by 1
        q.prepare(R"(
            UPDATE playlist_tracks SET position = position + 1
            WHERE playlist_id = :id AND position >= :to AND position < :from
        )");
    }
    q.bindValue(":id",   playlistId);
    q.bindValue(":from", from);
    q.bindValue(":to",   to);
    q.exec();

    // Place the moved track at its destination
    q.prepare(R"(
        UPDATE playlist_tracks SET position = :to
        WHERE playlist_id = :id AND position = -1
    )");
    q.bindValue(":id", playlistId);
    q.bindValue(":to", to);
    q.exec();

    emit playlistsChanged();
}

int Library::saveQueueAsPlaylist(const QString &name, const QStringList &paths)
{
    int id = createPlaylist(name);
    if (id < 0) return -1;

    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT OR IGNORE INTO playlist_tracks (playlist_id, path, position)
        VALUES (:id, :path, :pos)
    )");
    for (int i = 0; i < paths.size(); ++i) {
        q.bindValue(":id",   id);
        q.bindValue(":path", paths[i]);
        q.bindValue(":pos",  i);
        q.exec();
    }
    emit playlistsChanged();
    return id;
}

// ── Playlist reading ───────────────────────────────────────────────────────

QList<PlaylistInfo> Library::allPlaylists() const
{
    QList<PlaylistInfo> result;
    QSqlQuery q(m_db);
    q.exec("SELECT id, name FROM playlists ORDER BY name ASC");
    while (q.next())
        result.append({ q.value(0).toInt(), q.value(1).toString() });
    return result;
}

QList<Track> Library::tracksForPlaylist(int playlistId) const
{
    QList<Track> result;
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT t.path, t.title, t.artist, t.album, t.album_artist,
               t.composer, t.genre, t.track_number, t.disc_number,
               t.year, t.duration, t.date_added, t.date_last_played, t.play_count
        FROM playlist_tracks pt
        JOIN tracks t ON t.path = pt.path
        WHERE pt.playlist_id = :id
        ORDER BY pt.position ASC
    )");
    q.bindValue(":id", playlistId);
    q.exec();
    while (q.next())
        result.append(trackFromQuery(q));
    return result;
}

QStringList Library::albumsForArtist(const QString &artist) const
{
    QStringList result;
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT DISTINCT album FROM tracks
        WHERE artist = :artist
        ORDER BY album ASC
    )");
    q.bindValue(":artist", artist);
    q.exec();
    while (q.next())
        result.append(q.value(0).toString());
    return result;
}

void Library::sortPlaylist(int playlistId, TrackSort sort, bool ascending)
{
    // Fetch current tracks in requested sort order
    QString sortCol = trackSortColumn(sort);
    QString dir     = ascending ? "ASC" : "DESC";

    QSqlQuery q(m_db);
    q.prepare(QString(R"(
        SELECT pt.path FROM playlist_tracks pt
        JOIN tracks t ON t.path = pt.path
        WHERE pt.playlist_id = :id
        ORDER BY %1 %2
    )").arg(sortCol, dir));
    q.bindValue(":id", playlistId);
    q.exec();

    QStringList ordered;
    while (q.next())
        ordered << q.value(0).toString();

    // Rewrite positions
    QSqlQuery upd(m_db);
    upd.prepare(R"(
        UPDATE playlist_tracks SET position = :pos
        WHERE playlist_id = :id AND path = :path
    )");
    for (int i = 0; i < ordered.size(); ++i) {
        upd.bindValue(":pos",  i);
        upd.bindValue(":id",   playlistId);
        upd.bindValue(":path", ordered[i]);
        upd.exec();
    }
    emit playlistsChanged();
}

void Library::incrementPlayCount(const QString &path)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        UPDATE tracks
        SET play_count      = play_count + 1,
            date_last_played = :now
        WHERE path = :path
    )");
    q.bindValue(":now",  QDateTime::currentSecsSinceEpoch());
    q.bindValue(":path", path);
    q.exec();

    if (q.lastError().isValid())
        qWarning() << "Library: incrementPlayCount error:" << q.lastError().text();
}

void Library::saveQueues(const QList<QueueSnapshot> &queues)
{
    QSqlQuery q(m_db);

    // Clear existing saved queues — CASCADE deletes tracks too
    q.exec("DELETE FROM saved_queues");

    for (int i = 0; i < queues.size(); ++i) {
        const QueueSnapshot &snap = queues[i];

        q.prepare(R"(
            INSERT INTO saved_queues
                (name, position, track_index, track_position, was_playing, is_active)
            VALUES
                (:name, :pos, :trackIndex, :trackPos, :wasPlaying, :isActive)
        )");
        q.bindValue(":name",       snap.name);
        q.bindValue(":pos",        i);
        q.bindValue(":trackIndex", snap.currentTrackIndex);
        q.bindValue(":trackPos",   snap.currentPosition);
        q.bindValue(":wasPlaying", snap.wasPlaying ? 1 : 0);
        q.bindValue(":isActive",   snap.isActive   ? 1 : 0);
        q.exec();

        int queueId = q.lastInsertId().toInt();

        q.prepare(R"(
            INSERT INTO saved_queue_tracks (queue_id, path, position)
            VALUES (:queueId, :path, :pos)
        )");
        for (int j = 0; j < snap.paths.size(); ++j) {
            q.bindValue(":queueId", queueId);
            q.bindValue(":path",    snap.paths[j]);
            q.bindValue(":pos",     j);
            q.exec();
        }
    }
}

QList<QueueSnapshot> Library::loadQueues() const
{
    QList<QueueSnapshot> result;
    QSqlQuery q(m_db);

    q.exec("SELECT id, name, track_index, track_position, was_playing, is_active FROM saved_queues ORDER BY position ASC");

    while (q.next()) {
        QueueSnapshot snap;
        int queueId          = q.value(0).toInt();
        snap.name            = q.value(1).toString();
        snap.currentTrackIndex = q.value(2).toInt();
        snap.currentPosition = q.value(3).toLongLong();
        snap.wasPlaying      = q.value(4).toInt() == 1;
        snap.isActive        = q.value(5).toInt() == 1;

        QSqlQuery tq(m_db);
        tq.prepare("SELECT path FROM saved_queue_tracks WHERE queue_id = :id ORDER BY position ASC");
        tq.bindValue(":id", queueId);
        tq.exec();
        while (tq.next())
            snap.paths << tq.value(0).toString();

        result.append(snap);
    }

    return result;
}

void Library::removeTracksFromFolder(const QString &folderPath)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT path FROM tracks WHERE path LIKE :prefix");
    q.bindValue(":prefix", folderPath + "%");
    q.exec();

    QStringList toRemove;
    while (q.next())
        toRemove << q.value(0).toString();

    for (const QString &path : toRemove)
        removeTrack(path);
}

void Library::removeTrackIfMissing(const QString &path)
{
    if (!QFile::exists(path))
        removeTrack(path);
}