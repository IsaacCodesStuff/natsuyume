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

#include <unicode/unorm2.h>
#include <unicode/ustring.h>

#include <fstream>
#include <sstream>
#include <filesystem>
#include <cstring>

#include "lrcparser.h"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static std::string xiphField(TagLib::Ogg::XiphComment *xiph, const char *key)
{
    if (!xiph) return "";
    const auto &map = xiph->fieldListMap();
    auto it = map.find(key);
    if (it == map.end() || it->second.isEmpty())
        return "";
    return it->second.front().to8Bit(true);
}

static int xiphInt(TagLib::Ogg::XiphComment *xiph, const char *key)
{
    std::string val = xiphField(xiph, key);
    if (val.empty()) return 0;
    // Handle "1/2" disc/track format
    auto slash = val.find('/');
    std::string part = (slash != std::string::npos) ? val.substr(0, slash) : val;
    try { return std::stoi(part); } catch (...) { return 0; }
}

// Copy raw image bytes into track — no decoding, no scaling.
// Flutter handles display-side scaling.
static void loadCoverBytes(Track &track,
                           const void *data,
                           size_t size,
                           const std::string &mimeType = "image/jpeg")
{
    if (!data || size == 0) return;
    const uint8_t *bytes = reinterpret_cast<const uint8_t *>(data);
    track.coverArtData.assign(bytes, bytes + size);
    track.coverArtMimeType = mimeType;
}

// NFC-normalize + trim a UTF-8 string via ICU C API
static std::string normalizeStr(const std::string &s)
{
    if (s.empty()) return s;
    UErrorCode err = U_ZERO_ERROR;
    const UNormalizer2 *nfc = unorm2_getNFCInstance(&err);
    if (U_FAILURE(err)) return s;

    // Convert UTF-8 → UTF-16 for normalization
    int32_t u16len = 0;
    u_strFromUTF8(nullptr, 0, &u16len, s.c_str(), -1, &err);
    err = U_ZERO_ERROR;
    std::vector<UChar> u16(u16len + 1);
    u_strFromUTF8(u16.data(), u16len + 1, &u16len, s.c_str(), -1, &err);
    if (U_FAILURE(err)) return s;

    // Normalize
    std::vector<UChar> norm(u16len * 2 + 1);
    int32_t normLen = unorm2_normalize(nfc, u16.data(), u16len,
                                       norm.data(), norm.size(), &err);
    if (U_FAILURE(err)) return s;

    // Convert UTF-16 → UTF-8
    int32_t u8len = 0;
    u_strToUTF8(nullptr, 0, &u8len, norm.data(), normLen, &err);
    err = U_ZERO_ERROR;
    std::string result(u8len, '\0');
    u_strToUTF8(result.data(), u8len + 1, &u8len, norm.data(), normLen, &err);
    if (U_FAILURE(err)) return s;

    // Trim ASCII whitespace
    size_t start = result.find_first_not_of(" \t\r\n");
    size_t end   = result.find_last_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    return result.substr(start, end - start + 1);
}

// ---------------------------------------------------------------------------
// Metadata::read
// ---------------------------------------------------------------------------

