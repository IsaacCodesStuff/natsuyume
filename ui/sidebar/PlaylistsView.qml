import QtQuick
import QtQuick.Controls
import "playlists"
import "../"

Item {
    id: playlistsView

    property var theme: null
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

    // ── All songs (virtual playlist) ────────────────────────────
    Rectangle {
        id: allSongsRow
        anchors.top: newPlaylistBtn.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        anchors.topMargin: 4
        height: 48
        radius: 8
        visible: playlistsView.selectedPlaylistId === -1
        color: "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            spacing: 10

            Text {
                text: "🎵"
                font.pixelSize: 16
                color: playlistsView.theme.primaryText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "All songs"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: playlistsView.theme.primaryText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                playlistsView.selectedPlaylistId   = -2 // Player.kAllSongsPlaylistId
                playlistsView.selectedPlaylistName = "All songs"
                playlistsView.playlistTracks       = player.tracksForPlaylist(-2)
            }
        }
    }

    Rectangle {
        id: favoritesRow
        anchors.top: allSongsRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        anchors.topMargin: 0
        height: 48
        radius: 8
        visible: playlistsView.selectedPlaylistId === -1
        color: "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            spacing: 10

            Text {
                text: "♥"
                font.pixelSize: 16
                color: playlistsView.theme.primaryText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Favorites"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: playlistsView.theme.primaryText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                playlistsView.selectedPlaylistId   = -3 // Player.kFavoritesPlaylistId
                playlistsView.selectedPlaylistName = "Favorites"
                playlistsView.playlistTracks       = player.tracksForPlaylist(-3)
            }
        }
    }

    // ── Playlist list ──────────────────────────────────────────
    ListView {
        id: playlistList
        anchors.top: favoritesRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        anchors.topMargin: 4
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
                            playlistsView.playlistEditMode     = false
                        }
                    }
                }

                // Playlist name
                Text {
                    text: playlistsView.selectedPlaylistName
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: playlistsView.theme.primaryText
                    elide: Text.ElideRight
                    width: parent.width - 60
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Gear — top right
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "⚙"
                font.pixelSize: 16
                color: playlistsView.theme.mutedText

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Stage 2: playlist view options dialog — not yet implemented
                    }
                }
            }
        }

        // ── Summary line ──────────────────────────────────────────
        Text {
            id: playlistSummary
            anchors.top: playlistHeader.bottom
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 12
            text: playlistsView.playlistTracks.length + " songs · " +
                  playlistsView.formatTotalDuration(playlistsView.playlistTracks)
            font.pixelSize: 11
            color: playlistsView.theme.mutedText
        }

        // ── Action bar — edit | shuffle | sort | overflow ──────────
        Item {
            id: actionBar
            anchors.top: playlistSummary.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            height: 36

            Row {
                anchors.right: parent.right
                spacing: 8

                // Edit toggle — hidden for virtual playlists (All songs / Favorites)
                Rectangle {
                    width: editLabel.implicitWidth + 16
                    height: 36
                    radius: 8
                    visible: playlistsView.selectedPlaylistId >= 0
                    color: playlistsView.playlistEditMode
                           ? Qt.rgba(playlistsView.theme.accentColor.r,
                                     playlistsView.theme.accentColor.g,
                                     playlistsView.theme.accentColor.b, 0.18)
                           : Qt.rgba(1, 1, 1, 0.06)

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "✎"
                            font.pixelSize: 13
                            color: playlistsView.playlistEditMode
                                   ? playlistsView.theme.accentColor
                                   : playlistsView.theme.mutedText
                        }

                        Text {
                            id: editLabel
                            text: playlistsView.playlistEditMode ? "Done" : "Edit"
                            font.pixelSize: 12
                            color: playlistsView.playlistEditMode
                                   ? playlistsView.theme.accentColor
                                   : playlistsView.theme.mutedText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playlistsView.playlistEditMode = !playlistsView.playlistEditMode
                    }
                }

                // Shuffle
                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "⤨"
                        font.pixelSize: 15
                        color: playlistsView.theme.mutedText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let paths = playlistsView.playlistTracks.map(t => t.path)
                            player.openFilesInNewQueue(paths, playlistsView.selectedPlaylistName, true)
                        }
                    }
                }

                // Sort
                SortBar {
                    width: 36
                    height: 36
                    iconOnly: true
                    theme: playlistsView.theme
                    sortOptions: playlistsView.trackSortOptions
                    currentSort: player.playlistSort
                    currentAscending: player.playlistSortAscending

                    onSortChanged: function(value, label) {
                        player.setPlaylistSort(value)
                        if (playlistsView.selectedPlaylistId >= 0) {
                            player.sortPlaylist(playlistsView.selectedPlaylistId)
                            playlistsView.playlistTracks = player.tracksForPlaylist(
                                playlistsView.selectedPlaylistId)
                        }
                    }

                    onAscendingChanged: function(ascending) {
                        player.setPlaylistSortAscending(ascending)
                        if (playlistsView.selectedPlaylistId >= 0) {
                            player.sortPlaylist(playlistsView.selectedPlaylistId)
                            playlistsView.playlistTracks = player.tracksForPlaylist(
                                playlistsView.selectedPlaylistId)
                        }
                    }
                }

                // Overflow
                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "⋯"
                        font.pixelSize: 16
                        color: playlistsView.theme.mutedText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playlistOverflowMenu.open()
                    }
                }
            }
        }

        ContextMenu {
            id: playlistOverflowMenu
            theme: playlistsView.theme
            title: "Playlist options"
            actions: [
                { label: "Share songs",     icon: "🔗", disabled: true },
                { label: "Export as .M3U",  icon: "⬇",  disabled: true },
                { label: "Select multiple", icon: "☑",  disabled: true }
            ]
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