import QtQuick

// NavBar — unified navigation bar present on all three breakpoints.
//
// On desktop + tablet:
//   Tabs = Queues, Albums, Artists, Playlists, Settings
//
// On mobile:
//   Tabs = Now Playing, Queues, Albums, Artists, Playlists, Settings
//   The extra "Now Playing" tab switches the full stack view.
//
// Signals:
//   tabSelected(index) — emitted on tap

Item {
    id: navBar
    height: 54

    required property var  theme
    required property int  activeIndex
    property bool isMobile: false

    signal tabSelected(int index)

    readonly property color surfaceColor: theme.surfaceColor
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    // Desktop + tablet tabs
    readonly property var desktopTabs: [
        { label: "Queues"    },
        { label: "Albums"    },
        { label: "Artists"   },
        { label: "Playlists" },
        { label: "Settings"  }
    ]

    // Mobile tabs (Now Playing first)
    readonly property var mobileTabs: [
        { label: "Playing"   },
        { label: "Queues"    },
        { label: "Albums"    },
        { label: "Artists"   },
        { label: "Playlists" },
        { label: "Settings"  }
    ]

    readonly property var tabs: isMobile ? mobileTabs : desktopTabs

    // Background
    Rectangle {
        anchors.fill: parent
        color: surfaceColor

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }
    }

    // Tab strip — scrollable on mobile where 6 tabs overflow
    ListView {
        id: tabList
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 0
        clip: true
        interactive: isMobile
        snapMode: isMobile ? ListView.SnapToItem : ListView.NoSnap
        flickDeceleration: 1500
        model: navBar.tabs

        delegate: Item {
            id: tabDelegate
            width: isMobile
                   ? Math.max(navBar.width / 4, 64)
                   : navBar.width / navBar.tabs.length
            height: navBar.height

            readonly property bool isActive: index === navBar.activeIndex

            // Active top accent indicator
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: isActive ? 24 : 0
                height: 2
                radius: 1
                color: accentColor

                Behavior on width {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }

            Text {
                anchors.centerIn: parent
                text: modelData.label
                font.pixelSize: 10
                color: isActive ? accentColor : mutedText

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: navBar.tabSelected(index)
            }
        }
    }
}