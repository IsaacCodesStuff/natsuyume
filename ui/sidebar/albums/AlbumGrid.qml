import QtQuick
import QtQuick.Controls
import natsuyume_player

Item {
    id: albumGrid

    required property var    theme
    required property string searchQuery

    readonly property color primaryText:  theme.primaryText
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    signal albumSelected(string albumName)

    property var filteredAlbums: {
        if (searchQuery === "")
            return player.allAlbums
        return player.allAlbums.filter(a =>
            a.toLowerCase().includes(searchQuery)
        )
    }

    // Context menu
    ContextMenu {
        id: albumContextMenu
        theme: albumGrid.theme
    }

    function albumActions(albumName) {
        return [
            {
                label: "Play album",
                icon: "▶",
                onTriggered: function() {
                    let tracks = player.tracksForAlbum(albumName)
                    let paths = tracks.map(t => t.path)
                    player.openFilesInNewQueue(paths, albumName)
                }
            },
            {
                label: "Add to queue",
                icon: "+",
                onTriggered: function() {
                    player.requestAddAlbumToQueue(albumName)
                }
            },
            {
                label: "Add to currently playing queue",
                icon: "⏵+",
                onTriggered: function() {
                    player.addAlbumToQueue(albumName)
                }
            },
            {
                label: "Add to playlist",
                icon: "🎵",
                onTriggered: function() { player.requestAddAlbumToPlaylist(albumName) }            },
            {
                label: "Advanced shuffle",
                icon: "🔀",
                disabled: true
            }
        ]
    }

    GridView {
        id: grid
        anchors.fill: parent
        cellWidth:  Math.floor(grid.width / 2)
        cellHeight: cellWidth + 48
        clip: true
        model: albumGrid.filteredAlbums

        delegate: Item {
            width:  grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.05)
                clip: true

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        width:  parent.width
                        height: parent.width
                        color:  Qt.rgba(1, 1, 1, 0.08)

                        AlbumCover {
                            anchors.fill: parent
                            albumName: modelData
                            theme: albumGrid.theme
                        }
                    }

                    Item {
                        width: parent.width
                        height: 48

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: albumGrid.primaryText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            albumContextMenu.title   = modelData
                            albumContextMenu.actions = albumGrid.albumActions(modelData)
                            albumContextMenu.open()
                        } else {
                            albumGrid.albumSelected(modelData)
                        }
                    }

                    onPressAndHold: {
                        albumContextMenu.title   = modelData
                        albumContextMenu.actions = albumGrid.albumActions(modelData)
                        albumContextMenu.open()
                    }
                }
            }
        }
    }
}