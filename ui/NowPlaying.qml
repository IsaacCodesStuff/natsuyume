import QtQuick
import QtQuick.Controls

// NowPlaying — the player core. Always visible, never replaced.
//
// Required properties:
//   theme  — reference to root Window for palette + formatTime()
//   player — the Player instance
//
// Signals:
//   coverArtTapped — toggle lyrics overlay (tablet + mobile)
//   openFilePicker — open the file picker overlay

Item {
    id: nowPlaying

    required property var theme
    required property var player

    property bool showLyricsOverlay: false

    signal coverArtTapped

    readonly property color bgColor:       theme.bgColor
    readonly property color surfaceColor:  theme.surfaceColor
    readonly property color elevatedColor: theme.elevatedColor
    readonly property color primaryText:   theme.primaryText
    readonly property color secondaryText: theme.secondaryText
    readonly property color mutedText:     theme.mutedText
    readonly property color accentColor:   theme.accentColor

    readonly property real artSize: Math.min(width * 0.52, 260)
    readonly property real sidePad: Math.max(width * 0.06, 20)

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    // ── Cover art ──────────────────────────────────────────────
    Rectangle {
        id: coverArtBlock
        width: artSize
        height: artSize
        radius: 16
        color: surfaceColor
        anchors.top: parent.top
        anchors.topMargin: Math.max(height * 0.08, 32)
        anchors.horizontalCenter: parent.horizontalCenter

        Image {
            anchors.fill: parent
            source: theme.coverArtSource
            fillMode: Image.PreserveAspectCrop
            visible: theme.coverArtSource !== ""
            layer.enabled: true
        }

        Text {
            anchors.centerIn: parent
            text: "♪"
            font.pixelSize: artSize * 0.28
            color: mutedText
            visible: theme.coverArtSource === ""
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            text: "tap for lyrics"
            font.pixelSize: 10
            color: Qt.rgba(1, 1, 1, 0.35)
            visible: !theme.isDesktop
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !theme.isDesktop
            onClicked: nowPlaying.coverArtTapped()
        }
    }

    // ── Metadata ───────────────────────────────────────────────
    Column {
        id: metadataBlock
        anchors.top: coverArtBlock.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        width: parent.width - sidePad * 2

        Text {
            text: player.trackTitle !== "" ? player.trackTitle : "No track loaded"
            font.pixelSize: 18
            font.weight: Font.Bold
            color: primaryText
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: player.trackArtist
            font.pixelSize: 14
            color: secondaryText
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: player.trackAlbum
            font.pixelSize: 12
            color: mutedText
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        // Favorite toggle
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: player.isFavorite ? "♥" : "♡"
            font.pixelSize: 26
            color: player.isFavorite ? accentColor : mutedText

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: player.toggleFavorite()
            }
        }
    }

    // ── Controls ───────────────────────────────────────────────
    Column {
        id: controlsBlock
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14
        width: parent.width - sidePad * 2

        // Position / duration labels
        Item {
            width: parent.width
            height: 16

            Text {
                text: theme.formatTime(player.position)
                font.pixelSize: 12
                color: mutedText
                anchors.left: parent.left
            }

            Text {
                text: theme.formatTime(player.duration)
                font.pixelSize: 12
                color: mutedText
                anchors.right: parent.right
            }
        }

        // Seek bar
        Slider {
            id: seekBar
            width: parent.width
            from: 0
            to: Math.max(player.duration, 1)
            value: player.position
            onMoved: player.seekTo(value)
        }

        // Playback buttons
        Row {
            spacing: 0
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width

            Repeater {
                model: [
                    { icon: "⏮", action: "previous"  },
                    { icon: "⏪", action: "rewind"    },
                    { icon: player.isPlaying ? "⏸" : "▶", action: "playpause" },
                    { icon: "⏩", action: "forward"   },
                    { icon: "⏭", action: "next"      }
                ]

                delegate: Item {
                    width: controlsBlock.width / 5
                    height: 48

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 24
                        color: {
                            if (modelData.action === "previous"
                                    && !player.hasPrevious
                                    && player.position <= 3000)
                                return mutedText
                            if (modelData.action === "next" && !player.hasNext)
                                return mutedText
                            return primaryText
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

        // Shuffle + Repeat
        Row {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                width: parent.width / 2
                height: 36

                Text {
                    anchors.centerIn: parent
                    text: "🔀"
                    font.pixelSize: 20
                    color: player.isShuffled ? accentColor : mutedText

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: player.toggleShuffle()
                    }
                }
            }

            Item {
                width: parent.width / 2
                height: 36

                Text {
                    anchors.centerIn: parent
                    text: player.repeatMode === 2 ? "🔂" : "🔁"
                    font.pixelSize: 20
                    color: player.repeatMode === 0 ? mutedText : accentColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: player.cycleRepeatMode()
                    }
                }
            }
        }

        // Volume row
        Row {
            width: parent.width
            spacing: 10

            Text {
                text: "🔈"
                font.pixelSize: 16
                color: mutedText
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                id: volumeSlider
                width: parent.width - 52
                from: 0.0
                to: 1.0
                value: 0.8
                onMoved: player.setVolume(value)
            }

            Text {
                text: "🔊"
                font.pixelSize: 16
                color: mutedText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            text: player.trackCount > 1
                  ? "Track " + (player.trackIndex + 1) + " of " + player.trackCount
                  : ""
            font.pixelSize: 12
            color: mutedText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // ── Lyrics overlay (tablet + mobile) ──────────────────────
    Lyrics {
        anchors.fill: parent
        theme: nowPlaying.theme
        player: nowPlaying.player
        overlayMode: true
        visible: nowPlaying.showLyricsOverlay && !theme.isDesktop

        onCloseRequested: nowPlaying.coverArtTapped()

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
}