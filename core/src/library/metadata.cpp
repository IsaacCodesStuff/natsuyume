#include "metadata.h"

#include <taglib/fileref.h>
#include <taglib/tag.h>
#include <taglib/audioproperties.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/id3v2tag.h>
#include <taglib/id3v2frame.h>
#include <taglib/mpegfile.h>
#include <taglib/flacfile.h>
#include <taglib/flacpicture.h>
#include <taglib/vorbisfile.h>
#include <taglib/opusfile.h>
#include <taglib/xiphcomment.h>
#include <taglib/mp4file.h>
#include <taglib/mp4tag.h>
#include <taglib/mp4item.h>

#include <QImage>
#include <QDebug>
#include "lrcparser.h"
#include <QFileInfo>
#include <QFile>
#include <QDir>

// Helper to read a Xiph comment field (Ogg/FLAC)
static QString xiphField(TagLib::Ogg::XiphComment *xiph, const char *key)
{
    if (!xiph) return QString(""); // Changed to ""
    const auto &map = xiph->fieldListMap();
    auto it = map.find(key);
    if (it == map.end() || it->second.isEmpty())
        return QString(""); // Changed to ""
    return QString::fromStdString(it->second.front().to8Bit(true));
}

static QImage loadAndCapImage(const uchar *data, int size, int maxDimension = 1000)
{
    QImage img;
    img.loadFromData(data, size);
    if (img.isNull()) return img;
    if (img.width() > maxDimension || img.height() > maxDimension)
        img = img.scaled(maxDimension, maxDimension,
                         Qt::KeepAspectRatio,
                         Qt::SmoothTransformation);
    return img;
}

static int xiphInt(TagLib::Ogg::XiphComment *xiph, const char *key)
{
    QString val = xiphField(xiph, key);
    if (val.isEmpty()) return 0;
    // Handle "1/2" disc/track format
    return val.section('/', 0, 0).toInt();
}

