# Known Issues & Deferred Items

This document tracks open bugs, limitations, and features deferred from 0.8.x to future releases.

---

## Open bugs

### Seek bar — irregular behavior on manual track change
**Severity:** Medium  
**Status:** Partially fixed. Automatic track advance now updates the seek bar and metadata correctly. Manual track changes (tapping a track in the queue) occasionally show stale position for one poll tick before correcting. The 250ms poll interval means this is imperceptible in most cases but can appear as a brief freeze on slower devices.  
**Root cause:** mpv reports `time-pos` asynchronously after `seek`; the Dart poll may read a stale value on the first tick after a manual jump.  
**Planned fix:** 0.9.x — investigate per-seek position acknowledgment from mpv.

---

## Deferred to 0.9.0

### Playlists
The Playlists tab exists in the navigation bar but is a stub. Tapping it shows a placeholder screen.  
Full playlist CRUD (create, rename, delete, add/remove tracks, reorder, play) is planned for 0.9.0.

---

## Deferred to 0.9.x

### Multi-queue persistence
On app restart, only the single playing queue is restored (track list, active track, and position). Additional queues loaded in the same session are lost on restart.  
**Planned approach:** Dedicated `queues` and `queue_tracks` tables in `userdata.db` instead of the current newline-separated string in the settings table. The JSON blob approach was attempted and abandoned due to UTF-8 path encoding issues with the hand-rolled parser.

### Queue rename not reflected instantly in top bar
Renaming a queue from the dropdown updates the name in core immediately, but the top bar display only updates on the next `_refreshTracks` poll tick (≤250ms). Effectively invisible in practice but technically a one-tick lag.

---

## Known limitations

### arm64-v8a only
The native library build targets arm64-v8a exclusively. x86_64 (emulator) and 32-bit ARM are not supported. This is intentional for the pre-beta period.

### No cloud/network features
Natsuyume is a local music player. No streaming, no cloud sync, no online metadata lookup. This is by design.

### Playlists not yet implemented
See above.

### EQ and audio effects
No equalizer or DSP effects are planned for 0.9.x. mpv supports these natively and they may be added in a later release.

### Last.fm / scrobbling
Not implemented. May be considered post-1.0.

---

## Fixed in 0.8.x (formerly open)

| Issue | Resolution |
|---|---|
| Unsynced lyrics not showing in lyrics view | Fixed — plain text fallback path added to LyricsView |
| Album detail view not rendering cover art | Fixed — FutureBuilder wiring corrected, async load via CoverService |
| Queue list showing "Queue 1" instead of album name | Fixed — `openPathsInNewQueueNamed` now passes album/artist name |
| Queue dropdown non-functional | Fixed — QueueDialog callbacks wired to core |
| Deleted queues restoring themselves | Fixed — mutations now go through core, not local state |
| Queue track reordering not working | Fixed — ReorderableListView with ReorderableDragStartListener on handle only |
| Track looping after advancing one track | Fixed — `onTrackAdvancedGapless` callback chain was being overwritten by PlaybackManager; both Queue and PlaybackManager callbacks now chained correctly |
| Track metadata not updating in MiniPlayer/NowPlaying after auto-advance | Fixed — same root cause as above |
| Seek bar freezing after seeking | Fixed — `audio-stream-silence=yes` mpv option prevents AAudio pipeline stall on 96kHz FLAC files; `core-idle=true` during seek now ignored via `m_justSeeked` flag |
| RangeError on queue index -1 | Fixed — queue index clamped before use |
| Theme not persisting across restarts | Fixed — ThemeRegistry saves to SharedPreferences on every mutation, loads before first frame |
