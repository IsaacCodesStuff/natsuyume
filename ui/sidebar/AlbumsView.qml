import QtQuick
import QtQuick.Controls
import "albums"
import "../"

Item {
    id: albumsView

    property var theme: null
    property string selectedAlbum: ""
    property var    albumTracks:   []
    property string searchQuery:   ""

    readonly property var albumSortOptions: [
        { label: "Name",         value: 0 },
        { label: "Artist",       value: 1 },
        { label: "Album Artist", value: 2 },
        { label: "Year",         value: 3 },
        { label: "Song Count",   value: 4 },
        { label: "Duration",     value: 5 },
        { label: "Composer",     value: 6 },
        { label: "Date Added",   value: 7 }
    ]

    readonly property var trackSortOptions: [
        { label: "Track №",      value: 0  },
        { label: "Title",        value: 1  },
        { label: "Artist",       value: 2  },
        { label: "Album Artist", value: 3  },
        { label: "Year",         value: 4  },
        { label: "Duration",     value: 5  },
        { label: "Genre",        value: 6  },
        { label: "Composer",     value: 7  },
        { label: "Filename",     value: 8  },
        { label: "Date Added",   value: 9  },
        { label: "Last Played",  value: 10 },
        { label: "Play Count",   value: 11 }
    ]

    function formatTotalDuration(tracks) {
        let totalMs = 0
        for (let i = 0; i < tracks.length; i++)
            totalMs += tracks[i].duration

        let totalSeconds = Math.floor(totalMs / 1000)
        let hours = Math.floor(totalSeconds / 3600)
        let minutes = Math.floor((totalSeconds % 3600) / 60)
        let seconds = totalSeconds % 60
        let mm = (hours > 0 && minutes < 10) ? "0" + minutes : minutes
        let ss = seconds < 10 ? "0" + seconds : seconds
        return hours > 0 ? (hours + ":" + mm + ":" + ss) : (minutes + ":" + ss)
    }

    // ── Top bar: search + sort + settings ───────────────────────
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: 36
        visible: albumsView.selectedAlbum === ""

        Row {
            anchors.fill: parent
            spacing: 8

            Rectangle {
                width: parent.width - 36 - 36 - 16
                height: 36
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: "⌕"
                        font.pixelSize: 16
                        color: albumsView.theme.mutedText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        width: parent.width - 26
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: albumsView.theme.primaryText
                        placeholderText: "Search an album..."
                        placeholderTextColor: albumsView.theme.mutedText
                        background: Item {}
                        onTextChanged: albumsView.searchQuery = text.toLowerCase()
                    }
                }
            }

            SortBar {
                width: 36
                height: 36
                iconOnly: true
                theme: albumsView.theme
                sortOptions: albumsView.albumSortOptions
                currentSort: player.albumSort
                currentAscending: player.albumSortAscending

                onSortChanged: function(value, label) {
                    player.setAlbumSort(value)
                }
                onAscendingChanged: function(ascending) {
                    player.setAlbumSortAscending(ascending)
                }
            }

            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "⚙"
                    font.pixelSize: 16
                    color: albumsView.theme.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Stage 2: album view options dialog — not yet implemented
                    }
                }
            }
        }
    }

    // ── Album grid ─────────────────────────────────────────────
    AlbumGrid {
        id: grid
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        anchors.margins: 8
        visible: albumsView.selectedAlbum === ""
        theme: albumsView.theme
        searchQuery: albumsView.searchQuery

        onAlbumSelected: function(albumName) {
            albumsView.selectedAlbum = albumName
            albumsView.albumTracks   = player.tracksForAlbum(albumName)
        }
    }

    // ── Album track list ───────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: albumsView.selectedAlbum !== ""

        // Header
        Rectangle {
            id: albumHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            color: Qt.rgba(0, 0, 0, 0.15)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "‹"
                    font.pixelSize: 24
                    color: albumsView.theme.primaryText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: albumsView.selectedAlbum = ""
                    }
                }

                Text {
                    text: albumsView.selectedAlbum
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: albumsView.theme.primaryText
                    elide: Text.ElideRight
                    width: parent.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ── Artist chip row ──────────────────────────────────────
        property var albumArtists: {
            let seen = []
            for (let i = 0; i < albumsView.albumTracks.length; i++) {
                let a = albumsView.albumTracks[i].artist
                if (a && seen.indexOf(a) === -1) seen.push(a)
            }
            return seen
        }

        Text {
            id: artistsLabel
            anchors.top: albumHeader.bottom
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 12
            text: "Artists"
            font.pixelSize: 11
            color: albumsView.theme.mutedText
        }

        Row {
            id: artistChips
            anchors.top: artistsLabel.bottom
            anchors.left: parent.left
            anchors.topMargin: 6
            anchors.leftMargin: 12
            spacing: 8

            Repeater {
                model: parent.parent.albumArtists

                Rectangle {
                    height: 36
                    width: chipText.implicitWidth + 24
                    radius: 8
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 12
                        color: albumsView.theme.primaryText
                    }
                }
            }
        }

        // ── Summary line ──────────────────────────────────────────
        Text {
            id: summaryLine
            anchors.top: artistChips.bottom
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 12
            text: albumsView.albumTracks.length + " songs · " +
                  albumsView.formatTotalDuration(albumsView.albumTracks)
            font.pixelSize: 11
            color: albumsView.theme.mutedText
        }

        // ── Action bar — shuffle | sort ────────────────────────────
        Item {
            id: actionBar
            anchors.top: summaryLine.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            height: 36

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "⤨"
                        font.pixelSize: 15
                        color: albumsView.theme.mutedText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let paths = albumsView.albumTracks.map(t => t.path)
                            player.openFilesInNewQueue(paths, albumsView.selectedAlbum, true)
                        }
                    }
                }

                SortBar {
                    width: 36
                    height: 36
                    iconOnly: true
                    theme: albumsView.theme
                    sortOptions: albumsView.trackSortOptions
                    currentSort: player.trackSort
                    currentAscending: player.trackSortAscending

                    onSortChanged: function(value, label) {
                        player.setTrackSort(value)
                        albumsView.albumTracks = player.tracksForAlbum(albumsView.selectedAlbum)
                    }
                    onAscendingChanged: function(ascending) {
                        player.setTrackSortAscending(ascending)
                        albumsView.albumTracks = player.tracksForAlbum(albumsView.selectedAlbum)
                    }
                }

                Rectangle {
                    id: albumOverflowBtn
                    width: 36
                    height: 36
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "⋯"
                        font.pixelSize: 16
                        color: albumsView.theme.mutedText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: albumOverflowMenu.open()
                    }
                }
            }
        }

        ContextMenu {
            id: albumOverflowMenu
            theme: albumsView.theme
            title: "Album options"
            actions: [
                { label: "Share songs",     icon: "🔗", disabled: true },
                { label: "Export as .M3U",  icon: "⬇",  disabled: true },
                { label: "Select multiple", icon: "☑",  disabled: true }
            ]
        }

        // Track list
        AlbumTrackList {
            id: trackList
            anchors.top: actionBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            theme: albumsView.theme
            albumName: albumsView.selectedAlbum
            tracks: albumsView.albumTracks

            onBackRequested: albumsView.selectedAlbum = ""
            onTrackListUpdated: function(tracks) {
                albumsView.albumTracks = tracks
            }
        }
    }
}