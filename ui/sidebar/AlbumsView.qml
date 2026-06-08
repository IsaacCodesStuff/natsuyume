import QtQuick
import QtQuick.Controls
import "albums"

Item {
    id: albumsView

    required property var theme

    property string selectedAlbum: ""
    property var    albumTracks:   []
    property string searchQuery:   ""

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
    AlbumSortBar {
        id: albumSortBar
        anchors.top: searchBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        visible: albumsView.selectedAlbum === ""
        theme: albumsView.theme

        onSortRequested: function(value, label) {
            player.setAlbumSort(value)
            sortLabel = label
        }

        onAscendingToggled: function(ascending) {
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
    AlbumTrackList {
        id: trackList
        anchors.fill: parent
        visible: albumsView.selectedAlbum !== ""
        theme: albumsView.theme
        albumName: albumsView.selectedAlbum
        tracks: albumsView.albumTracks

        onBackRequested: albumsView.selectedAlbum = ""

        onTrackListUpdated: function(tracks) {
            albumsView.albumTracks = tracks
        }
    }

    // ── Album sort dropdown (rendered on top of everything) ────
    Item {
        visible: albumSortBar.sortOpen && albumsView.selectedAlbum === ""
        anchors.top: albumSortBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        height: albumSortBar.sortOptions.length * 40 + 48
        z: 10

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: albumsView.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Item {
                    width: parent.width
                    height: 36

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "↑ Asc",  value: true  },
                                { label: "↓ Desc", value: false }
                            ]

                            Rectangle {
                                width:  72
                                height: 28
                                radius: 6
                                color: player.albumSortAscending === modelData.value
                                       ? Qt.rgba(
                                             albumsView.theme.accentColor.r,
                                             albumsView.theme.accentColor.g,
                                             albumsView.theme.accentColor.b, 0.2)
                                       : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.pixelSize: 11
                                    color: player.albumSortAscending === modelData.value
                                           ? albumsView.theme.accentColor
                                           : albumsView.theme.mutedText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        albumSortBar.ascendingToggled(modelData.value)
                                        albumSortBar.sortOpen = false
                                    }
                                }
                            }
                        }
                    }
                }

                ListView {
                    width: parent.width
                    height: parent.height - 44
                    clip: true
                    spacing: 2
                    model: albumSortBar.sortOptions

                    delegate: Rectangle {
                        width: parent.width
                        height: 36
                        radius: 6
                        color: player.albumSort === modelData.value
                               ? Qt.rgba(
                                     albumsView.theme.accentColor.r,
                                     albumsView.theme.accentColor.g,
                                     albumsView.theme.accentColor.b, 0.15)
                               : Qt.rgba(1, 1, 1, 0.04)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData.label
                            font.pixelSize: 12
                            color: player.albumSort === modelData.value
                                   ? albumsView.theme.accentColor
                                   : albumsView.theme.primaryText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            text: "✓"
                            font.pixelSize: 11
                            color: albumsView.theme.accentColor
                            visible: player.albumSort === modelData.value
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                albumSortBar.sortRequested(modelData.value, modelData.label)
                                albumSortBar.sortOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Track sort dropdown (rendered on top of everything) ────
    Item {
        visible: trackList.trackSortOpen && albumsView.selectedAlbum !== ""
        anchors.top: parent.top
        anchors.topMargin: 44 + 36 + 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        height: trackList.trackSortOptions.length * 40 + 48
        z: 10

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: albumsView.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Item {
                    width: parent.width
                    height: 36

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "↑ Asc",  value: true  },
                                { label: "↓ Desc", value: false }
                            ]

                            Rectangle {
                                width:  72
                                height: 28
                                radius: 6
                                color: player.trackSortAscending === modelData.value
                                       ? Qt.rgba(
                                             albumsView.theme.accentColor.r,
                                             albumsView.theme.accentColor.g,
                                             albumsView.theme.accentColor.b, 0.2)
                                       : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.pixelSize: 11
                                    color: player.trackSortAscending === modelData.value
                                           ? albumsView.theme.accentColor
                                           : albumsView.theme.mutedText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        trackList.ascendingToggled(modelData.value)
                                        trackList.trackSortOpen = false
                                    }
                                }
                            }
                        }
                    }
                }

                ListView {
                    width: parent.width
                    height: parent.height - 44
                    clip: true
                    spacing: 2
                    model: trackList.trackSortOptions

                    delegate: Rectangle {
                        width: parent.width
                        height: 36
                        radius: 6
                        color: player.trackSort === modelData.value
                               ? Qt.rgba(
                                     albumsView.theme.accentColor.r,
                                     albumsView.theme.accentColor.g,
                                     albumsView.theme.accentColor.b, 0.15)
                               : Qt.rgba(1, 1, 1, 0.04)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData.label
                            font.pixelSize: 12
                            color: player.trackSort === modelData.value
                                   ? albumsView.theme.accentColor
                                   : albumsView.theme.primaryText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            text: "✓"
                            font.pixelSize: 11
                            color: albumsView.theme.accentColor
                            visible: player.trackSort === modelData.value
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                trackList.sortRequested(modelData.value, modelData.label)
                                trackList.trackSortOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}