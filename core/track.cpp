#include "track.h"

Track::Track(const QString &path)
    : path(path),
    title("Unknown Title"),
    artist("Unknown Artist"),
    album("Unknown Album"),
    albumArtist(""),
    composer(""),
    genre(""),
    trackNumber(0),
    discNumber(1),
    year(0),
    duration(0),
    dateAdded(0),
    dateLastPlayed(0),
    playCount(0)
{}