#ifndef PLAYERCONTROLLER_H
#define PLAYERCONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <QStringList>
#include <QtQml/qqml.h>
#include "queuesession.h"
#include "queuemanager.h"
#include "playbackmanager.h"
#include "playlistmanager.h"
#include "librarymanager.h"
#include "coverimageprovider.h"
#include "albumcoverprovider.h"

class PlayerController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // --- Playback ---
    Q_PROPERTY(bool   isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(qint64 position  READ position  NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration  READ duration  NOTIFY durationChanged)
    Q_PROPERTY(float  volume    READ volume    WRITE setVolume NOTIFY volumeChanged)

    // --- Metadata ---
    Q_PROPERTY(QString trackTitle  READ trackTitle  NOTIFY metadataChanged)
    Q_PROPERTY(QString trackArtist READ trackArtist NOTIFY metadataChanged)
    Q_PROPERTY(QString trackAlbum  READ trackAlbum  NOTIFY metadataChanged)
    Q_PROPERTY(QString trackPath   READ trackPath   NOTIFY metadataChanged)
    Q_PROPERTY(bool    hasCoverArt READ hasCoverArt NOTIFY metadataChanged)

    // --- Lyrics ---
    Q_PROPERTY(QString      rawLyrics      READ rawLyrics      NOTIFY metadataChanged)
    Q_PROPERTY(QVariantList lyricLines     READ lyricLines     NOTIFY metadataChanged)
    Q_PROPERTY(bool         lyricsAreSynced READ lyricsAreSynced NOTIFY metadataChanged)

    // --- Playing-queue track navigation ---
    Q_PROPERTY(int  playingTrackIndex READ playingTrackIndex NOTIFY playingTrackChanged)
    Q_PROPERTY(int  playingTrackCount READ playingTrackCount NOTIFY playingTrackChanged)
    Q_PROPERTY(bool hasPrevious       READ hasPrevious       NOTIFY playingTrackChanged)
    Q_PROPERTY(bool hasNext           READ hasNext           NOTIFY playingTrackChanged)

    // --- Viewed-queue track navigation ---
    Q_PROPERTY(int viewedTrackIndex READ viewedTrackIndex NOTIFY trackChanged)
    Q_PROPERTY(int viewedTrackCount READ viewedTrackCount NOTIFY trackChanged)

    // --- Multi-queue ---
    Q_PROPERTY(int         queueCount        READ queueCount        NOTIFY queuesChanged)
    Q_PROPERTY(int         activeQueueIndex  READ activeQueueIndex  NOTIFY queuesChanged)
    Q_PROPERTY(int         playingQueueIndex READ playingQueueIndex NOTIFY queuesChanged)
    Q_PROPERTY(QStringList queueNames        READ queueNames        NOTIFY queuesChanged)

    // --- Repeat / shuffle ---
    Q_PROPERTY(int  repeatMode READ repeatMode NOTIFY repeatModeChanged)
    Q_PROPERTY(bool isShuffled READ isShuffled NOTIFY shuffleChanged)

    // --- Favorites ---
    Q_PROPERTY(bool isFavorite READ isFavorite NOTIFY isFavoriteChanged)

    // --- Track list ---
    Q_PROPERTY(QVariantList trackList READ trackList NOTIFY trackChanged)

    // --- Library ---
    Q_PROPERTY(QStringList allAlbums     READ allAlbums     NOTIFY libraryChanged)
    Q_PROPERTY(QStringList allArtists    READ allArtists    NOTIFY libraryChanged)
    Q_PROPERTY(bool        isScanning    READ isScanning    NOTIFY scanningChanged)
    Q_PROPERTY(int         scanProgress  READ scanProgress  NOTIFY scanProgressChanged)
    Q_PROPERTY(int         scanTotal     READ scanTotal     NOTIFY scanProgressChanged)
    Q_PROPERTY(QString     scanningFile  READ scanningFile  NOTIFY scanProgressChanged)

    // --- Sort ---
    Q_PROPERTY(int  albumSort          READ albumSort          WRITE setAlbumSort          NOTIFY albumSortChanged)
    Q_PROPERTY(bool albumSortAscending READ albumSortAscending WRITE setAlbumSortAscending NOTIFY albumSortChanged)
    Q_PROPERTY(int  trackSort          READ trackSort          WRITE setTrackSort          NOTIFY trackSortChanged)
    Q_PROPERTY(bool trackSortAscending READ trackSortAscending WRITE setTrackSortAscending NOTIFY trackSortChanged)
    Q_PROPERTY(int  playlistSort          READ playlistSort          WRITE setPlaylistSort          NOTIFY playlistSortChanged)
    Q_PROPERTY(bool playlistSortAscending READ playlistSortAscending WRITE setPlaylistSortAscending NOTIFY playlistSortChanged)

    // --- Settings ---
    Q_PROPERTY(QStringList scanFolders        READ scanFolders        NOTIFY scanFoldersChanged)
    Q_PROPERTY(int         playCountThreshold READ playCountThreshold
                   WRITE setPlayCountThreshold NOTIFY playCountThresholdChanged)
    Q_PROPERTY(bool stopAfterCurrent READ stopAfterCurrent NOTIFY stopAfterCurrentChanged)

    // --- Queue duration ---
    Q_PROPERTY(qint64 queueTotalDuration READ queueTotalDuration NOTIFY trackChanged)

    // --- Playlists ---
    Q_PROPERTY(QVariantList allPlaylists READ allPlaylists NOTIFY playlistsChanged)

public:
    explicit PlayerController(QObject *parent = nullptr);

    // --- Setup ---
    void setCoverImageProvider(CoverImageProvider *provider);
    void setAlbumCoverProvider(AlbumCoverProvider *provider);

    // --- Playback ---
    bool   isPlaying() const;
    qint64 position()  const;
    qint64 duration()  const;
    float  volume()    const;

    // --- Metadata ---
    QString trackTitle()  const;
    QString trackArtist() const;
    QString trackAlbum()  const;
    QString trackPath()   const;
    bool    hasCoverArt() const;

    // --- Lyrics ---
    QString      rawLyrics()      const;
    QVariantList lyricLines()     const;
    bool         lyricsAreSynced() const;

    // --- Playing-queue track navigation ---
    int  playingTrackIndex() const;
    int  playingTrackCount() const;
    bool hasPrevious()       const;
    bool hasNext()           const;

    // --- Viewed-queue track navigation ---
    int viewedTrackIndex() const;
    int viewedTrackCount() const;

    // --- Multi-queue ---
    int         queueCount()        const;
    int         activeQueueIndex()  const;
    int         playingQueueIndex() const;
    QStringList queueNames()        const;

    // --- Repeat / shuffle ---
    int  repeatMode() const;
    bool isShuffled() const;

    // --- Favorites ---
    bool isFavorite() const;

    // --- Track list ---
    QVariantList trackList() const;

    // --- Library ---
    QStringList allAlbums()    const;
    QStringList allArtists()   const;
    bool        isScanning()   const;
    int         scanProgress() const;
    int         scanTotal()    const;
    QString     scanningFile() const;

    // --- Sort ---
    int  albumSort()              const;
    bool albumSortAscending()     const;
    int  trackSort()              const;
    bool trackSortAscending()     const;
    int  playlistSort()           const;
    bool playlistSortAscending()  const;

    // --- Settings ---
    QStringList scanFolders()        const;
    int         playCountThreshold() const;
    bool        stopAfterCurrent()   const;
    qint64      queueTotalDuration() const;

    // --- Playlists ---
    QVariantList allPlaylists() const;

    // --- Invokables: Playback ---
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void seekTo(qint64 positionMs);
    Q_INVOKABLE void playNext();
    Q_INVOKABLE void playPrevious();
    Q_INVOKABLE void cycleRepeatMode();
    Q_INVOKABLE void toggleShuffle();
    Q_INVOKABLE void toggleStopAfterCurrent();
    Q_INVOKABLE void setVolume(float volume);

    // --- Invokables: Queue ---
    Q_INVOKABLE void openFilesInNewQueue(const QStringList &paths,
                                         const QString &name = QString(),
                                         bool shuffle = false);
    Q_INVOKABLE void addPathsToNewQueue(const QStringList &paths,
                                        const QString &name = QString());
    Q_INVOKABLE void addPathsToQueue(int queueIndex, const QStringList &paths);
    Q_INVOKABLE void closeQueue(int index);
    Q_INVOKABLE void renameQueue(int index, const QString &name);
    Q_INVOKABLE void moveQueue(int from, int to);
    Q_INVOKABLE void viewQueue(int index);
    Q_INVOKABLE void switchToQueue(int index); // deprecated alias for viewQueue
    Q_INVOKABLE void addTrackToActiveQueue(const QString &filePath);
    Q_INVOKABLE void addTrackToQueue(const QString &path);
    Q_INVOKABLE void addAlbumToQueue(const QString &album);
    Q_INVOKABLE void removeTrackAt(int index);
    Q_INVOKABLE void moveTrack(int from, int to);
    Q_INVOKABLE void sortActiveQueue(int sort, bool ascending);
    Q_INVOKABLE void reverseActiveQueue();
    Q_INVOKABLE void jumpToTrack(int index);
    Q_INVOKABLE void jumpToTrackByPath(const QString &path);
    Q_INVOKABLE void saveQueues();
    Q_INVOKABLE void loadQueues();
    Q_INVOKABLE bool isAlbumActiveQueue(const QString &album) const;
    Q_INVOKABLE QVariantMap trackInfoByPath(const QString &path) const;

    // --- Invokables: Library ---
    Q_INVOKABLE void         scanFolder(const QString &folderPath);
    Q_INVOKABLE void         cancelScan();
    Q_INVOKABLE void         addScanFolder(const QString &path);
    Q_INVOKABLE void         removeScanFolder(const QString &path);
    Q_INVOKABLE void         rescanAllFolders();
    Q_INVOKABLE QVariantList tracksForAlbum(const QString &album)   const;
    Q_INVOKABLE QVariantList tracksForArtist(const QString &artist) const;
    Q_INVOKABLE QStringList  albumsForArtist(const QString &artist) const;
    Q_INVOKABLE QStringList  allArtistsSorted()                     const;
    Q_INVOKABLE QString      albumCoverPath(const QString &album)   const;
    Q_INVOKABLE void         setAlbumSort(int sort);
    Q_INVOKABLE void         setAlbumSortAscending(bool ascending);
    Q_INVOKABLE void         setTrackSort(int sort);
    Q_INVOKABLE void         setTrackSortAscending(bool ascending);
    Q_INVOKABLE void         setArtistSort(int sort);
    Q_INVOKABLE void         setArtistSortAscending(bool ascending);
    Q_INVOKABLE int          artistSort()          const;
    Q_INVOKABLE bool         artistSortAscending() const;

    // --- Invokables: Playlists ---
    Q_INVOKABLE int          createPlaylist(const QString &name);
    Q_INVOKABLE void         deletePlaylist(int playlistId);
    Q_INVOKABLE void         renamePlaylist(int playlistId, const QString &name);
    Q_INVOKABLE void         addTrackToPlaylist(int playlistId, const QString &path);
    Q_INVOKABLE void         removeTrackFromPlaylist(int playlistId, const QString &path);
    Q_INVOKABLE void         moveTrackInPlaylist(int playlistId, int from, int to);
    Q_INVOKABLE void         sortPlaylist(int playlistId);
    Q_INVOKABLE int          saveQueueAsPlaylist(const QString &name);
    Q_INVOKABLE QVariantList tracksForPlaylist(int playlistId) const;
    Q_INVOKABLE void         openPlaylistInNewQueue(int playlistId, const QString &name);
    Q_INVOKABLE void         requestAddToPlaylist(const QString &path);
    Q_INVOKABLE void         requestAddAlbumToPlaylist(const QString &albumName);
    Q_INVOKABLE void         setPlaylistSort(int sort);
    Q_INVOKABLE void         setPlaylistSortAscending(bool ascending);
    Q_INVOKABLE void         toggleFavorite();
    Q_INVOKABLE void         setPlayCountThreshold(int percent);

    // --- Invokables: Queue requests ---
    Q_INVOKABLE void requestAddToQueue(const QString &path);
    Q_INVOKABLE void requestAddAlbumToQueue(const QString &album);

    // --- Constants exposed to QML ---
    Q_INVOKABLE int allSongsPlaylistId()  const { return PlaylistManager::kAllSongsPlaylistId; }
    Q_INVOKABLE int favoritesPlaylistId() const { return PlaylistManager::kFavoritesPlaylistId; }

signals:
    void isPlayingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void metadataChanged();
    void trackChanged();
    void playingTrackChanged();
    void queuesChanged();
    void repeatModeChanged();
    void shuffleChanged();
    void isFavoriteChanged();
    void coverArtChanged();
    void libraryChanged();
    void scanningChanged();
    void scanProgressChanged();
    void albumSortChanged();
    void trackSortChanged();
    void playlistsChanged();
    void playlistSortChanged();
    void scanFoldersChanged();
    void playCountThresholdChanged();
    void stopAfterCurrentChanged();
    void artistSortChanged();
    void addToPlaylistRequested(const QString &path);
    void addAlbumToPlaylistRequested(const QString &albumName);
    void addToQueueRequested(QStringList paths);

private:
    QueueSession    *m_session;
    QueueManager    *m_queueManager;
    PlaybackManager *m_playbackManager;
    PlaylistManager *m_playlistManager;
    LibraryManager  *m_libraryManager;

    void wireSignals();
    void loadSettings();
    void saveSettings();
};

#endif // PLAYERCONTROLLER_H