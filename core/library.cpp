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

    if (q.lastError().isValid())
        qWarning() << "Library: schema error:" << q.lastError().text();
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