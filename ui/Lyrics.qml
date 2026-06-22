import QtQuick
import QtQuick.Controls

Item {
    id: lyrics

    required property var  theme
    required property var  player
    required property bool overlayMode
    property bool artMode: false

    signal closeRequested

    readonly property color bgColor:      theme.bgColor
    readonly property color surfaceColor: theme.surfaceColor
    readonly property color primaryText:  theme.primaryText
    readonly property color secondaryText:theme.secondaryText
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    // Text size state — toggled by Tt button
    property bool largeText: false
    readonly property int baseFontSize:    largeText ? 16 : 13
    readonly property int currentFontSize: largeText ? 19 : 15

    // ── Desktop column background ──────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: surfaceColor
        visible: !overlayMode && !artMode
    }

    // ── Overlay background ─────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            lyrics.theme.bgColor.r * 0.6,
            lyrics.theme.bgColor.g * 0.6,
            lyrics.theme.bgColor.b * 0.6,
            0.97)
        visible: overlayMode && !artMode
        radius: overlayMode ? 0 : 0
    }

    // ── Header ─────────────────────────────────────────────────
    Item {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 14
        height: visible ? 36 : 0
        visible: !artMode

        // Source indicator pill
        Rectangle {
            id: sourcePill
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: sourceLabel.implicitWidth + 20
            height: 26
            radius: 13
            color: Qt.rgba(1, 1, 1, 0.08)

            Row {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    id: sourceLabel
                    text: player.lyricsAreSynced ? "Synced lyrics" : "Embedded lyrics"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: lyrics.secondaryText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "▾"
                    font.pixelSize: 9
                    color: lyrics.secondaryText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Stage 2: lyrics source picker — not yet implemented
                }
            }
        }

        // Right-side controls
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Text size toggle
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: lyrics.largeText
                       ? Qt.rgba(lyrics.accentColor.r, lyrics.accentColor.g,
                                 lyrics.accentColor.b, 0.18)
                       : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "Tt"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: lyrics.largeText ? lyrics.accentColor : lyrics.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lyrics.largeText = !lyrics.largeText
                }
            }

            // Close button (overlay/artMode only)
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                visible: overlayMode || artMode

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 13
                    color: lyrics.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lyrics.closeRequested()
                }
            }
        }
    }

    // ── Lyrics list ────────────────────────────────────────────
    ListView {
        id: lyricsList
        anchors.top: artMode ? parent.top : headerRow.bottom
        anchors.topMargin: artMode ? 8 : 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: (overlayMode && !artMode) ? overlayControls.top : parent.bottom
        anchors.bottomMargin: 12
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        clip: true
        spacing: 18

        model: player.lyricsAreSynced
            ? player.lyricLines
            : plainLyrics.lines

        delegate: Text {
            required property var modelData
            required property int index
            width: lyricsList.width
            text: player.lyricsAreSynced ? modelData.text : modelData
            font.pixelSize: isCurrent ? lyrics.currentFontSize : lyrics.baseFontSize
            font.weight:    isCurrent ? Font.SemiBold : Font.Normal
            color: isCurrent ? lyrics.primaryText : lyrics.secondaryText
            opacity: isCurrent ? 1.0 : (overlayMode || artMode ? 0.45 : 0.65)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter

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

        onCountChanged: currentIndex = 0

        Connections {
            target: player
            function onPositionChanged() {
                if (!player.lyricsAreSynced || !player.lyricLines || player.lyricLines.length === 0)
                    return
                for (let i = lyricsList.count - 1; i >= 0; i--) {
                    let line = player.lyricLines[i]
                    if (!line) continue
                    if (player.position >= line.timestamp) {
                        lyricsList.currentIndex = i
                        lyricsList.positionViewAtIndex(i, ListView.Center)
                        break
                    }
                }
            }
        }

        QtObject {
            id: plainLyrics
            property var lines: player.rawLyrics.length > 0
                ? player.rawLyrics.split('\n').filter(l => l.trim() !== '')
                : []
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
        visible: overlayMode && !artMode

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