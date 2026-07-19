#include "userdata.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QDebug>

UserData::UserData(QObject *parent)
    : QObject(parent)
{}

UserData::~UserData()
{
    if (m_db.isOpen())
        m_db.close();
}

bool UserData::open()
{
    QString dataPath = QStandardPaths::writableLocation(
        QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);

    m_db = QSqlDatabase::addDatabase("QSQLITE", "natsuyume_userdata");
    m_db.setDatabaseName(dataPath + "/userdata.db");

    if (!m_db.open()) {
        qWarning() << "UserData: failed to open database:" << m_db.lastError().text();
        return false;
    }

    createSchema();
    return true;
}

void UserData::createSchema()
{
    QSqlQuery q(m_db);
    q.exec("PRAGMA journal_mode=WAL");
    q.exec("PRAGMA foreign_keys = ON");

    // Per-track user data — keyed by path, independent of library.db
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS user_track_data (
            path             TEXT PRIMARY KEY,
            play_count       INTEGER NOT NULL DEFAULT 0,
            date_last_played INTEGER NOT NULL DEFAULT 0,
            is_favorite      INTEGER NOT NULL DEFAULT 0
        )
    )");

    // Favorited paths not in the library (moved/deleted tracks)
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS favorite_paths (
            path TEXT PRIMARY KEY
        )
    )");

    // Playlists with optional user-supplied image
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlists (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT NOT NULL UNIQUE,
            image_path TEXT NOT NULL DEFAULT ''
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlist_tracks (
            playlist_id INTEGER NOT NULL,
            path        TEXT NOT NULL,
            position    INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, path),
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
        )
    )");

    // Per-artist user-supplied image
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS artist_images (
            artist     TEXT PRIMARY KEY,
            image_path TEXT NOT NULL DEFAULT ''
        )
    )");

    if (q.lastError().isValid())
        qWarning() << "UserData: schema error:" << q.lastError().text();
}

// --- Favorites ---

void UserData::setFavorite(const QString &path, bool favorite)
{
    // Ensure row exists in user_track_data
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT OR IGNORE INTO user_track_data (path) VALUES (:path)
    )");
    q.bindValue(":path", path);
    q.exec();

    q.prepare(R"(
        UPDATE user_track_data SET is_favorite = :fav WHERE path = :path
    )");
    q.bindValue(":fav",  favorite ? 1 : 0);
    q.bindValue(":path", path);
    q.exec();

    // Also maintain favorite_paths for tracks not in the library
    if (favorite) {
        q.prepare("INSERT OR IGNORE INTO favorite_paths (path) VALUES (:path)");
    } else {
        q.prepare("DELETE FROM favorite_paths WHERE path = :path");
    }
    q.bindValue(":path", path);
    q.exec();

    emit favoritesChanged();
}

bool UserData::isFavorite(const QString &path) const
{
    QSqlQuery q(m_db);
    q.prepare("SELECT is_favorite FROM user_track_data WHERE path = :path");
    q.bindValue(":path", path);
    q.exec();
    if (q.next()) return q.value(0).toInt() == 1;
    return false;
}

QSet<QString> UserData::allFavoritePaths() const
{
    QSet<QString> result;
    QSqlQuery q(m_db);
    q.exec("SELECT path FROM user_track_data WHERE is_favorite = 1");
    while (q.next()) result.insert(q.value(0).toString());
    q.exec("SELECT path FROM favorite_paths");
    while (q.next()) result.insert(q.value(0).toString());
    return result;
}

// --- Play stats ---

void UserData::incrementPlayCount(const QString &path)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT OR IGNORE INTO user_track_data (path) VALUES (:path)");
    q.bindValue(":path", path);
    q.exec();

    q.prepare(R"(
        UPDATE user_track_data
        SET play_count       = play_count + 1,
            date_last_played = :now
        WHERE path = :path
    )");
    q.bindValue(":now",  QDateTime::currentSecsSinceEpoch());
    q.bindValue(":path", path);
    q.exec();

    emit statsChanged();
}

int UserData::playCount(const QString &path) const
{
    QSqlQuery q(m_db);
    q.prepare("SELECT play_count FROM user_track_data WHERE path = :path");
    q.bindValue(":path", path);
    q.exec();
    return q.next() ? q.value(0).toInt() : 0;
}

qint64 UserData::dateLastPlayed(const QString &path) const
{
    QSqlQuery q(m_db);
    q.prepare("SELECT date_last_played FROM user_track_data WHERE path = :path");
    q.bindValue(":path", path);
    q.exec();
    return q.next() ? q.value(0).toLongLong() : 0;
}

// --- Merging ---

void UserData::applyUserData(Track &track) const
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT play_count, date_last_played, is_favorite
        FROM user_track_data WHERE path = :path
    )");
    q.bindValue(":path", track.path);
    q.exec();
    if (q.next()) {
        track.playCount      = q.value(0).toInt();
        track.dateLastPlayed = q.value(1).toLongLong();
        track.isFavorite     = q.value(2).toInt() == 1;
    }
}

void UserData::applyUserData(QList<Track> &tracks) const
{
    for (Track &t : tracks)
        applyUserData(t);
}

// --- Playlists ---

int UserData::createPlaylist(const QString &name)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO playlists (name) VALUES (:name)");
    q.bindValue(":name", name);
    if (!q.exec()) {
        qWarning() << "UserData: createPlaylist error:" << q.lastError().text();
        return -1;
    }
    emit playlistsChanged();
    return q.lastInsertId().toInt();
}