Track Metadata::read(const std::string &path, bool includeCoverArt)
{
    Track track(path);

    TagLib::FileRef ref(path.c_str());

    if (ref.isNull() || !ref.tag())
        return track;

    TagLib::Tag *tag = ref.tag();

    // --- Basic tags ---
    std::string title  = tag->title().to8Bit(true);
    std::string artist = tag->artist().to8Bit(true);
    std::string album  = tag->album().to8Bit(true);
    std::string genre  = tag->genre().to8Bit(true);

    track.title  = title.empty()  ? "Unknown Title"  : title;
    track.artist = artist.empty() ? "Unknown Artist" : artist;
    track.album  = album.empty()  ? "Unknown Album"  : album;
    track.genre  = genre;
    track.year   = tag->year();

    // --- Duration ---
    if (ref.audioProperties())
        track.duration = ref.audioProperties()->lengthInMilliseconds();

    // --- Format-specific extended tags ---
    if (auto *mp3 = dynamic_cast<TagLib::MPEG::File *>(ref.file())) {
        if (auto *id3 = mp3->ID3v2Tag()) {
            auto aaFrames = id3->frameListMap()["TPE2"];
            if (!aaFrames.isEmpty())
                track.albumArtist =
                    aaFrames.front()->toString().to8Bit(true);

            auto compFrames = id3->frameListMap()["TCOM"];
            if (!compFrames.isEmpty())
                track.composer =
                    compFrames.front()->toString().to8Bit(true);

            auto trackFrames = id3->frameListMap()["TRCK"];
            if (!trackFrames.isEmpty()) {
                std::string trk = trackFrames.front()->toString().to8Bit(true);
                auto slash = trk.find('/');
                std::string part = (slash != std::string::npos)
                                       ? trk.substr(0, slash) : trk;
                try { track.trackNumber = std::stoi(part); } catch (...) {}
            }

            auto discFrames = id3->frameListMap()["TPOS"];
            if (!discFrames.isEmpty()) {
                std::string disc = discFrames.front()->toString().to8Bit(true);
                auto slash = disc.find('/');
                std::string part = (slash != std::string::npos)
                                       ? disc.substr(0, slash) : disc;
                try {
                    track.discNumber = std::stoi(part);
                    if (track.discNumber < 1) track.discNumber = 1;
                } catch (...) {}
            }

            if (includeCoverArt) {
                auto apicFrames = id3->frameListMap()["APIC"];
                if (!apicFrames.isEmpty()) {
                    auto *frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(
                        apicFrames.front());
                    if (frame) {
                        std::string mime = frame->mimeType().to8Bit(true);
                        if (mime.empty()) mime = "image/jpeg";
                        loadCoverBytes(track,
                                       frame->picture().data(),
                                       frame->picture().size(),
                                       mime);
                    }
                }
            }

            auto usltFrames = id3->frameListMap()["USLT"];
            if (!usltFrames.isEmpty())
                track.lyrics = usltFrames.front()->toString().to8Bit(true);
        }
    }
    else if (auto *flac = dynamic_cast<TagLib::FLAC::File *>(ref.file())) {
        if (auto *xiph = flac->xiphComment()) {
            track.albumArtist = xiphField(xiph, "ALBUMARTIST");
            track.composer    = xiphField(xiph, "COMPOSER");
            track.trackNumber = xiphInt(xiph, "TRACKNUMBER");
            track.discNumber  = xiphInt(xiph, "DISCNUMBER");
            if (track.discNumber < 1) track.discNumber = 1;
            track.lyrics = xiphField(xiph, "LYRICS");
            if (track.lyrics.empty())
                track.lyrics = xiphField(xiph, "UNSYNCEDLYRICS");
        }

        if (includeCoverArt) {
            const auto &pics = flac->pictureList();
            if (!pics.isEmpty()) {
                std::string mime = pics.front()->mimeType().to8Bit(true);
                if (mime.empty()) mime = "image/jpeg";
                loadCoverBytes(track,
                               pics.front()->data().data(),
                               pics.front()->data().size(),
                               mime);
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
            if (track.lyrics.empty())
                track.lyrics = xiphField(xiph, "UNSYNCEDLYRICS");

            if (includeCoverArt) {
                const auto &pics = xiph->pictureList();
                if (!pics.isEmpty()) {
                    std::string mime = pics.front()->mimeType().to8Bit(true);
                    if (mime.empty()) mime = "image/jpeg";
                    loadCoverBytes(track,
                                   pics.front()->data().data(),
                                   pics.front()->data().size(),
                                   mime);
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
            if (track.lyrics.empty())
                track.lyrics = xiphField(xiph, "UNSYNCEDLYRICS");

            if (includeCoverArt) {
                const auto &pics = xiph->pictureList();
                if (!pics.isEmpty()) {
                    std::string mime = pics.front()->mimeType().to8Bit(true);
                    if (mime.empty()) mime = "image/jpeg";
                    loadCoverBytes(track,
                                   pics.front()->data().data(),
                                   pics.front()->data().size(),
                                   mime);
                }
            }
        }
    }
    else if (auto *mp4 = dynamic_cast<TagLib::MP4::File *>(ref.file())) {
        if (auto *mp4tag = mp4->tag()) {
            const auto &items = mp4tag->itemMap();

            auto getStr = [&](const char *key) -> std::string {
                auto it = items.find(key);
                if (it == items.end()) return "";
                auto list = it->second.toStringList();
                if (list.isEmpty()) return "";
                return list.front().to8Bit(true);
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

            if (includeCoverArt) {
                auto covIt = items.find("covr");
                if (covIt != items.end()) {
                    auto coverList = covIt->second.toCoverArtList();
                    if (!coverList.isEmpty()) {
                        std::string mime =
                            coverList.front().format() == TagLib::MP4::CoverArt::PNG
                                ? "image/png" : "image/jpeg";
                        loadCoverBytes(track,
                                       coverList.front().data().data(),
                                       coverList.front().data().size(),
                                       mime);
                    }
                }
            }

            track.lyrics = getStr("\xa9lyr");
        }
    }

    // --- LRC sidecar (priority over embedded lyrics) ---
    std::filesystem::path audioPath(path);
    std::filesystem::path lrcPath =
        audioPath.parent_path() / (audioPath.stem().string() + ".lrc");

    if (std::filesystem::exists(lrcPath)) {
        std::ifstream lrcFile(lrcPath);
        if (lrcFile.is_open()) {
            std::ostringstream ss;
            ss << lrcFile.rdbuf();
            track.lyrics = ss.str();
        }
    }

    // --- Sanitize all string fields ---
    auto sanitize = [](std::string &s) {
        s = normalizeStr(s);
    };

    sanitize(track.title);
    sanitize(track.artist);
    sanitize(track.album);
    sanitize(track.albumArtist);
    sanitize(track.composer);
    sanitize(track.genre);
    sanitize(track.lyrics);

    // Fallback display values
    if (track.title.empty())  track.title  = "Unknown Title";
    if (track.artist.empty()) track.artist = "Unknown Artist";
    if (track.album.empty())  track.album  = "Unknown Album";

    // Numeric sanity
    if (track.trackNumber < 0) track.trackNumber = 0;
    if (track.discNumber  < 1) track.discNumber  = 1;
    if (track.year        < 0) track.year        = 0;
    if (track.duration    < 0) track.duration    = 0;

    return track;
}