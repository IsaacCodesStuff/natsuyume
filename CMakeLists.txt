cmake_minimum_required(VERSION 3.16)
project(natsuyume_player VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia QuickControls2 Sql QuickDialogs2)
find_package(PkgConfig REQUIRED)
pkg_check_modules(TAGLIB REQUIRED taglib)

qt_standard_project_setup(REQUIRES 6.10)

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
        ui/FilePicker.qml
        ui/AlbumCover.qml
        ui/ContextMenu.qml
        ui/sidebar/SettingsView.qml
        ui/sidebar/QueuesView.qml
        ui/sidebar/albums/AlbumSortBar.qml
        ui/sidebar/albums/TrackSortBar.qml
        ui/sidebar/albums/AlbumGrid.qml
        ui/sidebar/albums/AlbumTrackList.qml
        ui/sidebar/AlbumsView.qml
        ui/sidebar/queues/QueueTopBar.qml
        ui/sidebar/queues/QueueTrackList.qml
        ui/sidebar/queues/QueueDropdown.qml
        ui/sidebar/queues/QueueAddButton.qml
    SOURCES
        core/trackcoverprovider.h core/trackcoverprovider.cpp
        core/albumcoverprovider.h core/albumcoverprovider.cpp
        core/coverimageprovider.h core/coverimageprovider.cpp
        core/fileindexer.h core/fileindexer.cpp
        core/library.h core/library.cpp
        core/track.h core/track.cpp
        core/player.h core/player.cpp
        manager/playback.h manager/playback.cpp
        manager/metadata.h manager/metadata.cpp
        manager/queue.h manager/queue.cpp
        QML_FILES ui/SongInfo.qml
)

set_target_properties(appnatsuyume_player PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(appnatsuyume_player PRIVATE
    ${TAGLIB_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/manager
)

target_link_libraries(appnatsuyume_player PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Qt6::QuickControls2
    Qt6::Sql
    Qt6::QuickDialogs2
    ${TAGLIB_LIBRARIES}
)

install(TARGETS appnatsuyume_player
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)