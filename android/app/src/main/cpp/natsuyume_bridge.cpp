#include "natsuyumecore.h"
#include <cstring>
#include <cstdlib>

using Natsuyume::NatsuyumeCore;

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

void ncore_pump_events(NatsuyumeCore* core) {
    if (core) core->pumpEvents();
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

int ncore_is_playing(NatsuyumeCore* core) {
    if (!core) return 0;
    return core->isPlaying() ? 1 : 0;
}

double ncore_get_position(NatsuyumeCore* core) {
    if (!core) return 0.0;
    return static_cast<double>(core->position()) / 1000.0;
}

double ncore_get_duration(NatsuyumeCore* core) {
    if (!core) return 0.0;
    return static_cast<double>(core->duration()) / 1000.0;
}

} // extern "C"