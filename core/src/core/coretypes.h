#ifndef CORETYPES_H
#define CORETYPES_H

#include <string>
#include <vector>
#include <cstdint>

namespace Natsuyume {

struct CoreTrack {
    // --- Core ---
    std::string path;
    std::string title;
    std::string artist;
    std::string album;

    // --- Extended metadata ---
    std::string albumArtist;
    std::string composer;
    std::string genre;
    int         trackNumber  = 0;
    int         discNumber   = 1;
    int         year         = 0;
    int64_t     duration     = 0;   // milliseconds

    // --- Library timestamps ---
    int64_t     dateAdded      = 0;
    int64_t     dateLastPlayed = 0;
    int         playCount      = 0;
    bool        isFavorite     = false;

    // --- Cover art (raw bytes, format defined by coverArtMimeType) ---
    std::vector<uint8_t> coverArtData;
    std::string          coverArtMimeType; // e.g. "image/jpeg"

    // --- Lyrics ---
    std::string lyrics;

    // --- Misc ---
    int64_t lastModified = 0;

    bool isValid()     const { return !path.empty(); }
    bool hasCoverArt() const { return !coverArtData.empty(); }
};

struct CorePlaylistInfo {
    int         id   = -1;
    std::string name;
};

struct CoreQueueSnapshot {
    std::string              name;
    std::vector<std::string> paths;
    int     currentTrackIndex = 0;
    int64_t currentPosition   = 0;
    bool    wasPlaying        = false;
    bool    isActive          = false;
};

enum class RepeatMode {
    NoRepeat,
    RepeatQueue,
    RepeatTrack
};

} // namespace Natsuyume

#endif // CORETYPES_H