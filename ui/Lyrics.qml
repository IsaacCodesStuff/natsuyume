import QtQuick
import QtQuick.Controls

// Lyrics — two modes:
//
//   overlayMode: false — desktop column, sits alongside NowPlaying
//   overlayMode: true  — overlay covering NowPlaying on tablet + mobile,
//                        with playback controls replicated at the bottom
//
// Required properties:
//   theme  — reference to root Window for palette access
//   player — the Player instance
//
// Signal:
//   closeRequested — emitted when user taps close in overlay mode

Item {
    id: lyrics

    required property var  theme
    required property var  player
    required property bool overlayMode

    signal closeRequested

    readonly property color bgColor:       theme.bgColor
    readonly property color surfaceColor:  theme.surfaceColor
    readonly property color primaryText:   theme.primaryText
    readonly property color secondaryText: theme.secondaryText
    readonly property color mutedText:     theme.mutedText
    readonly property color accentColor:   theme.accentColor

    // ── Desktop column background ──────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: surfaceColor
        visible: !overlayMode
    }

    // ── Overlay background ─────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.27, 0.09, 0.18, 0.96)
        visible: overlayMode
        radius: 16
    }

    // ── Header ─────────────────────────────────────────────────
    Row {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: overlayMode ? 14 : 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 24

        Rectangle {
            width: syncedLabel.implicitWidth + 16
            height: 22
            radius: 11
            color: Qt.rgba(1, 1, 1, 0.08)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: syncedLabel
                anchors.centerIn: parent
                text: player.lyricsAreSynced ? "Synced" : "Lyrics"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: secondaryText
            }
        }

        Item {
            width: parent.width
                   - syncedLabel.implicitWidth - 16
                   - (overlayMode ? closeBtn.implicitWidth + 8 : 0)
            height: 1
        }

        Text {
            id: closeBtn
            text: "✕  close"
            font.pixelSize: 10
            color: mutedText
            visible: overlayMode
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: lyrics.closeRequested()
            }
        }
    }

    // ── Lyrics list ────────────────────────────────────────────
    // TODO: wire to real synced lyrics model once backend supports it
    ListView {
        id: lyricsList
        anchors.top: headerRow.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: overlayMode ? overlayControls.top : parent.bottom
        anchors.bottomMargin: overlayMode ? 8 : 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        clip: true
        spacing: 14

        model: player.lyricsAreSynced
            ? player.lyricLines
            : plainLyrics.lines

        delegate: Text {
            required property var modelData
            required property int index
            width: lyricsList.width
            text: player.lyricsAreSynced ? modelData.text : modelData
            font.pixelSize: isCurrent ? 15 : 12
            font.weight:    isCurrent ? Font.Medium : Font.Normal
            color: isCurrent ? lyrics.primaryText : lyrics.secondaryText
            opacity: isCurrent ? 1.0 : (overlayMode ? 0.45 : 0.6)
            wrapMode: Text.WordWrap

            readonly property bool isCurrent: {
                if (!player.lyricsAreSynced) return false
                const pos = player.position
                const next = index + 1
                const nextTs = next < lyricsList.count
                    ? player.lyricLines[next].timestamp
                    : Infinity
                return pos >= modelData.timestamp && pos < nextTs
            }

            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
        }

        // Auto-scroll to current line
        onCountChanged: currentIndex = 0

        Connections {
            target: player
            function onPositionChanged() {
                for (let i = lyricsList.count - 1; i >= 0; i--) {
                    if (player.position >= player.lyricLines[i].timestamp) {
                        lyricsList.currentIndex = i
                        lyricsList.positionViewAtIndex(i, ListView.Center)
                        break
                    }
                }
            }
        }

        QtObject {
            id: plainLyrics
            property var lines: player.rawLyrics.length > 0 ? player.rawLyrics.split('\n') : []
        }
    }

    // ── Overlay controls (tablet + mobile only) ────────────────
    Column {
        id: overlayControls
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8
        visible: overlayMode

        // Seek bar
        Item {
            width: parent.width
            height: 28

            Slider {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: Math.max(player.duration, 1)
                value: player.position
                onMoved: player.seekTo(value)
            }
        }

        // Playback buttons
        Row {
            width: parent.width
            spacing: 0

            Repeater {
                model: [
                    { icon: "⏮", action: "previous"  },
                    { icon: "⏪", action: "rewind"    },
                    { icon: player.isPlaying ? "⏸" : "▶", action: "playpause" },
                    { icon: "⏩", action: "forward"   },
                    { icon: "⏭", action: "next"      }
                ]

                delegate: Item {
                    width: overlayControls.width / 5
                    height: 44

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 22
                        color: {
                            if (modelData.action === "previous"
                                    && !player.hasPrevious
                                    && player.position <= 3000)
                                return mutedText
                            if (modelData.action === "next" && !player.hasNext)
                                return mutedText
                            if (modelData.action === "playpause")
                                return accentColor
                            return "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "previous")
                                    player.playPrevious()
                                else if (modelData.action === "rewind")
                                    player.seekTo(Math.max(0, player.position - 10000))
                                else if (modelData.action === "playpause")
                                    player.isPlaying ? player.pause() : player.play()
                                else if (modelData.action === "forward")
                                    player.seekTo(Math.min(player.duration, player.position + 10000))
                                else if (modelData.action === "next")
                                    player.playNext()
                            }
                        }
                    }
                }
            }
        }
    }
}