#ifndef LIBRARY_H
#define LIBRARY_H
#include <QObject>
#include <QList>
#include <QString>
#include <QReadWriteLock>
#include <QSqlDatabase>
#include "track.h"

struct QueueSnapshot {
    QString     name;
    QStringList paths;
    int         currentTrackIndex = 0;
    qint64      currentPosition   = 0;
    bool        wasPlaying        = false;
    bool        isActive          = false;
};

class Library : public QObject
{
    Q_OBJECT
public:
    // --- Album sort options ---
    enum class AlbumSort {
        Name, Artist, AlbumArtist, Year, SongCount, Duration, Composer, DateAdded
    };

    // --- Artist sort options ---
    enum class ArtistSort {
        Name, SongCount, Duration, DateAdded
    };

    // --- Track sort options ---
    enum class TrackSort {
        TrackNumber, Title, Artist, AlbumArtist, Year, Duration, Genre,
        Composer, Filename, DateAdded, DateLastPlayed, PlayCount
    };

    explicit Library(QObject *parent = nullptr);
    ~Library();

    // --- Setup ---
    bool open();

    // --- Track writing ---
    void addTrack(const Track &track);
    void removeTrack(const QString &path);
    void clear();

    // --- Track reading ---
    QList<Track> allTracks() const;
    QStringList  allTrackPaths() const;
    Track        trackByPath(const QString &path) const;
    QList<Track> tracksByAlbum(const QString &album,
                               TrackSort sort = TrackSort::TrackNumber,
                               bool ascending = true) const;
    QList<Track> tracksByArtist(const QString &artist) const;
    QStringList  allAlbums(AlbumSort sort = AlbumSort::Name,
                          bool ascending = true) const;
    QStringList  allArtists() const;
    QStringList  allArtists(ArtistSort sort, bool ascending) const;
    bool         containsPath(const QString &path) const;
    QStringList  albumsForArtist(const QString &artist) const;
    qint64 lastModifiedFor(const QString &path) const;

    // --- Queue persistence ---
    void saveQueues(const QList<QueueSnapshot> &queues);
    QList<QueueSnapshot> loadQueues() const;

    void removeTracksFromFolder(const QString &folderPath);
    void removeTrackIfMissing(const QString &path);
    void addTracks(const QList<Track> &tracks);

signals:
    void libraryChanged();

private:
    QSqlDatabase   m_db;
    QHash<QString, qint64> m_pathCache; // path → last_modified
    mutable QReadWriteLock m_cacheLock;

    void createSchema();
    void populateCache();
    static QString albumSortColumn(AlbumSort sort);
    static QString trackSortColumn(TrackSort sort);
};
#endif // LIBRARY_H