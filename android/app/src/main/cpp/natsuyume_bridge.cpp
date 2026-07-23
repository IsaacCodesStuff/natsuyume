#include "natsuyumecore.h"
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

} // extern "C"