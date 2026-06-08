#ifndef LIBRARY_H
#define LIBRARY_H

#include <QObject>
#include <QList>
#include <QString>
#include <QSet>
#include <QReadWriteLock>
#include <QSqlDatabase>
#include "track.h"

class Library : public QObject
{
    Q_OBJECT

public:
    // --- Album sort options ---
    enum class AlbumSort {
        Name,
        Artist,
        AlbumArtist,
        Year,
        SongCount,
        Duration,
        Composer,
        DateAdded
    };

    // --- Track sort options ---
    enum class TrackSort {
        TrackNumber,
        Title,
        Artist,
        AlbumArtist,
        Year,
        Duration,
        Genre,
        Composer,
        Filename,
        DateAdded,
        DateLastPlayed,
        PlayCount
    };

    explicit Library(QObject *parent = nullptr);
    ~Library();

    // --- Setup ---
    bool open();

    // --- Writing ---
    void addTrack(const Track &track);
    void removeTrack(const QString &path);
    void clear();

    // --- Reading ---
    QList<Track> allTracks() const;
    QList<Track> tracksByAlbum(const QString &album,
                               TrackSort sort = TrackSort::TrackNumber,
                               bool ascending = true) const;
    QList<Track> tracksByArtist(const QString &artist) const;
    QStringList  allAlbums(AlbumSort sort = AlbumSort::Name,
                          bool ascending = true) const;
    QStringList  allArtists() const;
    bool         containsPath(const QString &path) const;

signals:
    void libraryChanged();

private:
    QSqlDatabase   m_db;
    QSet<QString>  m_pathCache;
    mutable QReadWriteLock m_cacheLock;

    void createSchema();
    void populateCache();

    static QString albumSortColumn(AlbumSort sort);
    static QString trackSortColumn(TrackSort sort);
};

#endif // LIBRARY_H