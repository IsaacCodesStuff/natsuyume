#ifndef USERDATA_H
#define USERDATA_H

#include <QObject>
#include <QSqlDatabase>
#include <QSet>
#include "track.h"
#include "library.h"

struct PlaylistInfo {
    int     id;
    QString name;
    QString imagePath;
};

class UserData : public QObject
{
    Q_OBJECT
public:
    explicit UserData(QObject *parent = nullptr);
    ~UserData();

    bool open();

    // --- Favorites ---
    void          setFavorite(const QString &path, bool favorite);
    bool          isFavorite(const QString &path) const;
    QSet<QString> allFavoritePaths() const;

    // --- Play stats ---
    void   incrementPlayCount(const QString &path);
    int    playCount(const QString &path) const;
    qint64 dateLastPlayed(const QString &path) const;

    // --- Merging stats into Track objects ---
    void applyUserData(Track &track) const;
    void applyUserData(QList<Track> &tracks) const;

    // --- Playlists ---
    int  createPlaylist(const QString &name);
    void deletePlaylist(int playlistId);
    void renamePlaylist(int playlistId, const QString &name);
    void setPlaylistImage(int playlistId, const QString &imagePath);
    void addTrackToPlaylist(int playlistId, const QString &path);
    void removeTrackFromPlaylist(int playlistId, const QString &path);
    void moveTrackInPlaylist(int playlistId, int from, int to);
    void sortPlaylist(int playlistId, Library::TrackSort sort, bool ascending);
    int  saveQueueAsPlaylist(const QString &name, const QStringList &paths);

    QList<PlaylistInfo> allPlaylists() const;
    QStringList         playlistTrackPaths(int playlistId) const;

    // --- Artist images ---
    void    setArtistImage(const QString &artist, const QString &imagePath);
    QString artistImage(const QString &artist) const;

    // --- Nuclear reset ---
    void clearAll();

    QSqlDatabase db() const { return m_db; }

signals:
    void playlistsChanged();
    void favoritesChanged();
    void statsChanged();

private:
    QSqlDatabase m_db;
    void createSchema();
};

#endif // USERDATA_H