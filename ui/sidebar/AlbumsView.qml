import QtQuick
import QtQuick.Controls
import "albums"

Item {
    id: albumsView

    required property var theme

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

    // ── Search bar ─────────────────────────────────────────────
    Rectangle {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: 36
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.06)
        visible: albumsView.selectedAlbum === ""

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
                placeholderText: "Search albums..."
                placeholderTextColor: albumsView.theme.mutedText
                background: Item {}
                onTextChanged: albumsView.searchQuery = text.toLowerCase()
            }
        }
    }

    // ── Album sort bar ─────────────────────────────────────────
    SortBar {
        id: albumSortBar
        anchors.top: searchBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        visible: albumsView.selectedAlbum === ""
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

    // ── Album grid ─────────────────────────────────────────────
    AlbumGrid {
        id: grid
        anchors.top: albumSortBar.bottom
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

        // Action bar — Play All | Sort
        Item {
            id: actionBar
            anchors.top: albumHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            height: 36

            // Play All
            Rectangle {
                anchors.left: parent.left
                width: parent.width / 2 - 4
                height: parent.height
                radius: 8
                color: Qt.rgba(
                    albumsView.theme.accentColor.r,
                    albumsView.theme.accentColor.g,
                    albumsView.theme.accentColor.b, 0.15)

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "▶"
                        font.pixelSize: 12
                        color: albumsView.theme.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Play All"
                        font.pixelSize: 12
                        color: albumsView.theme.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (player.isAlbumActiveQueue(albumsView.selectedAlbum)) {
                            player.jumpToTrack(0)
                        } else {
                            let paths = albumsView.albumTracks.map(t => t.path)
                            player.openFilesInNewQueue(paths, albumsView.selectedAlbum)
                        }
                    }
                }
            }

            // Track sort bar
            SortBar {
                id: trackSortBar
                anchors.right: parent.right
                width: parent.width / 2 - 4
                height: parent.height
                theme: albumsView.theme
                sortOptions: albumsView.trackSortOptions
                currentSort: player.trackSort
                currentAscending: player.trackSortAscending

                onSortChanged: function(value, label) {
                    player.setTrackSort(value)
                    albumsView.albumTracks = player.tracksForAlbum(
                        albumsView.selectedAlbum)
                }

                onAscendingChanged: function(ascending) {
                    player.setTrackSortAscending(ascending)
                    albumsView.albumTracks = player.tracksForAlbum(
                        albumsView.selectedAlbum)
                }
            }
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