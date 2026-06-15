import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: artistTrackList

    required property var    theme
    required property string artistName
    required property var    tracks

    signal backRequested

    // ── Album filter state ─────────────────────────────────────
    property string selectedAlbum: ""  // "" = All albums

    property var filteredTracks: {
        if (selectedAlbum === "")
            return tracks
        return tracks.filter(t => t.album === selectedAlbum)
    }

    property var artistAlbums: artistName !== "" ? player.albumsForArtist(artistName) : []

    // ── Stats ──────────────────────────────────────────────────
    readonly property int totalSongs: tracks.length
    readonly property int totalAlbums: artistAlbums.length
    readonly property real totalDuration: {
        let ms = 0
        for (let t of tracks) ms += Number(t.duration) || 0
        return ms
    }

    function formatDuration(ms) {
        let totalSecs = Math.floor(ms / 1000)
        let h = Math.floor(totalSecs / 3600)
        let m = Math.floor((totalSecs % 3600) / 60)
        let s = totalSecs % 60
        if (h > 0)
            return h + ":" + String(m).padStart(2,"0") + ":" + String(s).padStart(2,"0")
        return m + ":" + String(s).padStart(2,"0")
    }

    // ── Song info dialog ───────────────────────────────────────
    SongInfo {
        id: songInfoDialog
        theme: artistTrackList.theme
    }

    function trackActions(path) {
        return [
            {
                label: "Play",
                icon: "▶",
                onTriggered: function() {
                    let paths = artistTrackList.filteredTracks.map(t => t.path)
                    player.openFilesInNewQueue(paths, artistTrackList.artistName)
                    player.jumpToTrackByPath(path)
                }
            },
            {
                label: "Add to queue",
                icon: "+",
                onTriggered: function() { player.addTrackToQueue(path) }
            },
            {
                label: "Add to playlist",
                icon: "🎵",
                onTriggered: function() { player.requestAddToPlaylist(path) }
            },
            {
                label: "Song info",
                icon: "ℹ",
                onTriggered: function() { songInfoDialog.open(path) }
            }
        ]
    }

    // ── Album chip strip ───────────────────────────────────────
    Item {
        id: chipStrip
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 72

        ListView {
            id: chipList
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            leftMargin: 8
            rightMargin: 8

            model: [""].concat(artistTrackList.artistAlbums)

            delegate: Item {
                width: chip.width
                height: chipList.height

                readonly property bool isAll:      modelData === ""
                readonly property bool isSelected: artistTrackList.selectedAlbum === modelData

                Rectangle {
                    id: chip
                    height: parent.height
                    width: isAll ? allLabel.implicitWidth + 24 : chipContent.implicitWidth + 16
                    radius: 8
                    color: isSelected
                           ? Qt.rgba(artistTrackList.theme.accentColor.r,
                                     artistTrackList.theme.accentColor.g,
                                     artistTrackList.theme.accentColor.b, 0.18)
                           : Qt.rgba(1, 1, 1, 0.06)

                    // "All albums" chip
                    Text {
                        id: allLabel
                        anchors.centerIn: parent
                        visible: isAll
                        text: "All albums"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: isSelected
                               ? artistTrackList.theme.accentColor
                               : artistTrackList.theme.primaryText
                    }

                    // Album chip with cover + name
                    Row {
                        id: chipContent
                        visible: !isAll
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        spacing: 6

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 4
                            color: Qt.rgba(1, 1, 1, 0.08)
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: "image://albumcovers/" + encodeURIComponent(modelData)
                                fillMode: Image.PreserveAspectCrop
                            }
                        }

                        Text {
                            width: Math.min(implicitWidth, 100)
                            text: modelData
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: isSelected
                                   ? artistTrackList.theme.accentColor
                                   : artistTrackList.theme.primaryText
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: Text.NoWrap
                        }
                    }

                    // Selection underline
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: 1
                        color: artistTrackList.theme.accentColor
                        visible: isSelected
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: artistTrackList.selectedAlbum = modelData
                    }
                }
            }
        }
    }

    // ── Stats line ─────────────────────────────────────────────
    Item {
        id: statsBar
        anchors.top: chipStrip.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 28

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: artistTrackList.totalAlbums + " albums  ·  "
                    + artistTrackList.totalSongs + " songs  ·  "
                    + artistTrackList.formatDuration(artistTrackList.totalDuration)
                font.pixelSize: 11
                color: artistTrackList.theme.mutedText
            }
        }

        // Shuffle + Sort
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "⇀"
                font.pixelSize: 18
                color: artistTrackList.theme.mutedText
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let paths = artistTrackList.filteredTracks.map(t => t.path)
                        player.openFilesInNewQueue(paths, artistTrackList.artistName)
                        player.toggleShuffle()
                    }
                }
            }
        }
    }

    // ── Track list ─────────────────────────────────────────────
    ListView {
        id: listView
        anchors.top: statsBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4
        clip: true
        model: artistTrackList.filteredTracks

        delegate: Item {
            width: listView.width
            height: 56

            TrackRow {
                anchors.fill: parent
                theme:          artistTrackList.theme
                title:          modelData.title
                artist:         modelData.artist
                album:          modelData.album
                path:           modelData.path
                duration:       modelData.duration
                showAlbum:      true
                showDragHandle: false
                isCurrentTrack: false
                isPlaying:      false
                actions:        artistTrackList.trackActions(modelData.path)

                onTapped: {
                    let paths = artistTrackList.filteredTracks.map(t => t.path)
                    player.openFilesInNewQueue(paths, artistTrackList.artistName)
                    player.jumpToTrackByPath(modelData.path)
                }
            }
        }
    }
}