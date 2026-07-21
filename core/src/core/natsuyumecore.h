#ifndef NATSUYUMECORE_H
#define NATSUYUMECORE_H

#include <string>
#include <vector>
#include <functional>
#include <cstdint>
#include "coretypes.h"

namespace Natsuyume {

// ---------------------------------------------------------------------------
// CoreCallbacks
// All callbacks are invoked on the thread that owns the core event loop.
// Qt adapter: wire via QMetaObject::invokeMethod(..., Qt::QueuedConnection).
// CLI adapter: invoke directly (single-threaded).
// ---------------------------------------------------------------------------
struct CoreCallbacks {
    // --- Playback ---
    std::function<void(bool isPlaying)>        onPlaybackStateChanged;
    std::function<void(int64_t positionMs)>    onPositionChanged;
    std::function<void(int64_t durationMs)>    onDurationChanged;
    std::function<void(float volume)>          onVolumeChanged;

    // --- Track / metadata ---
    std::function<void(const CoreTrack &)>     onTrackChanged;
    std::function<void()>                      onMetadataChanged;

    // --- Queue ---
    std::function<void()>                      onQueueChanged;
    std::function<void()>                      onQueuesChanged;    // multi-queue list changed
    std::function<void()>                      onRepeatModeChanged;
    std::function<void()>                      onShuffleChanged;
    std::function<void()>                      onStopAfterCurrentChanged;

    // --- Library ---
    std::function<void()>                      onLibraryChanged;
    std::function<void(bool isScanning)>       onScanningChanged;
    std::function<void(int current,
                       int total,
                       const std::string &file)> onScanProgressChanged;

    // --- Playlists ---
    std::function<void()>                      onPlaylistsChanged;

    // --- Favorites ---
    std::function<void(bool isFavorite)>       onFavoriteChanged;

    // --- A-B repeat ---
    std::function<void()>                      onAbRepeatChanged;

    // --- Sort ---
    std::function<void()>                      onAlbumSortChanged;
    std::function<void()>                      onTrackSortChanged;
    std::function<void()>                      onPlaylistSortChanged;

    // --- Settings ---
    std::function<void()>                      onScanFoldersChanged;
    std::function<void()>                      onPlayCountThresholdChanged;
};

// ---------------------------------------------------------------------------
// NatsuyumeCore
// Pure C++ facade. No Qt headers included here.
// Owns all subsystems. Frontends interact only through this class.
// ---------------------------------------------------------------------------
class NatsuyumeCore {
public:
    NatsuyumeCore();
    ~NatsuyumeCore();

    // --- Lifecycle ---
    bool init();         // open DB, load settings, restore queues
    void shutdown();     // save queues/settings, tear down mpv

    // --- Callbacks (set before calling init()) ---
    CoreCallbacks callbacks;

    // --- Playback ---
    void play();
    void pause();
    void seekTo(int64_t positionMs);
    void playNext();
    void playPrevious();
    void cycleRepeatMode();
    void toggleShuffle();
    void toggleStopAfterCurrent();
    void setVolume(float volume);

    // --- Playback state ---
    bool    isPlaying()  const;
    int64_t position()   const;
    int64_t duration()   const;
    float   volume()     const;
    int     repeatMode() const;   // maps to RepeatMode enum
    bool    isShuffled() const;
    bool    stopAfterCurrent() const;

    // --- Current track ---
    CoreTrack currentTrack() const;
    bool      isFavorite()   const;

    // --- Playing-queue navigation state ---
    int  playingTrackIndex() const;
    int  playingTrackCount() const;
    bool hasPrevious()       const;
    bool hasNext()           const;

    // --- Viewed-queue navigation state ---
    int viewedTrackIndex() const;
    int viewedTrackCount() const;

