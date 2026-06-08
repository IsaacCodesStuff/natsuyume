import QtQuick
import QtQuick.Controls

Item {
    id: albumGrid

    required property var    theme
    required property string searchQuery

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    signal albumSelected(string albumName)

    property var filteredAlbums: {
        if (searchQuery === "")
            return player.allAlbums
        return player.allAlbums.filter(a =>
            a.toLowerCase().includes(searchQuery)
        )
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: albumGrid.albumSelected(modelData)
                }
            }
        }
    }
}