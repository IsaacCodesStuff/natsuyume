#include "natsuyumecore.h"
#include "metadata.h"
#include "track.h"
#include <cstring>
#include <cstdlib>
#include <thread>
#include <atomic>
#include <android/log.h>

static std::atomic<bool> g_prewarm_done{false};

using Natsuyume::NatsuyumeCore;
using Natsuyume::CoreTrack;

extern "C" {

NatsuyumeCore* ncore_create() {
    return new NatsuyumeCore();
}

void ncore_destroy(NatsuyumeCore* core) {
    delete core;
}

void ncore_set_data_dir(NatsuyumeCore* core, const char* data_dir) {
    if (core && data_dir) core->setDataDir(std::string(data_dir));
}

void ncore_init(NatsuyumeCore* core) {
    if (core) core->init();
}

void ncore_shutdown(NatsuyumeCore* core) {
    if (core) core->shutdown();
}

// Open a single file in a new queue and start playing
void ncore_open_file(NatsuyumeCore* core, const char* path) {
    if (!core || !path) return;
    core->openFilesInNewQueue({std::string(path)}, "", false);
}

char* ncore_get_version() {
    const char* version = "0.8.0";
    char* out = static_cast<char*>(malloc(strlen(version) + 1));
    strcpy(out, version);
    return out;
}

void ncore_free_string(char* str) {
    free(str);
}

int ncore_track_count(NatsuyumeCore* core) {
    if (!core) return 0;
    return static_cast<int>(
        core->tracksForPlaylist(NatsuyumeCore::allSongsPlaylistId()).size()
    );
}

void ncore_add_scan_folder(NatsuyumeCore* core, const char* path) {
    if (core && path) core->addScanFolder(std::string(path));
}

void ncore_scan_library(NatsuyumeCore* core) {
    if (core) core->rescanAllFolders();
}

void ncore_play(NatsuyumeCore* core) {
    if (core) core->play();
}

void ncore_pause(NatsuyumeCore* core) {
    if (core) core->pause();
}

void ncore_next(NatsuyumeCore* core) {
    if (core) core->playNext();
}

void ncore_previous(NatsuyumeCore* core) {
    if (core) core->playPrevious();
}

void ncore_seek(NatsuyumeCore* core, double position_seconds) {
    if (core) core->seekTo(static_cast<int64_t>(position_seconds * 1000.0));
}

// ---------------------------------------------------------------------------
// Playback state queries
// ---------------------------------------------------------------------------

int ncore_is_playing(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->isPlaying() ? 1 : 0;
}

int64_t ncore_get_position(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->position();
}

int64_t ncore_get_duration(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->duration();
}

// ---------------------------------------------------------------------------
// Current track — flattened into C-compatible out-params
// Caller must free each char* via ncore_free_string()
// ---------------------------------------------------------------------------

void ncore_get_current_track(NatsuyumeCore* core,
                              char** out_path,
                              char** out_title,
                              char** out_artist,
                              char** out_album,
                              char** out_album_artist,
                              char** out_genre,
                              int*   out_track_number,
                              int*   out_year,
                              int64_t* out_duration,
                              int*   out_play_count,
                              int*   out_is_favorite)
{
    auto copyStr = [](const std::string& s) -> char* {
        char* out = static_cast<char*>(malloc(s.size() + 1));
        memcpy(out, s.c_str(), s.size() + 1);
        return out;
    };

    if (!core) {
        *out_path         = copyStr("");
        *out_title        = copyStr("");
        *out_artist       = copyStr("");
        *out_album        = copyStr("");
        *out_album_artist = copyStr("");
        *out_genre        = copyStr("");
        *out_track_number = 0;
        *out_year         = 0;
        *out_duration     = 0;
        *out_play_count   = 0;
        *out_is_favorite  = 0;
        return;
    }

    CoreTrack t = core->currentTrack();
    *out_path         = copyStr(t.path);
    *out_title        = copyStr(t.title);
    *out_artist       = copyStr(t.artist);
    *out_album        = copyStr(t.album);
    *out_album_artist = copyStr(t.albumArtist);
    *out_genre        = copyStr(t.genre);
    *out_track_number = t.trackNumber;
    *out_year         = t.year;
    *out_duration     = t.duration;
    *out_play_count   = t.playCount;
    *out_is_favorite  = t.isFavorite ? 1 : 0;
}

// Callback typedefs — called from C++ event thread, marshalled to Dart by NativeCallable
typedef void (*DartPlaybackStateCallback)(int32_t is_playing);
typedef void (*DartPositionCallback)(int64_t position_ms);
typedef void (*DartDurationCallback)(int64_t duration_ms);
typedef void (*DartTrackChangedCallback)();

void ncore_set_playback_state_callback(NatsuyumeCore* core,
                                        DartPlaybackStateCallback cb) {
    if (!core) return;
    core->callbacks.onPlaybackStateChanged = [cb](bool isPlaying) {
        if (cb) cb(isPlaying ? 1 : 0);
    };
}

void ncore_set_position_callback(NatsuyumeCore* core,
                                  DartPositionCallback cb) {
    if (!core) return;
    core->callbacks.onPositionChanged = [cb](int64_t positionMs) {
        if (cb) cb(positionMs);
    };
}

void ncore_set_duration_callback(NatsuyumeCore* core,
                                  DartDurationCallback cb) {
    if (!core) return;
    core->callbacks.onDurationChanged = [cb](int64_t durationMs) {
        if (cb) cb(durationMs);
    };
}

void ncore_set_track_changed_callback(NatsuyumeCore* core,
                                       DartTrackChangedCallback cb) {
    if (!core) return;
    core->callbacks.onTrackChanged = [cb](const Natsuyume::CoreTrack&) {
        if (cb) cb();
    };
}

// ---------------------------------------------------------------------------
// Library drain + scan state
// ---------------------------------------------------------------------------

void ncore_drain_library_callbacks(NatsuyumeCore* core) {
    if (core) core->drainLibraryCallbacks();
}

int ncore_is_scanning(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->isScanning() ? 1 : 0;
}

int ncore_scan_progress(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->scanProgress();
}

int ncore_scan_total(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->scanTotal();
}

void ncore_remove_scan_folder(NatsuyumeCore* core, const char* path) {
    if (core && path) core->removeScanFolder(std::string(path));
}

void ncore_cancel_scan(NatsuyumeCore* core) {
    if (core) core->cancelScan();
}

// Returns JSON array of tracks in the current viewed queue.
// Caller must free with ncore_free_string().
char* ncore_get_queue_json(NatsuyumeCore* core) {
    if (!core) {
        char* empty = static_cast<char*>(malloc(3));
        strcpy(empty, "[]");
        return empty;
    }

    std::vector<Natsuyume::CoreTrack> tracks = core->trackList();

    std::string json = "[";
    for (size_t i = 0; i < tracks.size(); i++) {
        const auto& t = tracks[i];
        if (i > 0) json += ",";

        auto escape = [](const std::string& s) {
            std::string out;
            for (char c : s) {
                if (c == '"')  out += "\\\"";
                else if (c == '\\') out += "\\\\";
                else if (c == '\n') out += "\\n";
                else if (c == '\r') out += "\\r";
                else if (c == '\t') out += "\\t";
                else out += c;
            }
            return out;
        };

        json += "{";
        json += "\"path\":\"" + escape(t.path) + "\",";
        json += "\"title\":\"" + escape(t.title) + "\",";
        json += "\"artist\":\"" + escape(t.artist) + "\",";
        json += "\"album\":\"" + escape(t.album) + "\",";
        json += "\"albumArtist\":\"" + escape(t.albumArtist) + "\",";
        json += "\"trackNumber\":" + std::to_string(t.trackNumber) + ",";
        json += "\"durationMs\":" + std::to_string(t.duration) + ",";
        json += "\"isFavorite\":" + std::string(t.isFavorite ? "true" : "false");
        json += "}";
    }
    json += "]";

    char* out = static_cast<char*>(malloc(json.size() + 1));
    memcpy(out, json.c_str(), json.size() + 1);
    return out;
}

// ---------------------------------------------------------------------------
// Library queries
// ---------------------------------------------------------------------------

static std::string escapeJson(const std::string& s) {
    std::string out;
    for (char c : s) {
        if      (c == '"')  out += "\\\"";
        else if (c == '\\') out += "\\\\";
        else if (c == '\n') out += "\\n";
        else if (c == '\r') out += "\\r";
        else if (c == '\t') out += "\\t";
        else out += c;
    }
    return out;
}

static char* mallocStr(const std::string& s) {
    char* out = static_cast<char*>(malloc(s.size() + 1));
    memcpy(out, s.c_str(), s.size() + 1);
    return out;
}

char* ncore_get_albums_json(NatsuyumeCore* core) {
    if (!core) return mallocStr("[]");

    std::vector<std::string> albums = core->allAlbums();
    std::string json = "[";
    for (size_t i = 0; i < albums.size(); i++) {
        if (i > 0) json += ",";
        const std::string& name = albums[i];
        auto tracks = core->tracksForAlbum(name);

        int year = 0;
        for (const auto& t : tracks)
            if (t.year > year) year = t.year;

        json += "{";
        json += "\"title\":\"" + escapeJson(name) + "\",";
        json += "\"artist\":\"" + escapeJson(tracks.empty() ? "" : tracks.front().albumArtist.empty() ? tracks.front().artist : tracks.front().albumArtist) + "\",";
        json += "\"year\":" + std::to_string(year) + ",";
        json += "\"songCount\":" + std::to_string(tracks.size());
        json += "}";
    }
    json += "]";
    return mallocStr(json);
}

char* ncore_get_artists_json(NatsuyumeCore* core) {
    if (!core) return mallocStr("[]");

    std::vector<std::string> artists = core->allArtists();
    std::string json = "[";
    for (size_t i = 0; i < artists.size(); i++) {
        if (i > 0) json += ",";
        const std::string& name = artists[i];
        auto albums = core->albumsForArtist(name);

        json += "{";
        json += "\"name\":\"" + escapeJson(name) + "\",";
        json += "\"albumCount\":" + std::to_string(albums.size());
        json += "}";
    }
    json += "]";
    return mallocStr(json);
}

char* ncore_get_album_tracks_json(NatsuyumeCore* core, const char* albumName) {
    if (!core || !albumName) return mallocStr("[]");

    auto tracks = core->tracksForAlbum(std::string(albumName));
    std::string json = "[";
    for (size_t i = 0; i < tracks.size(); i++) {
        if (i > 0) json += ",";
        const auto& t = tracks[i];
        json += "{";
        json += "\"path\":\"" + escapeJson(t.path) + "\",";
        json += "\"title\":\"" + escapeJson(t.title) + "\",";
        json += "\"artist\":\"" + escapeJson(t.artist) + "\",";
        json += "\"durationMs\":" + std::to_string(t.duration);
        json += "}";
    }
    json += "]";
    return mallocStr(json);
}

char* ncore_get_artist_albums_json(NatsuyumeCore* core, const char* artistName) {
    if (!core || !artistName) return mallocStr("[]");

    auto albums = core->albumsForArtist(std::string(artistName));
    std::string json = "[";
    for (size_t i = 0; i < albums.size(); i++) {
        if (i > 0) json += ",";
        const std::string& name = albums[i];
        auto tracks = core->tracksForAlbum(name);

        int year = 0;
        for (const auto& t : tracks)
            if (t.year > year) year = t.year;

        json += "{";
        json += "\"title\":\"" + escapeJson(name) + "\",";
        json += "\"year\":" + std::to_string(year) + ",";
        json += "\"songCount\":" + std::to_string(tracks.size());
        json += "}";
    }
    json += "]";
    return mallocStr(json);
}

// ---------------------------------------------------------------------------
// Queue loading
// ---------------------------------------------------------------------------

void ncore_open_paths_in_new_queue(NatsuyumeCore* core,
                                   const char* pathsJson,
                                   int startIndex) {
    if (!core || !pathsJson) return;

    // Parse JSON array of strings: ["path1","path2",...]
    std::vector<std::string> paths;
    std::string json(pathsJson);

    // Simple parser — no dependencies, handles our own escaped output
    size_t pos = 0;
    while ((pos = json.find('"', pos)) != std::string::npos) {
        size_t start = pos + 1;
        size_t end = start;
        while (end < json.size()) {
            if (json[end] == '\\') { end += 2; continue; }
            if (json[end] == '"') break;
            end++;
        }
        if (end < json.size()) {
            // Unescape
            std::string raw = json.substr(start, end - start);
            std::string path;
            for (size_t i = 0; i < raw.size(); i++) {
                if (raw[i] == '\\' && i + 1 < raw.size()) {
                    switch (raw[i+1]) {
                        case '"':  path += '"';  i++; break;
                        case '\\': path += '\\'; i++; break;
                        case 'n':  path += '\n'; i++; break;
                        case 'r':  path += '\r'; i++; break;
                        case 't':  path += '\t'; i++; break;
                        default:   path += raw[i]; break;
                    }
                } else {
                    path += raw[i];
                }
            }
            paths.push_back(path);
        }
        pos = end + 1;
    }

    if (paths.empty()) return;

    core->openFilesInNewQueue(paths, "", false);

    if (startIndex > 0 && startIndex < (int)paths.size())
        core->jumpToTrack(startIndex);
}

// ---------------------------------------------------------------------------
// Cover art
// ---------------------------------------------------------------------------

// Returns heap-allocated raw image bytes for the given track path.
// If path matches the currently playing track, uses already-loaded bytes.
// Otherwise re-reads via Metadata::read(). Returns nullptr if no art.
// out_size  → byte count
// out_mime  → heap-allocated MIME string, free with ncore_free_string()
// Caller frees returned bytes with ncore_free_cover_bytes().
uint8_t* ncore_get_cover_bytes(NatsuyumeCore* core,
                                const char*    path,
                                int*           out_size,
                                char**         out_mime)
{
    if (!core || !path || !out_size || !out_mime) return nullptr;
    *out_size = 0;
    *out_mime = nullptr;

    const std::vector<uint8_t>* dataPtr  = nullptr;
    const std::string*          mimePtr  = nullptr;

    // Fast path: currently playing track already has bytes loaded
    Natsuyume::CoreTrack current = core->currentTrack();
    std::string requestedPath(path);

    Track tempTrack("");
    if (requestedPath == current.path && !current.coverArtData.empty()) {
        dataPtr = &current.coverArtData;
        mimePtr = &current.coverArtMimeType;
    } else {
        // Slow path: re-read via TagLib
        tempTrack = Metadata::read(requestedPath, true);
        if (tempTrack.coverArtData.empty()) return nullptr;
        dataPtr = &tempTrack.coverArtData;
        mimePtr = &tempTrack.coverArtMimeType;
    }

    if (!dataPtr || dataPtr->empty()) return nullptr;

    uint8_t* out = static_cast<uint8_t*>(malloc(dataPtr->size()));
    memcpy(out, dataPtr->data(), dataPtr->size());
    *out_size = static_cast<int>(dataPtr->size());
    *out_mime = static_cast<char*>(malloc(mimePtr->size() + 1));
    memcpy(*out_mime, mimePtr->c_str(), mimePtr->size() + 1);
    return out;
}

void ncore_free_cover_bytes(uint8_t* data) {
    free(data);
}

// Returns cover art for the first track of the named album.
// Dart doesn't need to know track paths — core handles the lookup.
uint8_t* ncore_get_cover_bytes_for_album(NatsuyumeCore* core,
                                          const char*    albumName,
                                          int*           out_size,
                                          char**         out_mime)
{
    if (!core || !albumName || !out_size || !out_mime) return nullptr;
    *out_size = 0;
    *out_mime = nullptr;

    auto tracks = core->tracksForAlbum(std::string(albumName));
    if (tracks.empty()) return nullptr;

    return ncore_get_cover_bytes(core,
                                  tracks.front().path.c_str(),
                                  out_size,
                                  out_mime);
}

// ---------------------------------------------------------------------------
// Lyrics
// ---------------------------------------------------------------------------

// Returns heap-allocated lyrics string for the given track path.
// Free with ncore_free_string().
// Returns an empty string (not nullptr) if no lyrics are found.
char* ncore_get_lyrics(NatsuyumeCore* core, const char* path)
{
    if (!core || !path) return mallocStr("");

    // Fast path: currently playing track
    Natsuyume::CoreTrack current = core->currentTrack();
    if (std::string(path) == current.path)
        return mallocStr(current.lyrics);

    // Slow path: re-read. includeCoverArt=false — we only want lyrics.
    Track t = Metadata::read(std::string(path), false);
    return mallocStr(t.lyrics);
}

void ncore_jump_to_track(NatsuyumeCore* core, int index) {
    if (core) core->jumpToTrack(index);
}

} // extern "C"