void UserData::deletePlaylist(int playlistId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM playlists WHERE id = :id");
    q.bindValue(":id", playlistId);
    q.exec();
    emit playlistsChanged();
}

void UserData::renamePlaylist(int playlistId, const QString &name)
{
    QSqlQuery q(m_db);
    q.prepare("UPDATE playlists SET name = :name WHERE id = :id");
    q.bindValue(":name", name);
    q.bindValue(":id",   playlistId);
    q.exec();
    emit playlistsChanged();
}

void UserData::setPlaylistImage(int playlistId, const QString &imagePath)
{
    QSqlQuery q(m_db);
    q.prepare("UPDATE playlists SET image_path = :img WHERE id = :id");
    q.bindValue(":img", imagePath);
    q.bindValue(":id",  playlistId);
    q.exec();
    emit playlistsChanged();
}

void UserData::addTrackToPlaylist(int playlistId, const QString &path)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT COALESCE(MAX(position), -1)
        FROM playlist_tracks WHERE playlist_id = :id
    )");
    q.bindValue(":id", playlistId);
    q.exec();
    int nextPos = q.next() ? q.value(0).toInt() + 1 : 0;

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

void UserData::removeTrackFromPlaylist(int playlistId, const QString &path)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT position FROM playlist_tracks
        WHERE playlist_id = :id AND path = :path
    )");
    q.bindValue(":id",   playlistId);
    q.bindValue(":path", path);
    q.exec();
    if (!q.next()) return;
    int removedPos = q.value(0).toInt();

    q.prepare(R"(
        DELETE FROM playlist_tracks
        WHERE playlist_id = :id AND path = :path
    )");
    q.bindValue(":id",   playlistId);
    q.bindValue(":path", path);
    q.exec();

    q.prepare(R"(
        UPDATE playlist_tracks SET position = position - 1
        WHERE playlist_id = :id AND position > :pos
    )");
    q.bindValue(":id",  playlistId);
    q.bindValue(":pos", removedPos);
    q.exec();
    emit playlistsChanged();
}

void UserData::moveTrackInPlaylist(int playlistId, int from, int to)
{
    if (from == to) return;
    QSqlQuery q(m_db);

    q.prepare(R"(
        UPDATE playlist_tracks SET position = -1
        WHERE playlist_id = :id AND position = :from
    )");
    q.bindValue(":id",   playlistId);
    q.bindValue(":from", from);
    q.exec();

    if (from < to) {
        q.prepare(R"(
            UPDATE playlist_tracks SET position = position - 1
            WHERE playlist_id = :id AND position > :from AND position <= :to
        )");
    } else {
        q.prepare(R"(
            UPDATE playlist_tracks SET position = position + 1
            WHERE playlist_id = :id AND position >= :to AND position < :from
        )");
    }
    q.bindValue(":id",   playlistId);
    q.bindValue(":from", from);
    q.bindValue(":to",   to);
    q.exec();

    q.prepare(R"(
        UPDATE playlist_tracks SET position = :to
        WHERE playlist_id = :id AND position = -1
    )");
    q.bindValue(":id", playlistId);
    q.bindValue(":to", to);
    q.exec();
    emit playlistsChanged();
}

void UserData::sortPlaylist(int playlistId,
                            Library::TrackSort sort, bool ascending)
{
    // Fetch ordered paths from library.db via a cross-db query is not
    // possible here — caller must supply sorted paths instead.
    // This is handled by UserDataManager::sortPlaylist.
    Q_UNUSED(playlistId); Q_UNUSED(sort); Q_UNUSED(ascending);
    qWarning() << "UserData::sortPlaylist: call UserDataManager::sortPlaylist instead";
}

int UserData::saveQueueAsPlaylist(const QString &name, const QStringList &paths)
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

QList<PlaylistInfo> UserData::allPlaylists() const
{
    QList<PlaylistInfo> result;
    QSqlQuery q(m_db);
    q.exec("SELECT id, name, image_path FROM playlists ORDER BY name ASC");
    while (q.next()) {
        PlaylistInfo info;
        info.id        = q.value(0).toInt();
        info.name      = q.value(1).toString();
        info.imagePath = q.value(2).toString();
        result.append(info);
    }
    return result;
}

QStringList UserData::playlistTrackPaths(int playlistId) const
{
    QStringList result;
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT path FROM playlist_tracks
        WHERE playlist_id = :id ORDER BY position ASC
    )");
    q.bindValue(":id", playlistId);
    q.exec();
    while (q.next()) result.append(q.value(0).toString());
    return result;
}

// --- Artist images ---

void UserData::setArtistImage(const QString &artist, const QString &imagePath)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO artist_images (artist, image_path)
        VALUES (:artist, :img)
        ON CONFLICT(artist) DO UPDATE SET image_path = :img
    )");
    q.bindValue(":artist", artist);
    q.bindValue(":img",    imagePath);
    q.exec();
}

QString UserData::artistImage(const QString &artist) const
{
    QSqlQuery q(m_db);
    q.prepare("SELECT image_path FROM artist_images WHERE artist = :artist");
    q.bindValue(":artist", artist);
    q.exec();
    return q.next() ? q.value(0).toString() : QString();
}

// --- Nuclear reset ---

void UserData::clearAll()
{
    QSqlQuery q(m_db);
    q.exec("DELETE FROM user_track_data");
    q.exec("DELETE FROM favorite_paths");
    q.exec("DELETE FROM playlists");
    q.exec("DELETE FROM artist_images");
    emit playlistsChanged();
    emit favoritesChanged();
    emit statsChanged();
}