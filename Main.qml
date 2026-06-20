import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import natsuyume_player
import "ui"

Window {
    id: root
    width: 1024
    height: 680
    minimumWidth: 360
    minimumHeight: 520
    visible: true
    title: "Natsuyume"
    onClosing: function(close) {
        root.visible = false
        player.saveQueues()
        player.saveSettings()
        close.accepted = true
    }

    // ── Player instance ────────────────────────────────────────
    Player {
        id: player
    }

    // ── Shared dialogs ─────────────────────────────────────────
    PlaylistPicker {
        id: playlistPicker
        theme: root
    }

    QueuePicker {
        id: queuePicker
        theme: root
    }

    Connections {
        target: player
        function onAddToPlaylistRequested(path) {
            playlistPicker.open(path)
        }
        function onAddAlbumToPlaylistRequested(albumName) {
            playlistPicker.openForAlbum(albumName)
        }
        function onAddToQueueRequested(paths) {
            queuePicker.open(paths)
        }
    }

    // ── Breakpoints ────────────────────────────────────────────
    readonly property bool isDesktop: width >= 1024
    readonly property bool isTablet:  width >= 600 && width < 1024
    readonly property bool isMobile:  width < 600

    // ── Color palette ──────────────────────────────────────────
    property color bgColor:       "#49494B"
    property color surfaceColor:  "#8D5FAE"
    property color elevatedColor: "#C193BF"
    property color primaryText:   "#FFFFFF"
    property color secondaryText: "#F6E8DC"
    property color mutedText:     "#428EC5"
    property color accentColor:   "#90BFF9"

    // ── Global state ───────────────────────────────────────────
    property string coverArtPath: ""
    property bool   showLyrics: false
    property int    currentTab: 0

    // Mobile-specific state
    property int mobileTabIndex:   0
    property int mobilePanelIndex: 0

    color: bgColor

    // ── Cover art handler ──────────────────────────────────────
    Connections {
        target: player
        function onCoverArtChanged() {
            coverArtSource = "image://covers/current?t=" + Date.now()
        }
    }

    property string coverArtSource: ""

    // ── Desktop layout ─────────────────────────────────────────
    Loader {
        id: desktopLayout
        anchors.fill: parent
        active: isDesktop
        sourceComponent: desktopComponent
    }

    Component {
        id: desktopComponent
        Item {
            readonly property var playerRef: player  // capture outer id

            Row {
                id: desktopPanels
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: desktopNavBar.top
                spacing: 0

                Sidebar {
                    width: Math.round(parent.width * 0.26)
                    height: parent.height
                    theme: root
                    currentTab: root.currentTab
                }

                NowPlaying {
                    width: parent.width
                           - Math.round(desktopPanels.width * 0.26)
                           - Math.round(desktopPanels.width * 0.22)
                    height: parent.height
                    theme: root
                    player: playerRef
                    showLyricsOverlay: false
                }

                Lyrics {
                    width: Math.round(parent.width * 0.22)
                    height: parent.height
                    theme: root
                    player: playerRef
                    overlayMode: false
                }
            }

            NavBar {
                id: desktopNavBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                theme: root
                isMobile: false
                activeIndex: root.currentTab
                onTabSelected: function(index) { root.currentTab = index }
            }
        }
    }

    // ── Tablet layout ──────────────────────────────────────────
    Loader {
        id: tabletLayout
        anchors.fill: parent
        active: isTablet
        sourceComponent: tabletComponent
    }

    Component {
        id: tabletComponent
        Item {
            readonly property var playerRef: player  // capture outer id

            Row {
                id: tabletPanels
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: tabletNavBar.top
                spacing: 0

                Sidebar {
                    width: Math.round(parent.width * 0.38)
                    height: parent.height
                    theme: root
                    currentTab: root.currentTab
                }

                NowPlaying {
                    width: parent.width - Math.round(tabletPanels.width * 0.38)
                    height: parent.height
                    theme: root
                    player: playerRef
                }
            }

            NavBar {
                id: tabletNavBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                theme: root
                isMobile: false
                activeIndex: root.currentTab
                onTabSelected: function(index) { root.currentTab = index }
            }
        }
    }

    // ── Mobile layout ──────────────────────────────────────────
    Loader {
        id: mobileLayout
        anchors.fill: parent
        active: isMobile
        sourceComponent: mobileComponent
    }

    Component {
        id: mobileComponent
        Item {
            readonly property var playerRef: player  // capture outer id

            StackLayout {
                id: mobileStack
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: mobileNavBar.top
                currentIndex: root.mobilePanelIndex

                NowPlaying {
                    theme: root
                    player: playerRef
                }

                Sidebar {
                    theme: root
                    currentTab: root.currentTab
                }
            }

            NavBar {
                id: mobileNavBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                theme: root
                isMobile: true
                activeIndex: root.mobileTabIndex
                onTabSelected: function(index) {
                    root.mobileTabIndex = index
                    root.mobilePanelIndex = index === 0 ? 0 : 1
                    if (index > 0) root.currentTab = index - 1
                }
            }
        }
    }

    // ── Helpers ────────────────────────────────────────────────
    function formatTime(ms) {
        let totalSeconds = Math.floor(ms / 1000)
        let minutes = Math.floor(totalSeconds / 60)
        let seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}