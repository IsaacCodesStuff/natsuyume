import QtQuick
import QtQuick.Controls

Item {
    id: nowPlaying

    required property var theme
    required property var player

    property bool showLyricsOverlay: false
    property bool showLyricsInArtArea: false  // replaces art with lyrics on mobile/tablet

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

    // ── Art / Lyrics toggle area ───────────────────────────────
    Item {
        id: artArea
        width: artSize
        height: (nowPlaying.showLyricsInArtArea && !theme.isDesktop)
                ? artSize * 1.6    // taller when showing lyrics
                : artSize
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Album art
        Rectangle {
            id: coverArtBlock
            anchors.fill: parent
            radius: 16
            color: surfaceColor
            visible: !nowPlaying.showLyricsInArtArea || theme.isDesktop

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

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !theme.isDesktop
                onClicked: nowPlaying.showLyricsInArtArea = true
            }
        }

        // Lyrics in art area (mobile/tablet only)
        Lyrics {
            anchors.fill: parent
            theme: nowPlaying.theme
            player: nowPlaying.player
            overlayMode: false
            artMode: true
            visible: nowPlaying.showLyricsInArtArea && !theme.isDesktop

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: nowPlaying.showLyricsInArtArea = false
            }
        }
    }

    // ── Metadata ───────────────────────────────────────────────
    Column {
        id: metadataBlock
        anchors.top: artArea.bottom
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
    }

    // ── Quick access bar ───────────────────────────────────────
    Item {
        id: quickAccessBar
        anchors.top: metadataBlock.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: sidePad
        anchors.rightMargin: sidePad
        height: 44

        ListView {
            id: quickAccessList
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 4
            clip: true

            model: [
                {
                    icon: player.isFavorite ? "♥" : "♡",
                    label: "Favorite",
                    active: player.isFavorite,
                    onTapped: function() { player.toggleFavorite() }
                },
                {
                    icon: "ℹ",
                    label: "Song info",
                    active: false,
                    onTapped: function() { quickAccessSongInfo.open(player.trackPath) }
                },
                {
                    icon: "🎵",
                    label: "Lyrics",
                    active: nowPlaying.showLyricsInArtArea,
                    onTapped: function() {
                        if (theme.isDesktop) {
                            // on desktop lyrics panel is always visible
                        } else {
                            nowPlaying.showLyricsInArtArea = !nowPlaying.showLyricsInArtArea
                        }
                    }
                },
                {
                    icon: "≡+",
                    label: "Add to playlist",
                    active: false,
                    onTapped: function() { player.requestAddToPlaylist(player.trackPath) }
                },
                {
                    icon: "⏹",
                    label: "Stop after",
                    active: player.stopAfterCurrent,
                    onTapped: function() { player.toggleStopAfterCurrent() }
                },
                {
                    icon: "⇌",
                    label: "A-B Repeat",
                    active: false,
                    onTapped: function() { /* placeholder */ }
                }
            ]

            delegate: Item {
                width: 60
                height: quickAccessList.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 8
                    color: modelData.active
                           ? Qt.rgba(accentColor.r, accentColor.g,
                                     accentColor.b, 0.18)
                           : Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.pixelSize: 16
                            color: modelData.active ? accentColor : mutedText
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.pixelSize: 7
                            color: modelData.active ? accentColor : mutedText
                            elide: Text.ElideRight
                            width: 54
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.onTapped()
                    }
                }
            }
        }
    }

    // ── Song info dialog ───────────────────────────────────────
    SongInfo {
        id: quickAccessSongInfo
        theme: nowPlaying.theme
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
                            if (modelData.action === "playpause")
                                return accentColor
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

        // Shuffle + Repeat + Stop
        Row {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                width: parent.width / 3
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
                width: parent.width / 3
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

            Item {
                width: parent.width / 3
                height: 36

                Text {
                    anchors.centerIn: parent
                    text: "⏹"
                    font.pixelSize: 20
                    color: player.stopAfterCurrent ? accentColor : mutedText

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: player.toggleStopAfterCurrent()
                    }
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: accentColor
                    visible: player.stopAfterCurrent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
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
                value: player.volume
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
}