    // --- Queue operations ---
    void openFilesInNewQueue(const std::vector<std::string> &paths,
                             const std::string &name = {},
                             bool shuffle = false);
    void addPathsToNewQueue(const std::vector<std::string> &paths,
                            const std::string &name = {});
    void addPathsToQueue(int queueIndex, const std::vector<std::string> &paths);
    void closeQueue(int index);
    void renameQueue(int index, const std::string &name);
    void moveQueue(int from, int to);
    void viewQueue(int index);
    void addTrackToQueue(const std::string &path);
    void addAlbumToQueue(const std::string &album);
    void removeTrackAt(int index);
    void moveTrack(int from, int to);
    void sortActiveQueue(int sort, bool ascending);
    void reverseActiveQueue();
    void jumpToTrack(int index);
    void jumpToTrackByPath(const std::string &path);
    void saveQueues();
    void loadQueues();

    // --- Queue state ---
    int                         queueCount()        const;
    int                         activeQueueIndex()  const;
    int                         playingQueueIndex() const;
    std::vector<std::string>    queueNames()        const;
    int64_t                     queueTotalDuration() const;
    bool                        isAlbumActiveQueue(const std::string &album) const;
    std::vector<CoreTrack>      trackList()         const;
    CoreTrack                   trackInfoByPath(const std::string &path) const;

    // --- Library ---
    void scanFolder(const std::string &folderPath);
    void cancelScan();
    void addScanFolder(const std::string &path);
    void removeScanFolder(const std::string &path);
    void rescanAllFolders();
    bool isScanning()   const;
    int  scanProgress() const;
    int  scanTotal()    const;
    std::string scanningFile() const;

    // --- Library queries ---
    std::vector<std::string> allAlbums()   const;
    std::vector<std::string> allArtists()  const;
    std::vector<CoreTrack>   tracksForAlbum(const std::string &album)   const;
    std::vector<CoreTrack>   tracksForArtist(const std::string &artist) const;
    std::vector<std::string> albumsForArtist(const std::string &artist) const;
    std::vector<std::string> allArtistsSorted() const;
    std::string              albumCoverPath(const std::string &album)   const;

    // --- Sort ---
    int  albumSort()              const;
    bool albumSortAscending()     const;
    int  trackSort()              const;
    bool trackSortAscending()     const;
    int  artistSort()             const;
    bool artistSortAscending()    const;
    int  playlistSort()           const;
    bool playlistSortAscending()  const;

    void setAlbumSort(int sort);
    void setAlbumSortAscending(bool ascending);
    void setTrackSort(int sort);
    void setTrackSortAscending(bool ascending);
    void setArtistSort(int sort);
    void setArtistSortAscending(bool ascending);
    void setPlaylistSort(int sort);
    void setPlaylistSortAscending(bool ascending);

    // --- Playlists ---
    int  createPlaylist(const std::string &name);
    void deletePlaylist(int playlistId);
    void renamePlaylist(int playlistId, const std::string &name);
    void addTrackToPlaylist(int playlistId, const std::string &path);
    void removeTrackFromPlaylist(int playlistId, const std::string &path);
    void moveTrackInPlaylist(int playlistId, int from, int to);
    void sortPlaylist(int playlistId);
    int  saveQueueAsPlaylist(const std::string &name);
    void openPlaylistInNewQueue(int playlistId, const std::string &name);

    std::vector<CorePlaylistInfo> allPlaylists()                        const;
    std::vector<CoreTrack>        tracksForPlaylist(int playlistId)     const;

    static int allSongsPlaylistId();
    static int favoritesPlaylistId();

    // --- Favorites ---
    void toggleFavorite();

    // --- Settings ---
    std::vector<std::string> scanFolders()        const;
    int                      playCountThreshold() const;
    void                     setPlayCountThreshold(int percent);
    void                     saveSettings();

    // --- A-B repeat ---
    bool    abRepeatActive() const;
    int64_t pointA()         const;
    int64_t pointB()         const;
    void    setPointA();
    void    setPointB();
    void    clearAbRepeat();

    // --- Artist images ---
    void        setArtistImage(const std::string &artist,
                        const std::string &imagePath);
    std::string artistImage(const std::string &artist) const;

    // --- Playlist image ---
    void setPlaylistImage(int playlistId, const std::string &imagePath);

    // --- Clear operations ---
    void clearUserData();
    void clearLibrary();

    void setDataDir(const std::string &dir);

private:
    struct Impl;
    Impl *m_impl = nullptr;   // pImpl — keeps Qt internals out of this header
};

} // namespace Natsuyume

#endif // NATSUYUMECORE_H