Track Metadata::read(const QString &path, bool includeCoverArt)
{
    Track track(path);

    TagLib::FileRef ref(path.toUtf8().constData());

    if (ref.isNull() || !ref.tag())
        return track;

    TagLib::Tag *tag = ref.tag();

    // --- Basic tags ---
    QString title  = QString::fromStdString(tag->title().to8Bit(true));
    QString artist = QString::fromStdString(tag->artist().to8Bit(true));
    QString album  = QString::fromStdString(tag->album().to8Bit(true));
    QString genre  = QString::fromStdString(tag->genre().to8Bit(true));

    track.title  = title.isEmpty()  ? "Unknown Title"  : title;
    track.artist = artist.isEmpty() ? "Unknown Artist" : artist;
    track.album  = album.isEmpty()  ? "Unknown Album"  : album;
    track.genre  = genre;
    track.year   = tag->year();

    // --- Duration ---
    if (ref.audioProperties())
        track.duration = ref.audioProperties()->lengthInMilliseconds();

    // --- Format-specific extended tags ---
    if (auto *mp3 = dynamic_cast<TagLib::MPEG::File *>(ref.file())) {
        if (auto *id3 = mp3->ID3v2Tag()) {
            // Album artist
            auto aaFrames = id3->frameListMap()["TPE2"];
            if (!aaFrames.isEmpty())
                track.albumArtist = QString::fromStdString(
                    aaFrames.front()->toString().to8Bit(true));

            // Composer
            auto compFrames = id3->frameListMap()["TCOM"];
            if (!compFrames.isEmpty())
                track.composer = QString::fromStdString(
                    compFrames.front()->toString().to8Bit(true));

            // Track number (handles "5/12" format)
            auto trackFrames = id3->frameListMap()["TRCK"];
            if (!trackFrames.isEmpty()) {
                QString trk = QString::fromStdString(
                    trackFrames.front()->toString().to8Bit(true));
                track.trackNumber = trk.section('/', 0, 0).toInt();
            }

            // Disc number
            auto discFrames = id3->frameListMap()["TPOS"];
            if (!discFrames.isEmpty()) {
                QString disc = QString::fromStdString(
                    discFrames.front()->toString().to8Bit(true));
                track.discNumber = disc.section('/', 0, 0).toInt();
                if (track.discNumber < 1) track.discNumber = 1;
            }

            // Cover art
            if (includeCoverArt) {
                auto apicFrames = id3->frameListMap()["APIC"];
                if (!apicFrames.isEmpty()) {
                    auto *frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(
                        apicFrames.front());
                    if (frame) {
                        track.coverArt = loadAndCapImage(
                            reinterpret_cast<const uchar *>(frame->picture().data()),
                            frame->picture().size());
                    }
                }
            }

            // Lyrics — prefer USLT (synced-text container), fall back to SYLT
            auto usltFrames = id3->frameListMap()["USLT"];
            if (!usltFrames.isEmpty())
                track.lyrics = QString::fromStdString(
                    usltFrames.front()->toString().to8Bit(true));
        }
    }
    else if (auto *flac = dynamic_cast<TagLib::FLAC::File *>(ref.file())) {
        // Extended tags from Xiph comment
        if (auto *xiph = flac->xiphComment()) {
            track.albumArtist = xiphField(xiph, "ALBUMARTIST");
            track.composer    = xiphField(xiph, "COMPOSER");
            track.trackNumber = xiphInt(xiph, "TRACKNUMBER");
            track.discNumber  = xiphInt(xiph, "DISCNUMBER");
            if (track.discNumber < 1) track.discNumber = 1;
            track.lyrics = xiphField(xiph, "LYRICS");
            if (track.lyrics.isEmpty())
            track.lyrics = xiphField(xiph, "UNSYNCEDLYRICS");
        }

        // Cover art
        if (includeCoverArt) {
            const auto &pics = flac->pictureList();
            if (!pics.isEmpty()) {
                track.coverArt = loadAndCapImage(
                    reinterpret_cast<const uchar *>(pics.front()->data().data()),
                    pics.front()->data().size());
            }
        }
    }
    else if (auto *ogg = dynamic_cast<TagLib::Ogg::Vorbis::File *>(ref.file())) {
        if (auto *xiph = ogg->tag()) {
            track.albumArtist = xiphField(xiph, "ALBUMARTIST");
            track.composer    = xiphField(xiph, "COMPOSER");
            track.trackNumber = xiphInt(xiph, "TRACKNUMBER");
            track.discNumber  = xiphInt(xiph, "DISCNUMBER");
            if (track.discNumber < 1) track.discNumber = 1;
            track.lyrics = xiphField(xiph, "LYRICS");
            if (track.lyrics.isEmpty())
            track.lyrics = xiphField(xiph, "UNSYNCEDLYRICS");

            if (includeCoverArt) {
                const auto &pics = xiph->pictureList();
                if (!pics.isEmpty()) {
                    track.coverArt = loadAndCapImage(
                        reinterpret_cast<const uchar *>(pics.front()->data().data()),
                        pics.front()->data().size());
                }
            }
        }
    }
    else if (auto *opus = dynamic_cast<TagLib::Ogg::Opus::File *>(ref.file())) {
        if (auto *xiph = opus->tag()) {
            track.albumArtist = xiphField(xiph, "ALBUMARTIST");
            track.composer    = xiphField(xiph, "COMPOSER");
            track.trackNumber = xiphInt(xiph, "TRACKNUMBER");
            track.discNumber  = xiphInt(xiph, "DISCNUMBER");
            if (track.discNumber < 1) track.discNumber = 1;
            track.lyrics = xiphField(xiph, "LYRICS");
            if (track.lyrics.isEmpty())
            track.lyrics = xiphField(xiph, "UNSYNCEDLYRICS");

            if (includeCoverArt) {
                const auto &pics = xiph->pictureList();
                if (!pics.isEmpty()) {
                    track.coverArt = loadAndCapImage(
                        reinterpret_cast<const uchar *>(pics.front()->data().data()),
                        pics.front()->data().size());
                }
            }
        }
    }
    else if (auto *mp4 = dynamic_cast<TagLib::MP4::File *>(ref.file())) {
        if (auto *mp4tag = mp4->tag()) {
            const auto &items = mp4tag->itemMap();

            auto getStr = [&](const char *key) -> QString {
                auto it = items.find(key);
                if (it == items.end()) return QString(""); // Changed to ""
                auto list = it->second.toStringList();
                if (list.isEmpty()) return QString(""); // Changed to ""
                return QString::fromStdString(list.front().to8Bit(true));
            };

            track.albumArtist = getStr("aART");
            track.composer    = getStr("\xa9wrt");

            auto trkIt = items.find("trkn");
            if (trkIt != items.end()) {
                auto intPair = trkIt->second.toIntPair();
                track.trackNumber = intPair.first;
            }

            auto discIt = items.find("disk");
            if (discIt != items.end()) {
                auto intPair = discIt->second.toIntPair();
                track.discNumber = intPair.first;
                if (track.discNumber < 1) track.discNumber = 1;
            }

            // Cover art
            if (includeCoverArt) {
                auto covIt = items.find("covr");
                if (covIt != items.end()) {
                    auto coverList = covIt->second.toCoverArtList();
                    if (!coverList.isEmpty()) {
                        track.coverArt = loadAndCapImage(
                            reinterpret_cast<const uchar *>(coverList.front().data().data()),
                            coverList.front().data().size());
                    }
                }
            }

            // Lyrics
            track.lyrics = getStr("\xa9lyr");
        }
    }

    // ── Lyrics ────────────────────────────────────────────────────────────────
    // Priority: .lrc sidecar > embedded tag

    // 1. Look for a .lrc file next to the audio file
    QFileInfo fi(path);
    QString lrcPath = fi.dir().filePath(fi.completeBaseName() + ".lrc");
    QFile lrcFile(lrcPath);
    if (lrcFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        track.lyrics = QString::fromUtf8(lrcFile.readAll());
        return track; // sidecar takes priority, skip embedded
    }

    // Sanitize all string fields — normalize null QStrings to empty,
    // apply NFC normalization, and fill in fallback display values
    auto sanitizeStr = [](QString &s) {
        if (s.isNull()) s = QString("");
        s = s.normalized(QString::NormalizationForm_C).trimmed();
    };

    sanitizeStr(track.title);
    sanitizeStr(track.artist);
    sanitizeStr(track.album);
    sanitizeStr(track.albumArtist);
    sanitizeStr(track.composer);
    sanitizeStr(track.genre);
    sanitizeStr(track.lyrics);

    // Fallback display values for missing required fields
    if (track.title.isEmpty())  track.title  = "Unknown Title";
    if (track.artist.isEmpty()) track.artist = "Unknown Artist";
    if (track.album.isEmpty())  track.album  = "Unknown Album";

    // Numeric sanity
    if (track.trackNumber < 0) track.trackNumber = 0;
    if (track.discNumber  < 1) track.discNumber  = 1;
    if (track.year        < 0) track.year        = 0;
    if (track.duration    < 0) track.duration    = 0;

    // 2. Embedded lyrics — already read per-format above, stored in track.lyrics
    //    (populated in the format blocks below; nothing to do here)

    return track;
}