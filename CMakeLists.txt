cmake_minimum_required(VERSION 3.16)
project(natsuyume_player VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia QuickControls2 Sql QuickDialogs2)
find_package(PkgConfig REQUIRED)
pkg_check_modules(TAGLIB REQUIRED taglib)
find_library(MPV_LIBRARIES NAMES mpv REQUIRED)
set(MPV_INCLUDE_DIRS "/usr/include")

qt_standard_project_setup(REQUIRES 6.10)

# ---------------------------------------------------------------------------
# natsuyume_core — static library shared by GUI and CLI
# ---------------------------------------------------------------------------
qt_add_library(natsuyume_core STATIC
    core/coretypes.h
    core/natsuyumecore.h core/natsuyumecore.cpp
    core/lrcparser.h core/lrcparser.cpp
    domain/track.h domain/track.cpp
    library/fileindexer.h library/fileindexer.cpp
    library/library.h library/library.cpp
    library/metadata.h library/metadata.cpp
    playback/playback.h playback/playback.cpp
    playback/queue.h playback/queue.cpp
    player/queuesession.h player/queuesession.cpp
    player/queuemanager.h player/queuemanager.cpp
    player/playbackmanager.h player/playbackmanager.cpp
    player/playlistmanager.h player/playlistmanager.cpp
    player/librarymanager.h player/librarymanager.cpp
)

target_include_directories(natsuyume_core PUBLIC
    ${TAGLIB_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/domain
    ${CMAKE_CURRENT_SOURCE_DIR}/library
    ${CMAKE_CURRENT_SOURCE_DIR}/playback
    ${CMAKE_CURRENT_SOURCE_DIR}/player
    ${MPV_INCLUDE_DIRS}
)

target_link_libraries(natsuyume_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Sql
    ${TAGLIB_LIBRARIES}
    ${MPV_LIBRARIES}
)

# ---------------------------------------------------------------------------
# appnatsuyume_player — GUI application
# ---------------------------------------------------------------------------
qt_add_executable(appnatsuyume_player
    main.cpp
)

qt_add_qml_module(appnatsuyume_player
    URI natsuyume_player
    VERSION 1.0
    QML_FILES
        Main.qml
        ui/NavBar.qml
        ui/Sidebar.qml
        ui/NowPlaying.qml
        ui/Lyrics.qml
        ui/AlbumCover.qml
        ui/ContextMenu.qml
        ui/SongInfo.qml
        ui/SortBar.qml
        ui/TrackRow.qml
        ui/sidebar/SettingsView.qml
        ui/sidebar/QueuesView.qml
        ui/sidebar/ArtistsView.qml
        ui/sidebar/AlbumsView.qml
        ui/sidebar/albums/AlbumGrid.qml
        ui/sidebar/albums/AlbumTrackList.qml
        ui/sidebar/artists/ArtistTrackList.qml
        ui/sidebar/queues/QueueTopBar.qml
        ui/sidebar/queues/QueueTrackList.qml
        ui/sidebar/queues/QueueDropdown.qml
        ui/sidebar/queues/QueueAddButton.qml
        ui/sidebar/queues/SaveAsPlaylistDialog.qml
        ui/PlaylistPicker.qml
        ui/sidebar/playlists/PlaylistTrackList.qml
        ui/sidebar/PlaylistsView.qml
        ui/QueuePicker.qml
        ui/sidebar/queues/QueueSortMenu.qml
    SOURCES
        core/coverimageprovider.h core/coverimageprovider.cpp
        core/albumcoverprovider.h core/albumcoverprovider.cpp
        core/trackcoverprovider.h core/trackcoverprovider.cpp
        player/playercontroller.h player/playercontroller.cpp
)

target_link_libraries(appnatsuyume_player PRIVATE
    natsuyume_core
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::Quick
)

set_target_properties(appnatsuyume_player PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# ---------------------------------------------------------------------------
# appnatsuyume_cli — headless validation binary
# ---------------------------------------------------------------------------
qt_add_executable(appnatsuyume_cli
    cli/main_cli.cpp
)

target_link_libraries(appnatsuyume_cli PRIVATE
    natsuyume_core
    Qt6::Core
)

install(TARGETS appnatsuyume_player appnatsuyume_cli
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)