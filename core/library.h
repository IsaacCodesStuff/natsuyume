#ifndef LIBRARY_H
#define LIBRARY_H
#include <QObject>
#include <QList>
#include <QString>
#include <QSet>
#include <QReadWriteLock>
#include <QSqlDatabase>
#include "track.h"

struct PlaylistInfo {
    int     id;
    QString name;
};

class Library : public QObject
{
    Q_OBJECT
public:
    // --- Album sort options ---
    enum class AlbumSort {
        Name, Artist, AlbumArtist, Year, SongCount, Duration, Composer, DateAdded
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
    QList<Track> tracksByAlbum(const QString &album,
                               TrackSort sort = TrackSort::TrackNumber,
                               bool ascending = true) const;
    QList<Track> tracksByArtist(const QString &artist) const;
    QStringList  allAlbums(AlbumSort sort = AlbumSort::Name,
                          bool ascending = true) const;
    QStringList  allArtists() const;
    bool         containsPath(const QString &path) const;
    QStringList  albumsForArtist(const QString &artist) const;

    // --- Playlist writing ---
    int  createPlaylist(const QString &name);           // returns new id, -1 on error
    void deletePlaylist(int playlistId);
    void renamePlaylist(int playlistId, const QString &name);
    void addTrackToPlaylist(int playlistId, const QString &path);
    void removeTrackFromPlaylist(int playlistId, const QString &path);
    void moveTrackInPlaylist(int playlistId, int from, int to);
    int  saveQueueAsPlaylist(const QString &name, const QStringList &paths); // returns id
    void sortPlaylist(int playlistId, TrackSort sort, bool ascending);

    // --- Playlist reading ---
    QList<PlaylistInfo> allPlaylists() const;
    QList<Track>        tracksForPlaylist(int playlistId) const;

    void incrementPlayCount(const QString &path);

signals:
    void libraryChanged();
    void playlistsChanged();

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