#ifndef USERDATA_H
#define USERDATA_H

#include <string>
#include <vector>
#include <unordered_set>
#include <functional>
#include <cstdint>
#include <sqlite3.h>
#include "track.h"
#include "library.h"

struct PlaylistInfo {
    int         id = -1;
    std::string name;
    std::string imagePath;
};

class UserData
{
public:
    UserData();
    ~UserData();

    bool open(const std::string &dataDir);

    // --- Callbacks ---
    std::function<void()> onPlaylistsChanged;
    std::function<void()> onFavoritesChanged;
    std::function<void()> onStatsChanged;

    // --- Favorites ---
    void setFavorite(const std::string &path, bool favorite);
    bool isFavorite(const std::string &path) const;
    std::unordered_set<std::string> allFavoritePaths() const;

    // --- Play stats ---
    void    incrementPlayCount(const std::string &path);
    int     playCount(const std::string &path) const;
    int64_t dateLastPlayed(const std::string &path) const;

    // --- Merging stats into Track objects ---
    void applyUserData(Track &track) const;
    void applyUserData(std::vector<Track> &tracks) const;

    // --- Playlists ---
    int  createPlaylist(const std::string &name);
    void deletePlaylist(int playlistId);
    void renamePlaylist(int playlistId, const std::string &name);
    void setPlaylistImage(int playlistId, const std::string &imagePath);
    void addTrackToPlaylist(int playlistId, const std::string &path);
    void removeTrackFromPlaylist(int playlistId, const std::string &path);
    void moveTrackInPlaylist(int playlistId, int from, int to);
    void sortPlaylist(int playlistId,
                      Library::TrackSort sort, bool ascending);
    int  saveQueueAsPlaylist(const std::string &name,
                             const std::vector<std::string> &paths);

    std::vector<PlaylistInfo>  allPlaylists() const;
    std::vector<std::string>   playlistTrackPaths(int playlistId) const;

    // --- Artist images ---
    void        setArtistImage(const std::string &artist,
                               const std::string &imagePath);
    std::string artistImage(const std::string &artist) const;

    // --- Nuclear reset ---
    void clearAll();

    sqlite3 *db() const { return m_db; }

private:
    sqlite3 *m_db = nullptr;
    void createSchema();
    bool exec(const std::string &sql) const;
};

#endif // USERDATA_H