import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: albumTrackList

    required property var    theme
    required property string albumName
    required property var    tracks

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property bool trackSortOpen: false

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

    signal backRequested
    signal trackListUpdated(var tracks)
    signal sortRequested(int value, string label)
    signal ascendingToggled(bool ascending)

    // Context menu
    ContextMenu {
        id: trackContextMenu
        theme: albumTrackList.theme
    }

    SongInfo {
        id: songInfoDialog
        theme: albumTrackList.theme
    }

    function trackActions(path, title) {
        return [
            {
                label: "Play",
                icon: "▶",
                onTriggered: function() {
                    if (player.isAlbumActiveQueue(albumTrackList.albumName)) {
                        player.jumpToTrackByPath(path)
                    } else {
                        let paths = albumTrackList.tracks.map(t => t.path)
                        player.openFilesInNewQueue(paths, albumTrackList.albumName)
                        player.jumpToTrackByPath(path)
                    }
                }
            },
            {
                label: "Add to queue",
                icon: "+",
                onTriggered: function() {
                    player.addTrackToQueue(path)
                }
            },
            {
                label: "Add to playlist",
                icon: "🎵",
                disabled: true
            },
            {
                label: "Song info",
                icon: "ℹ",
                onTriggered: function() { songInfoDialog.open(path) }
            }
        ]
    }

    // Header
    Rectangle {
        id: header
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
                color: albumTrackList.primaryText
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: albumTrackList.backRequested()
                }
            }

            Text {
                text: albumTrackList.albumName
                font.pixelSize: 13
                font.weight: Font.Medium
                color: albumTrackList.primaryText
                elide: Text.ElideRight
                width: parent.width - 36
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Action bar
    Item {
        id: actionBar
        anchors.top: header.bottom
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
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "▶"
                    font.pixelSize: 12
                    color: albumTrackList.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Play All"
                    font.pixelSize: 12
                    color: albumTrackList.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (player.isAlbumActiveQueue(albumTrackList.albumName)) {
                        player.jumpToTrack(0)
                    } else {
                        let paths = albumTrackList.tracks.map(t => t.path)
                        player.openFilesInNewQueue(paths, albumTrackList.albumName)
                    }
                }
            }
        }

        // Track sort bar
        TrackSortBar {
            anchors.right: parent.right
            width: parent.width / 2 - 4
            height: parent.height
            theme: albumTrackList.theme
            sortOpen: albumTrackList.trackSortOpen

            onSortOpenChanged: albumTrackList.trackSortOpen = sortOpen

            onSortRequested: function(value, label) {
                albumTrackList.sortRequested(value, label)
                player.setTrackSort(value)
                albumTrackList.trackListUpdated(
                    player.tracksForAlbum(albumTrackList.albumName))
            }

            onAscendingToggled: function(ascending) {
                albumTrackList.ascendingToggled(ascending)
                player.setTrackSortAscending(ascending)
                albumTrackList.trackListUpdated(
                    player.tracksForAlbum(albumTrackList.albumName))
            }
        }
    }

    // Track list
    ListView {
        id: listView
        anchors.top: actionBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4
        clip: true
        model: albumTrackList.tracks

        delegate: Rectangle {
            id: trackDelegate
            width: listView.width
            height: 48
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.04)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 0
                spacing: 8

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    spacing: 2

                    Text {
                        text: modelData.title
                        font.pixelSize: 12
                        color: albumTrackList.primaryText
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: modelData.artist
                        font.pixelSize: 10
                        color: albumTrackList.mutedText
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Divider
                Rectangle {
                    width: 1
                    height: parent.height * 0.6
                    color: Qt.rgba(1, 1, 1, 0.08)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Options button
                Item {
                    width: 32
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "⋮"
                        font.pixelSize: 16
                        color: albumTrackList.mutedText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            trackContextMenu.title   = modelData.title
                            trackContextMenu.actions = albumTrackList.trackActions(
                                modelData.path, modelData.title)
                            trackContextMenu.open()
                        }
                    }
                }
            }

            // Tap to play
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 32
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        trackContextMenu.title   = modelData.title
                        trackContextMenu.actions = albumTrackList.trackActions(
                            modelData.path, modelData.title)
                        trackContextMenu.open()
                    } else {
                        if (player.isAlbumActiveQueue(albumTrackList.albumName)) {
                            player.jumpToTrackByPath(modelData.path)
                        } else {
                            let paths = albumTrackList.tracks.map(t => t.path)
                            player.openFilesInNewQueue(paths, albumTrackList.albumName)
                            player.jumpToTrackByPath(modelData.path)
                        }
                    }
                }

                onPressAndHold: {
                    trackContextMenu.title   = modelData.title
                    trackContextMenu.actions = albumTrackList.trackActions(
                        modelData.path, modelData.title)
                    trackContextMenu.open()
                }
            }
        }
    }
}