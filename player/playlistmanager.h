#ifndef PLAYLISTMANAGER_H
#define PLAYLISTMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QStringList>
#include "queuesession.h"
#include "library.h"

class PlaylistManager : public QObject
{
    Q_OBJECT

public:
    explicit PlaylistManager(QueueSession *session, QObject *parent = nullptr);

    void setLibrary(Library *library);

    // --- Playlists ---
    QVariantList allPlaylists()                                        const;
    int          createPlaylist(const QString &name);
    void         deletePlaylist(int playlistId);
    void         renamePlaylist(int playlistId, const QString &name);
    void         addTrackToPlaylist(int playlistId, const QString &path);
    void         removeTrackFromPlaylist(int playlistId, const QString &path);
    void         moveTrackInPlaylist(int playlistId, int from, int to);
    void         sortPlaylist(int playlistId);
    int          saveQueueAsPlaylist(const QString &name);
    QVariantList tracksForPlaylist(int playlistId)                     const;
    void         openPlaylistInNewQueue(int playlistId, const QString &name);

    // --- Playlist sort ---
    int  playlistSort()                        const;
    bool playlistSortAscending()               const;
    void setPlaylistSort(int sort);
    void setPlaylistSortAscending(bool ascending);

    // --- Favorites ---
    bool isFavorite(const QString &path)       const;
    void toggleFavorite(const QString &path);

    // --- Settings ---
    void loadSettings();
    void saveSettings();

    // --- Constants ---
    static constexpr int kAllSongsPlaylistId  = -2;
    static constexpr int kFavoritesPlaylistId = -3;

    // --- Request signals (relayed to QML via PlayerController) ---
    void requestAddToPlaylist(const QString &path);
    void requestAddAlbumToPlaylist(const QString &albumName);

signals:
    void playlistsChanged();
    void playlistSortChanged();
    void isFavoriteChanged();
    void addToPlaylistRequested(const QString &path);
    void addAlbumToPlaylistRequested(const QString &albumName);
    void openInNewQueueRequested(const QStringList &paths, const QString &name);

private:
    QueueSession       *m_session;
    Library            *m_library = nullptr;

    QStringList            m_favorites;
    Library::TrackSort     m_playlistSort          = Library::TrackSort::TrackNumber;
    bool                   m_playlistSortAscending = true;
};

#endif // PLAYLISTMANAGER_H