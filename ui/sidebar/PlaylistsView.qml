import QtQuick
import QtQuick.Controls
import "playlists"
import "../"

Item {
    id: playlistsView

    required property var theme

    property int    selectedPlaylistId:   -1
    property string selectedPlaylistName: ""
    property var    playlistTracks:       []
    property bool playlistEditMode: false

    readonly property var trackSortOptions: [
        { label: "Manual",       value: 0  },
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

    Connections {
        target: player
        function onPlaylistsChanged() {
            if (playlistsView.selectedPlaylistId !== -1) {
                playlistsView.playlistTracks = player.tracksForPlaylist(
                    playlistsView.selectedPlaylistId)
            }
        }
    }

    // ── Playlist context menu ──────────────────────────────────
    ContextMenu {
        id: playlistContextMenu
        theme: playlistsView.theme
    }

    function playlistActions(playlistId, playlistName) {
        return [
            {
                label: "Play",
                icon: "▶",
                onTriggered: function() {
                    player.openPlaylistInNewQueue(playlistId, playlistName)
                }
            },
            {
                label: "Rename",
                icon: "✎",
                onTriggered: function() {
                    renameDialog.targetId   = playlistId
                    renameDialog.targetName = playlistName
                    renameDialog.open()
                }
            },
            {
                label: "Delete",
                icon: "✕",
                destructive: true,
                onTriggered: function() {
                    player.deletePlaylist(playlistId)
                    if (playlistsView.selectedPlaylistId === playlistId) {
                        playlistsView.selectedPlaylistId   = -1
                        playlistsView.selectedPlaylistName = ""
                        playlistsView.playlistTracks       = []
                    }
                }
            }
        ]
    }

    // ── Rename dialog ──────────────────────────────────────────
    Popup {
        id: renameDialog
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        property int    targetId:   -1
        property string targetName: ""

        background: Rectangle {
            radius: 14
            color: playlistsView.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        onOpened: {
            renameField.text = renameDialog.targetName
            renameField.forceActiveFocus()
        }

        contentItem: Column {
            width: renameDialog.width
            spacing: 4
            topPadding: 16
            bottomPadding: 12
            leftPadding: 12
            rightPadding: 12

            Text {
                width: renameDialog.width - 24
                height: 24
                text: renameDialog.targetName
                font.pixelSize: 13
                font.weight: Font.Medium
                color: playlistsView.theme.primaryText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Item { width: renameDialog.width; height: 8 }

            Rectangle {
                width: renameDialog.width - 24
                height: 40
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                TextField {
                    id: renameField
                    anchors.fill: parent
                    anchors.margins: 4
                    font.pixelSize: 13
                    color: playlistsView.theme.primaryText
                    placeholderText: "New name"
                    placeholderTextColor: playlistsView.theme.mutedText
                    background: Item {}
                    onAccepted: doRename()
                }
            }

            Item { width: renameDialog.width; height: 8 }

            Rectangle {
                width: renameDialog.width - 24
                height: 44
                radius: 8
                color: Qt.rgba(
                    playlistsView.theme.accentColor.r,
                    playlistsView.theme.accentColor.g,
                    playlistsView.theme.accentColor.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "Rename"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: playlistsView.theme.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doRename()
                }
            }

            Item { width: renameDialog.width; height: 4 }

            Rectangle {
                width: renameDialog.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: playlistsView.theme.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: renameDialog.close()
                }
            }
        }
    }

    function doRename() {
        let name = renameField.text.trim()
        if (name.length === 0) return
        player.renamePlaylist(renameDialog.targetId, name)
        if (playlistsView.selectedPlaylistId === renameDialog.targetId)
            playlistsView.selectedPlaylistName = name
        renameDialog.close()
    }

    // ── New playlist button ────────────────────────────────────
    Rectangle {
        id: newPlaylistBtn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: 44
        radius: 8
        visible: playlistsView.selectedPlaylistId === -1
        color: Qt.rgba(
            playlistsView.theme.accentColor.r,
            playlistsView.theme.accentColor.g,
            playlistsView.theme.accentColor.b, 0.12)

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "+"
                font.pixelSize: 20
                color: playlistsView.theme.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "New playlist"
                font.pixelSize: 13
                color: playlistsView.theme.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: newPlaylistDialog.open()
        }
    }

    Popup {
        id: newPlaylistDialog
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        background: Rectangle {
            radius: 14
            color: playlistsView.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.6) }

        onOpened: {
            newPlaylistField.text = ""
            newPlaylistField.forceActiveFocus()
        }

        contentItem: Column {
            width: newPlaylistDialog.width
            spacing: 4
            topPadding: 16
            bottomPadding: 12
            leftPadding: 12
            rightPadding: 12

            Text {
                width: newPlaylistDialog.width - 24
                height: 24
                text: "New playlist"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: playlistsView.theme.primaryText
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: newPlaylistDialog.width; height: 8 }

            Rectangle {
                width: newPlaylistDialog.width - 24
                height: 40
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                TextField {
                    id: newPlaylistField
                    anchors.fill: parent
                    anchors.margins: 4
                    font.pixelSize: 13
                    color: playlistsView.theme.primaryText
                    placeholderText: "Playlist name"
                    placeholderTextColor: playlistsView.theme.mutedText
                    background: Item {}
                    onAccepted: doCreatePlaylist()
                }
            }

            Item { width: newPlaylistDialog.width; height: 8 }

            Rectangle {
                width: newPlaylistDialog.width - 24
                height: 44
                radius: 8
                color: Qt.rgba(
                    playlistsView.theme.accentColor.r,
                    playlistsView.theme.accentColor.g,
                    playlistsView.theme.accentColor.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "Create"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: playlistsView.theme.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doCreatePlaylist()
                }
            }

            Item { width: newPlaylistDialog.width; height: 4 }

            Rectangle {
                width: newPlaylistDialog.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: playlistsView.theme.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: newPlaylistDialog.close()
                }
            }
        }
    }

    function doCreatePlaylist() {
        let name = newPlaylistField.text.trim()
        if (name.length === 0) return
        player.createPlaylist(name)
        newPlaylistDialog.close()
    }

    // ── Playlist list ──────────────────────────────────────────
    ListView {
        id: playlistList
        anchors.top: newPlaylistBtn.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        clip: true
        visible: playlistsView.selectedPlaylistId === -1
        model: player.allPlaylists

        delegate: Item {
            width: playlistList.width
            height: 48

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 8
                color: "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: modelData.name
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: playlistsView.theme.primaryText
                    elide: Text.ElideRight
                    width: parent.width - 24
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            playlistContextMenu.title   = modelData.name
                            playlistContextMenu.actions = playlistsView.playlistActions(
                                modelData.id, modelData.name)
                            playlistContextMenu.open()
                        } else {
                            playlistsView.selectedPlaylistId   = modelData.id
                            playlistsView.selectedPlaylistName = modelData.name
                            playlistsView.playlistTracks       = player.tracksForPlaylist(modelData.id)
                        }
                    }

                    onPressAndHold: {
                        playlistContextMenu.title   = modelData.name
                        playlistContextMenu.actions = playlistsView.playlistActions(
                            modelData.id, modelData.name)
                        playlistContextMenu.open()
                    }
                }
            }
        }
    }

    // ── Playlist detail ────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: playlistsView.selectedPlaylistId !== -1

        // Header
        Rectangle {
            id: playlistHeader
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

                // Back button
                Text {
                    text: "‹"
                    font.pixelSize: 24
                    color: playlistsView.theme.primaryText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            playlistsView.selectedPlaylistId   = -1
                            playlistsView.selectedPlaylistName = ""
                            playlistsView.playlistTracks       = []
                            playlistsView.playlistEditMode     = false  // ← add this
                        }
                    }
                }

                // Playlist name
                Text {
                    text: playlistsView.selectedPlaylistName
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: playlistsView.theme.primaryText
                    elide: Text.ElideRight
                    width: parent.width - 80
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Edit mode toggle
                Text {
                    text: playlistsView.playlistEditMode ? "Done" : "✎"
                    font.pixelSize: playlistsView.playlistEditMode ? 12 : 16
                    color: playlistsView.playlistEditMode
                           ? playlistsView.theme.accentColor
                           : playlistsView.theme.mutedText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playlistsView.playlistEditMode = !playlistsView.playlistEditMode
                    }
                }
            }
        }

        // Action bar
        Item {
            id: actionBar
            anchors.top: playlistHeader.bottom
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
                    playlistsView.theme.accentColor.r,
                    playlistsView.theme.accentColor.g,
                    playlistsView.theme.accentColor.b, 0.15)

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "▶"
                        font.pixelSize: 12
                        color: playlistsView.theme.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Play All"
                        font.pixelSize: 12
                        color: playlistsView.theme.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        player.openPlaylistInNewQueue(
                            playlistsView.selectedPlaylistId,
                            playlistsView.selectedPlaylistName)
                    }
                }
            }

            // Sort bar
            SortBar {
                id: playlistSortBar
                anchors.right: parent.right
                width: parent.width / 2 - 4
                height: parent.height
                theme: playlistsView.theme
                sortOptions: playlistsView.trackSortOptions
                currentSort: player.playlistSort
                currentAscending: player.playlistSortAscending

                onSortChanged: function(value, label) {
                    player.setPlaylistSort(value)
                    if (playlistsView.selectedPlaylistId !== -1) {
                        player.sortPlaylist(playlistsView.selectedPlaylistId)
                        playlistsView.playlistTracks = player.tracksForPlaylist(
                            playlistsView.selectedPlaylistId)
                    }
                }

                onAscendingChanged: function(ascending) {
                    player.setPlaylistSortAscending(ascending)
                    if (playlistsView.selectedPlaylistId !== -1) {
                        player.sortPlaylist(playlistsView.selectedPlaylistId)
                        playlistsView.playlistTracks = player.tracksForPlaylist(
                            playlistsView.selectedPlaylistId)
                    }
                }
            }
        }

        // Track list
        PlaylistTrackList {
            id: trackList
            anchors.top: actionBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 8
            theme:        playlistsView.theme
            playlistId:   playlistsView.selectedPlaylistId
            playlistName: playlistsView.selectedPlaylistName
            tracks:       playlistsView.playlistTracks
            editMode:     playlistsView.playlistEditMode

            onTrackListUpdated: {
                playlistsView.playlistTracks = player.tracksForPlaylist(
                    playlistsView.selectedPlaylistId)
            }
        }
    }  // ← closes the detail Item
}      // ← closes PlaylistsView