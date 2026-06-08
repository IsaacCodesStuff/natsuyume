import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import natsuyume_player

Window {
    id: root
    width: 1024
    height: 680
    minimumWidth: 360
    minimumHeight: 520
    visible: true
    title: "Natsuyume"

    // ── Player instance ────────────────────────────────────────
    Player {
        id: player
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
    property bool   showFilePicker: false
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
            if (player.hasCoverArt) {
                coverArtSource = "image://covers/current?t=" + Date.now()
            } else {
                coverArtSource = ""
            }
        }
    }

    property string coverArtSource: ""

    // ── Desktop layout ─────────────────────────────────────────
    Item {
        id: desktopLayout
        anchors.fill: parent
        visible: isDesktop

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
                player: player
                showLyricsOverlay: false
                onOpenFilePicker: root.showFilePicker = true
            }

            Lyrics {
                width: Math.round(parent.width * 0.22)
                height: parent.height
                theme: root
                player: player
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

    // ── Tablet layout ──────────────────────────────────────────
    Item {
        id: tabletLayout
        anchors.fill: parent
        visible: isTablet

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
                player: player
                showLyricsOverlay: root.showLyrics
                onCoverArtTapped: root.showLyrics = !root.showLyrics
                onOpenFilePicker: root.showFilePicker = true
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

    // ── Mobile layout ──────────────────────────────────────────
    Item {
        id: mobileLayout
        anchors.fill: parent
        visible: isMobile

        StackLayout {
            id: mobileStack
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: mobileNavBar.top
            currentIndex: root.mobilePanelIndex

            NowPlaying {
                theme: root
                player: player
                showLyricsOverlay: root.showLyrics
                onCoverArtTapped: root.showLyrics = !root.showLyrics
                onOpenFilePicker: root.showFilePicker = true
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

    // ── File picker overlay ────────────────────────────────────
    FilePicker {
        id: filePicker
        visible: showFilePicker
        anchors.fill: parent
        z: 10
        theme: root

        onFilesSelected: function(paths) {
            player.openFilesInNewQueue(paths)
            showFilePicker = false
        }
        onCancelled: {
            showFilePicker = false
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