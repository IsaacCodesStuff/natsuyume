import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: playlistTrackList

    required property var    theme
    required property int    playlistId
    required property string playlistName
    required property var    tracks

    signal trackListUpdated

    property bool editMode: false

    property int  dragFromIndex:    -1
    property int  dragToIndex:      -1
    property bool dragProxyVisible: false
    property real dragProxyY:       0

    // ── Auto-scroll state ──────────────────────────────────────
    property real  autoScrollSpeed: 0
    readonly property int  edgeZone:       50
    readonly property real maxScrollSpeed: 14

    Timer {
        id: autoScrollTimer
        interval: 16
        repeat: true
        running: playlistTrackList.autoScrollSpeed !== 0 && playlistTrackList.dragFromIndex >= 0
        onTriggered: {
            let newY = listView.contentY + playlistTrackList.autoScrollSpeed
            newY = Math.max(0, Math.min(newY, listView.contentHeight - listView.height))
            listView.contentY = newY
        }
    }

    function updateAutoScroll(localY) {
        if (localY < edgeZone) {
            let depth = (edgeZone - localY) / edgeZone
            autoScrollSpeed = -maxScrollSpeed * depth
        } else if (localY > listView.height - edgeZone) {
            let depth = (localY - (listView.height - edgeZone)) / edgeZone
            autoScrollSpeed = maxScrollSpeed * depth
        } else {
            autoScrollSpeed = 0
        }
    }


    // ── Song info dialog ───────────────────────────────────────
    SongInfo {
        id: songInfoDialog
        theme: playlistTrackList.theme
    }

    function trackActions(path) {
        let actions = [
            {
                label: "Play",
                icon: "▶",
                onTriggered: function() {
                    player.openPlaylistInNewQueue(playlistTrackList.playlistId,
                                                 playlistTrackList.playlistName)
                    player.jumpToTrackByPath(path)
                }
            },
            {
                label: "Add to queue",
                icon: "+",
                onTriggered: function() { player.requestAddToQueue(path) }
            },
            {
                label: "Add to currently playing queue",
                icon: "⏵+",
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

        // Only show Remove for real playlists, not virtual ones
        if (playlistTrackList.playlistId >= 0) {
            actions.push({
                label: "Remove from playlist",
                icon: "✕",
                destructive: true,
                onTriggered: function() {
                    player.removeTrackFromPlaylist(playlistTrackList.playlistId, path)
                    playlistTrackList.trackListUpdated()
                }
            })
        }

        return actions
    }

    // ── Edit mode hint ─────────────────────────────────────────
    Rectangle {
        id: editBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        color: "transparent"
        visible: playlistTrackList.editMode

        Text {
            anchors.centerIn: parent
            text: "Drag tracks to reorder"
            font.pixelSize: 11
            color: playlistTrackList.theme.mutedText
        }
    }

    // ── Track list ─────────────────────────────────────────────
    ListView {
        id: listView
        anchors.top: playlistTrackList.editMode ? editBar.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4
        clip: true
        model: playlistTrackList.tracks
        interactive: playlistTrackList.dragFromIndex < 0

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: delegateItem
            width: listView.width
            height: 56

            property var  ptl:        playlistTrackList
            property bool isDragging: delegateItem.ptl.dragFromIndex === index

            opacity: isDragging ? 0.5 : 1.0
            scale:   isDragging ? 1.02 : 1.0

            Behavior on opacity { NumberAnimation { duration: 100 } }
            Behavior on scale   { NumberAnimation { duration: 100 } }

            TrackRow {
                anchors.fill: parent
                theme:          playlistTrackList.theme
                title:          modelData.title
                artist:         modelData.artist
                album:          modelData.album
                path:           modelData.path
                duration:       modelData.duration
                showAlbum:      true
                showDragHandle: playlistTrackList.editMode
                isCurrentTrack: false
                isPlaying:      false
                actions:        playlistTrackList.trackActions(modelData.path)

                onTapped: {
                    if (!playlistTrackList.editMode) {
                        player.openPlaylistInNewQueue(playlistTrackList.playlistId,
                                                     playlistTrackList.playlistName)
                        player.jumpToTrackByPath(modelData.path)
                    }
                }

                onDragHandlePressed: function(globalY) {
                    delegateItem.ptl.dragFromIndex    = index
                    delegateItem.ptl.dragToIndex      = index
                    delegateItem.ptl.dragProxyY       = globalY - listView.y - 28
                    delegateItem.ptl.dragProxyVisible = true
                }

                onDragHandleMoved: function(globalY) {
                    let localY = globalY - listView.y - delegateItem.ptl.y
                    delegateItem.ptl.dragProxyY = localY - 28
                    let listY = localY - 8
                    let newIndex = Math.floor((listY + listView.contentY) / 60)
                    newIndex = Math.max(0, Math.min(newIndex,
                        delegateItem.ptl.tracks.length - 1))
                    delegateItem.ptl.dragToIndex = newIndex

                    let viewportY = globalY - listView.mapToItem(null, 0, 0).y
                    delegateItem.ptl.updateAutoScroll(viewportY)
                }

                onDragHandleReleased: {
                    if (delegateItem.ptl.dragFromIndex >= 0 &&
                        delegateItem.ptl.dragToIndex >= 0 &&
                        delegateItem.ptl.dragFromIndex !== delegateItem.ptl.dragToIndex) {
                        player.moveTrackInPlaylist(
                            delegateItem.ptl.playlistId,
                            delegateItem.ptl.dragFromIndex,
                            delegateItem.ptl.dragToIndex)
                        delegateItem.ptl.trackListUpdated()
                    }
                    delegateItem.ptl.dragProxyVisible = false
                    delegateItem.ptl.dragFromIndex    = -1
                    delegateItem.ptl.dragToIndex      = -1
                    delegateItem.ptl.autoScrollSpeed  = 0
                }
            }
        }
    }

    // ── Drag proxy ─────────────────────────────────────────────
    Rectangle {
        x: 8
        y: playlistTrackList.dragProxyY
        width: listView.width
        height: 56
        radius: 8
        visible: playlistTrackList.dragProxyVisible
        opacity: 0.85
        z: 20

        color: Qt.rgba(
            playlistTrackList.theme.accentColor.r,
            playlistTrackList.theme.accentColor.g,
            playlistTrackList.theme.accentColor.b, 0.25)
        border.color: Qt.rgba(
            playlistTrackList.theme.accentColor.r,
            playlistTrackList.theme.accentColor.g,
            playlistTrackList.theme.accentColor.b, 0.5)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: {
                let idx = dragFromIndex
                let t = tracks
                if (idx >= 0 && t && idx < t.length)
                    return t[idx].title
                return ""
            }
            font.pixelSize: 12
            color: theme.primaryText
            elide: Text.ElideRight
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
        }
    }

    function endDrag() {
        dragProxyVisible = false
        dragFromIndex    = -1
        dragToIndex      = -1
        autoScrollSpeed  = 0
    }
}