#ifndef LIBRARY_H
#define LIBRARY_H

#include <string>
#include <vector>
#include <functional>
#include <unordered_map>
#include <shared_mutex>
#include <cstdint>
#include <sqlite3.h>
#include "track.h"

struct QueueSnapshot {
    std::string              name;
    std::vector<std::string> paths;
    int     currentTrackIndex = 0;
    int64_t currentPosition   = 0;
    bool    wasPlaying        = false;
    bool    isActive          = false;
};

class Library
{
public:
    enum class AlbumSort {
        Name, Artist, AlbumArtist, Year, SongCount, Duration, Composer, DateAdded
    };

    enum class ArtistSort {
        Name, SongCount, Duration, DateAdded
    };

    enum class TrackSort {
        TrackNumber, Title, Artist, AlbumArtist, Year, Duration, Genre,
        Composer, Filename, DateAdded, DateLastPlayed, PlayCount
    };

    Library();
    ~Library();

    // Called once at startup — dataDir is passed in from Flutter
    bool open(const std::string &dataDir);

    // Callback fired when library contents change
    std::function<void()> onLibraryChanged;

    // --- Track writing ---
    void addTrack(const Track &track);
    void addTracks(const std::vector<Track> &tracks);
    void removeTrack(const std::string &path);
    void clear();

    // --- Track reading ---
    std::vector<Track>       allTracks()       const;
    std::vector<std::string> allTrackPaths()   const;
    Track                    trackByPath(const std::string &path) const;
    std::vector<Track>       tracksByAlbum(const std::string &album,
                                           TrackSort sort = TrackSort::TrackNumber,
                                           bool ascending = true) const;
    std::vector<Track>       tracksByArtist(const std::string &artist) const;
    std::vector<std::string> allAlbums(AlbumSort sort = AlbumSort::Name,
                                       bool ascending = true) const;
    std::vector<std::string> allArtists() const;
    std::vector<std::string> allArtists(ArtistSort sort, bool ascending) const;
    bool    containsPath(const std::string &path) const;
    int64_t lastModifiedFor(const std::string &path) const;
    std::vector<std::string> albumsForArtist(const std::string &artist) const;

    // --- Queue persistence ---
    void                      saveQueues(const std::vector<QueueSnapshot> &queues);
    std::vector<QueueSnapshot> loadQueues() const;

    // --- Bulk operations ---
    void removeTracksFromFolder(const std::string &folderPath);
    void removeTrackIfMissing(const std::string &path);

private:
    sqlite3 *m_db = nullptr;
    std::unordered_map<std::string, int64_t> m_pathCache;
    mutable std::shared_mutex m_cacheLock;

    void createSchema();
    void populateCache();

    static std::string albumSortColumn(AlbumSort sort);
    static std::string trackSortColumn(TrackSort sort);

    // SQLite helpers
    bool exec(const std::string &sql) const;
    static Track trackFromStmt(sqlite3_stmt *stmt);
};

#endif // LIBRARY_H