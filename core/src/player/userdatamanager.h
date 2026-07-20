#ifndef USERDATAMANAGER_H
#define USERDATAMANAGER_H

#include <string>
#include <vector>
#include <unordered_set>
#include <functional>
#include <cstdint>
#include "userdata.h"
#include "library.h"
#include "coretypes.h"

class UserDataManager
{
public:
    UserDataManager();

    bool open(const std::string &dataDir);
    void setLibrary(Library *library);

    // --- Callbacks ---
    std::function<void()> onPlaylistsChanged;
    std::function<void()> onPlaylistSortChanged;
    std::function<void()> onIsFavoriteChanged;
    std::function<void(const std::vector<std::string> &paths,
                       const std::string &name)> onOpenInNewQueueRequested;

    // --- Favorites ---
    bool                             isFavorite(const std::string &path) const;
    void                             toggleFavorite(const std::string &path);
    std::unordered_set<std::string>  allFavoritePaths() const;

    // --- Play stats ---
    void incrementPlayCount(const std::string &path);
    void applyUserData(Track &track) const;
    void applyUserData(std::vector<Track> &tracks) const;

    // --- Playlists ---
    std::vector<Natsuyume::CorePlaylistInfo> allPlaylists()              const;
    int  createPlaylist(const std::string &name);
    void deletePlaylist(int playlistId);
    void renamePlaylist(int playlistId, const std::string &name);
    void setPlaylistImage(int playlistId, const std::string &imagePath);
    void addTrackToPlaylist(int playlistId, const std::string &path);
    void removeTrackFromPlaylist(int playlistId, const std::string &path);
    void moveTrackInPlaylist(int playlistId, int from, int to);
    void sortPlaylist(int playlistId);
    int  saveQueueAsPlaylist(const std::string &name,
                             const std::vector<std::string> &paths);
    std::vector<Track> tracksForPlaylist(int playlistId) const;
    void openPlaylistInNewQueue(int playlistId, const std::string &name);

    // --- Playlist sort ---
    int  playlistSort()          const;
    bool playlistSortAscending() const;
    void setPlaylistSort(int sort);
    void setPlaylistSortAscending(bool ascending);

    // --- Artist images ---
    void        setArtistImage(const std::string &artist,
                               const std::string &imagePath);
    std::string artistImage(const std::string &artist) const;

    // --- Clear operations ---
    void clearUserData();
    void clearLibrary();

    // --- Settings ---
    void loadSettings(const std::string &dataDir);
    void saveSettings(const std::string &dataDir);

    // --- Constants ---
    static constexpr int kAllSongsPlaylistId  = -2;
    static constexpr int kFavoritesPlaylistId = -3;

    // --- Raw playlists (internal use) ---
    std::vector<PlaylistInfo> rawPlaylists() const;

private:
    UserData *m_userData = nullptr;
    Library  *m_library  = nullptr;

    Library::TrackSort m_playlistSort          = Library::TrackSort::TrackNumber;
    bool               m_playlistSortAscending = true;
    std::string        m_dataDir;
};

#endif // USERDATAMANAGER_H