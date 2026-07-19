#ifndef TRACK_H
#define TRACK_H

#include <QString>
#include <QImage>

class Track
{
public:
    Track() = default;
    Track(const QString &path);

    // --- Core ---
    QString path;
    QString title;
    QString artist;
    QString album;

    // --- Extended metadata ---
    QString albumArtist;
    QString composer;
    QString genre;

    int     trackNumber = 0;
    int     discNumber  = 1;
    int     year        = 0;
    qint64  duration    = 0;  // milliseconds

    // --- Library timestamps ---
    qint64  dateAdded      = 0;
    qint64  dateLastPlayed = 0;
    int     playCount      = 0;
    bool    isFavorite     = false;

    // --- Cover art ---
    QImage  coverArt;
    QString lyrics;

    bool isValid()      const { return !path.isEmpty(); }
    bool hasCoverArt()  const { return !coverArt.isNull(); }
    qint64 lastModified = 0;
};

#endif // TRACK_H