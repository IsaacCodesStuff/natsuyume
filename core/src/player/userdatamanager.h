#ifndef USERDATAMANAGER_H
#define USERDATAMANAGER_H

#include <QObject>
#include <QSet>
#include <QVariantList>
#include "userdata.h"
#include "library.h"

class UserDataManager : public QObject
{
    Q_OBJECT
public:
    explicit UserDataManager(QObject *parent = nullptr);

    bool open();
    void setLibrary(Library *library);

    // --- Favorites ---
    bool          isFavorite(const QString &path) const;
    void          toggleFavorite(const QString &path);
    QSet<QString> allFavoritePaths() const;

    // --- Play stats ---
    void incrementPlayCount(const QString &path);
    void applyUserData(Track &track) const;
    void applyUserData(QList<Track> &tracks) const;

    // --- Playlists ---
    QVariantList allPlaylists()                                         const;
    int          createPlaylist(const QString &name);
    void         deletePlaylist(int playlistId);
    void         renamePlaylist(int playlistId, const QString &name);
    void         setPlaylistImage(int playlistId, const QString &imagePath);
    void         addTrackToPlaylist(int playlistId, const QString &path);
    void         removeTrackFromPlaylist(int playlistId, const QString &path);
    void         moveTrackInPlaylist(int playlistId, int from, int to);
    void         sortPlaylist(int playlistId);
    int          saveQueueAsPlaylist(const QString &name,
                            const QStringList &paths);
    QList<Track> tracksForPlaylist(int playlistId)                      const;
    void         openPlaylistInNewQueue(int playlistId, const QString &name);

    // --- Playlist sort ---
    int  playlistSort()              const;
    bool playlistSortAscending()     const;
    void setPlaylistSort(int sort);
    void setPlaylistSortAscending(bool ascending);

    // --- Artist images ---
    void    setArtistImage(const QString &artist, const QString &imagePath);
    QString artistImage(const QString &artist) const;

    // --- Clear operations ---
    void clearUserData();   // wipes userdata.db — favorites, playlists, stats
    void clearLibrary();    // tells Library to clear tracks only

    // --- Settings ---
    void loadSettings();
    void saveSettings();

    // --- Constants ---
    static constexpr int kAllSongsPlaylistId  = -2;
    static constexpr int kFavoritesPlaylistId = -3;

    // --- Request relay (mirrors old PlaylistManager pattern) ---
    void requestAddToPlaylist(const QString &path);
    void requestAddAlbumToPlaylist(const QString &albumName);
    QList<PlaylistInfo> rawPlaylists() const;

signals:
    void playlistsChanged();
    void playlistSortChanged();
    void isFavoriteChanged();
    void addToPlaylistRequested(const QString &path);
    void addAlbumToPlaylistRequested(const QString &albumName);
    void openInNewQueueRequested(const QStringList &paths, const QString &name);

private:
    UserData *m_userData = nullptr;
    Library  *m_library  = nullptr;

    Library::TrackSort m_playlistSort          = Library::TrackSort::TrackNumber;
    bool               m_playlistSortAscending = true;
};

#endif // USERDATAMANAGER_H