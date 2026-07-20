#ifndef TRACK_H
#define TRACK_H

#include <string>
#include <vector>
#include <cstdint>

class Track
{
public:
    Track() = default;
    Track(const std::string &path);

    // --- Core ---
    std::string path;
    std::string title;
    std::string artist;
    std::string album;

    // --- Extended metadata ---
    std::string albumArtist;
    std::string composer;
    std::string genre;

    int      trackNumber = 0;
    int      discNumber  = 1;
    int      year        = 0;
    int64_t  duration    = 0;  // milliseconds

    // --- Library timestamps ---
    int64_t  dateAdded      = 0;
    int64_t  dateLastPlayed = 0;
    int      playCount      = 0;
    bool     isFavorite     = false;

    // --- Cover art (raw bytes) ---
    std::vector<uint8_t> coverArtData;
    std::string          coverArtMimeType;

    // --- Lyrics ---
    std::string lyrics;

    // --- Misc ---
    int64_t lastModified = 0;

    bool isValid()     const { return !path.empty(); }
    bool hasCoverArt() const { return !coverArtData.empty(); }
};

#endif // TRACK_H