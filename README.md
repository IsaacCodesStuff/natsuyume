# Natsuyume 夏夢

A music player for Android built for people who actually care about their music.

Natsuyume is a personal project inspired by Musicolet, built from scratch with a Flutter frontend and a pure C++ audio core. It is currently in active development toward its first public beta (0.9.0).

---

## What makes it different

**Multi-queue architecture.** Most music players have one queue. Natsuyume lets you maintain multiple named queues simultaneously and switch between them without losing your place. Load an album, load another, switch back — everything stays exactly where you left it.

**Pure C++ audio core.** The playback engine (`NatsuyumeCore` / `libnatsuyume_core.so`) is written entirely in C++ and communicates with Flutter via `dart:ffi`. It uses mpv + FFmpeg for gapless playback, TagLib for metadata, SQLite3 for the library database, and ICU for Unicode-correct sorting and normalization.

**Dynamic album art themes.** The UI color scheme shifts to match your album art. Vibrant, muted, monochrome, expressive — nine generation styles driven by `palette_generator`. Secret palettes can be unlocked by entering codes in the Easter egg screen.

**Synced lyrics.** Embedded LRC lyrics and `.lrc` sidecar files both work. The lyrics view auto-scrolls to follow playback with a Musicolet-style centered active line. Tapping a line seeks to that timestamp.

---

## Architecture

```
Flutter (Dart)
└── dart:ffi → natsuyume_bridge.cpp
               └── NatsuyumeCore (C++17)
                   ├── PlaybackManager → Queue → Playback (mpv)
                   ├── FileIndexer → Library (SQLite3)
                   ├── UserDataManager (SQLite3)
                   └── LrcParser
```

**Two databases:**
- `library.db` — discovered/reproducible data (tracks, albums, artists). Fully rebuildable from a rescan.
- `userdata.db` — user-owned data (play counts, favorites, playlists, settings, playback state). Never deleted on rescan.

---

## Status

| Feature | Status |
|---|---|
| Library scanning (FLAC, MP3, AAC, OGG) | ✅ Working |
| Gapless playback | ✅ Working |
| Multi-queue system | ✅ Working |
| Cover art (grid, detail, player) | ✅ Working |
| Synced + unsynced lyrics | ✅ Working |
| Dynamic color themes | ✅ Working |
| Secret palette system | ✅ Working |
| Theme persistence | ✅ Working |
| Playback state persistence (single queue) | ✅ Working |
| Track reordering in queue | ✅ Working |
| Album / artist detail views | ✅ Working |
| Onboarding flow | ✅ Working |
| Playlists | 🔲 Stub — planned for 0.9.0 |
| Multi-queue persistence | 🔲 Planned for 0.9.x |
| EQ / audio effects | 🔲 Not planned for 0.9.x |

See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for open bugs and deferred items.

---

## Build requirements

- Flutter 3.44.5
- Android NDK 28.2.13676358
- Android API 31, arm64-v8a only
- CMake 3.22+
- Prebuilt native libraries in `android/jni/`:
  - libmpv + FFmpeg (from [mpv-android](https://github.com/mpv-android/mpv-android) 2026-04-25 release)
  - TagLib (cross-compiled for arm64-v8a)
- ICU via NDK native (`unorm2` / `ucol`)
- SQLite3 amalgamation (bundled in `core/src/`)

```bash
flutter pub get
flutter run --debug
```

Target device: Samsung Galaxy A06 (Android 16 / SDK 36). Other Android 12+ devices should work but are untested.

---

## Project structure

```
natsuyume/
├── lib/                    # Flutter/Dart frontend
│   ├── core/               # FFI bindings, NatsuyumeCore wrapper, CoverService
│   ├── onboarding/         # First-launch flow
│   ├── player/             # Main app shell and screens
│   │   └── screens/        # Queue, Albums, Artists, Playlists, NowPlaying, etc.
│   ├── theme/              # NatsuyumeTheme, ThemeRegistry, color system
│   └── widgets/            # Shared widgets (FloatingMiniPlayer, MiniPlayer, etc.)
├── core/                   # C++ audio core (NatsuyumeCore)
│   └── src/
│       ├── core/           # NatsuyumeCore, PlaybackManager, QueueSession
│       ├── domain/         # Track, Album, Artist data types
│       ├── library/        # FileIndexer, Library, Metadata, LrcParser
│       └── player/         # Queue, Playback (mpv wrapper)
└── android/
    ├── app/src/main/cpp/   # FFI bridge (natsuyume_bridge.cpp)
    └── jni/                # Prebuilt native libraries and headers
```

---

## Versioning

- `0.x.x` — pre-release development builds
- `0.9.0` — first public beta (target)
- `1.0.0` — stable release

---

## License

Personal project. Not licensed for distribution or modification without permission.
