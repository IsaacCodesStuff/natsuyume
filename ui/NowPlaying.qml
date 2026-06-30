import QtQuick
import QtQuick.Controls

Item {
    id: nowPlaying

    required property var theme
    required property var player

    property bool showLyricsOverlay: false
    property bool showLyricsInArtArea: false

    signal coverArtTapped

    readonly property color bgColor:       theme.bgColor
    readonly property color surfaceColor:  theme.surfaceColor
    readonly property color elevatedColor: theme.elevatedColor
    readonly property color primaryText:   theme.primaryText
    readonly property color secondaryText: theme.secondaryText
    readonly property color mutedText:     theme.mutedText
    readonly property color accentColor:   theme.accentColor

    readonly property real sidePad: Math.max(width * 0.06, 16)

    // Layout mode thresholds
    readonly property bool isMedium: height < 580
    readonly property bool isTall:   height >= 580

    // Reserve space for everything below the art area:
    // metadata (~3 lines), quick access bar, controls block, and margins.
    readonly property real reservedBottomHeight: {
        let metaHeight = isMedium ? 80 : 90   // approx 3 lines + spacing
        let quickAccessHeight = 44 + 8
        let controlsHeight = (isMedium ? 16 : 24) * 2 + (isMedium ? 8 : 12) * 3
            + 16 + 32 + (isMedium ? 40 : 48) + (isMedium ? 28 : 36) + 32
        return metaHeight + quickAccessHeight + controlsHeight
    }

    readonly property real availableArtHeight: Math.max(60, height - reservedBottomHeight - 16)

    // Art size adapts to layout mode, constrained by both width and available height
    readonly property real artSize: {
        let byWidth = isMedium ? Math.min(width * 0.42, 180) : Math.min(width * 0.52, 240)
        return Math.min(byWidth, availableArtHeight)
    }

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    // ── NORMAL layout (tall + medium, art centered top) ──────────
    Item {
        id: normalLayout
        anchors.fill: parent

        // Art area — top, shrinks to leave room for controls
        Item {
            id: artArea
            anchors.horizontalCenter: parent.horizontalCenter
            width: nowPlaying.showLyricsInArtArea && !theme.isDesktop
                   ? parent.width
                   : nowPlaying.artSize
            height: nowPlaying.showLyricsInArtArea && !theme.isDesktop
                    ? metadataBlock.y - 8
                    : nowPlaying.artSize

            // Center art vertically in the space above metadataBlock
            y: nowPlaying.showLyricsInArtArea && !theme.isDesktop
               ? 0
               : Math.max(8, (metadataBlock.y - nowPlaying.artSize) / 2)

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle {
                id: coverArtBlock
                anchors.fill: parent
                radius: 14
                color: nowPlaying.surfaceColor
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
                    font.pixelSize: nowPlaying.artSize * 0.28
                    color: nowPlaying.mutedText
                    visible: theme.coverArtSource === ""
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !theme.isDesktop
                    onClicked: nowPlaying.showLyricsInArtArea = true
                }
            }

            Lyrics {
                anchors.fill: parent
                theme: nowPlaying.theme
                player: nowPlaying.player
                overlayMode: true
                artMode: false
                visible: nowPlaying.showLyricsInArtArea && !theme.isDesktop
                onCloseRequested: nowPlaying.showLyricsInArtArea = false
            }
        }

        // Metadata — anchored up from quick access bar
        Column {
            id: metadataBlock
            anchors.bottom: quickAccessBar.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            width: parent.width - nowPlaying.sidePad * 2

            Text {
                text: player.trackTitle !== "" ? player.trackTitle : "No track loaded"
                font.pixelSize: nowPlaying.isMedium ? 15 : 17
                font.weight: Font.Bold
                color: nowPlaying.primaryText
                anchors.horizontalCenter: parent.horizontalCenter
                elide: Text.ElideRight
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: player.trackArtist
                font.pixelSize: nowPlaying.isMedium ? 12 : 13
                color: nowPlaying.secondaryText
                anchors.horizontalCenter: parent.horizontalCenter
                elide: Text.ElideRight
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: player.trackAlbum
                font.pixelSize: nowPlaying.isMedium ? 10 : 11
                color: nowPlaying.mutedText
                anchors.horizontalCenter: parent.horizontalCenter
                elide: Text.ElideRight
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Quick access bar — anchored up from controls
        Item {
            id: quickAccessBar
            anchors.bottom: controlsBlock.top
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: nowPlaying.sidePad
            anchors.rightMargin: nowPlaying.sidePad
            height: 44

            ListView {
                id: quickAccessList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 4
                clip: true

                model: [
                    { icon: player.isFavorite ? "♥" : "♡", label: "Favorite",     active: player.isFavorite,            onTapped: function() { player.toggleFavorite() } },
                    { icon: "ℹ",                             label: "Song info",    active: false,                         onTapped: function() { quickAccessSongInfo.open(player.trackPath) } },
                    { icon: "🎵",                            label: "Lyrics",       active: nowPlaying.showLyricsInArtArea, onTapped: function() { if (!theme.isDesktop) nowPlaying.showLyricsInArtArea = !nowPlaying.showLyricsInArtArea } },
                    { icon: "≡+",                            label: "Add to playlist", active: false,                      onTapped: function() { player.requestAddToPlaylist(player.trackPath) } },
                    { icon: "⏹",                             label: "Stop after",   active: player.stopAfterCurrent,       onTapped: function() { player.toggleStopAfterCurrent() } },
                    { icon: "⇌",                             label: "A-B Repeat",   active: false,                         onTapped: function() { /* placeholder */ } }
                ]

                delegate: Item {
                    width: 60
                    height: quickAccessList.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 8
                        color: modelData.active
                               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
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

        // Song info dialog
        SongInfo {
            id: quickAccessSongInfo
            theme: nowPlaying.theme
        }

        // Controls — anchored to bottom
        Column {
            id: controlsBlock
            anchors.bottom: parent.bottom
            anchors.bottomMargin: nowPlaying.isMedium ? 16 : 24
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: nowPlaying.isMedium ? 8 : 12
            width: parent.width - nowPlaying.sidePad * 2

            Item {
                width: parent.width
                height: 16

                Text {
                    text: theme.formatTime(player.position)
                    font.pixelSize: 12
                    color: nowPlaying.mutedText
                    anchors.left: parent.left
                }

                Text {
                    text: theme.formatTime(player.duration)
                    font.pixelSize: 12
                    color: nowPlaying.mutedText
                    anchors.right: parent.right
                }
            }

            Slider {
                width: parent.width
                from: 0
                to: Math.max(player.duration, 1)
                value: player.position
                onMoved: player.seekTo(value)
            }

            Row {
                spacing: 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width

                Repeater {
                    model: [
                        { icon: "⏮", action: "previous" },
                        { icon: "⏪", action: "rewind"   },
                        { icon: player.isPlaying ? "⏸" : "▶", action: "playpause" },
                        { icon: "⏩", action: "forward"  },
                        { icon: "⏭", action: "next"     }
                    ]

                    delegate: Item {
                        width: controlsBlock.width / 5
                        height: nowPlaying.isMedium ? 40 : 48

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: nowPlaying.isMedium ? 20 : 24
                            color: {
                                if (modelData.action === "previous" && !player.hasPrevious && player.position <= 3000) return nowPlaying.mutedText
                                if (modelData.action === "next" && !player.hasNext) return nowPlaying.mutedText
                                if (modelData.action === "playpause") return nowPlaying.accentColor
                                return nowPlaying.primaryText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.action === "previous") player.playPrevious()
                                    else if (modelData.action === "rewind") player.seekTo(Math.max(0, player.position - 10000))
                                    else if (modelData.action === "playpause") player.isPlaying ? player.pause() : player.play()
                                    else if (modelData.action === "forward") player.seekTo(Math.min(player.duration, player.position + 10000))
                                    else if (modelData.action === "next") player.playNext()
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width

                Item {
                    width: parent.width / 3
                    height: nowPlaying.isMedium ? 28 : 36

                    Text {
                        anchors.centerIn: parent
                        text: "🔀"
                        font.pixelSize: nowPlaying.isMedium ? 16 : 20
                        color: player.isShuffled ? nowPlaying.accentColor : nowPlaying.mutedText

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.toggleShuffle()
                        }
                    }
                }

                Item {
                    width: parent.width / 3
                    height: nowPlaying.isMedium ? 28 : 36

                    Text {
                        anchors.centerIn: parent
                        text: player.repeatMode === 2 ? "🔂" : "🔁"
                        font.pixelSize: nowPlaying.isMedium ? 16 : 20
                        color: player.repeatMode === 0 ? nowPlaying.mutedText : nowPlaying.accentColor

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.cycleRepeatMode()
                        }
                    }
                }

                Item {
                    width: parent.width / 3
                    height: nowPlaying.isMedium ? 28 : 36

                    Text {
                        anchors.centerIn: parent
                        text: "⏹"
                        font.pixelSize: nowPlaying.isMedium ? 16 : 20
                        color: player.stopAfterCurrent ? nowPlaying.accentColor : nowPlaying.mutedText

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.toggleStopAfterCurrent()
                        }

                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: nowPlaying.accentColor
                            visible: player.stopAfterCurrent
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: "🔈"
                    font.pixelSize: 16
                    color: nowPlaying.mutedText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    width: parent.width - 52
                    from: 0.0
                    to: 1.0
                    value: player.volume
                    onMoved: player.setVolume(value)
                }

                Text {
                    text: "🔊"
                    font.pixelSize: 16
                    color: nowPlaying.mutedText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}