import QtQuick
import "../.."

Item {
    id: queueTrackList

    required property var  theme

    property int  dragFromIndex:    -1
    property int  dragToIndex:      -1
    property bool dragProxyVisible: false
    property real dragProxyY:       0

    function trackActions(idx, path, title) {
        return [
            {
                label: "Play",
                icon: "▶",
                onTriggered: function() { player.jumpToTrack(idx) }
            },
            {
                label: "Stop after this song",
                icon: "⏹",
                disabled: true
            },
            {
                label: "Song info",
                icon: "ℹ",
                onTriggered: function() { songInfoDialog.open(path) }
            },
            {
                label: "Add to playlist",
                icon: "🎵",
                onTriggered: function() { player.requestAddToPlaylist(path) }
            },
            {
                label: "Save queue as playlist",
                icon: "💾",
                disabled: true
            },
            {
                label: "Remove from queue",
                icon: "✕",
                destructive: true,
                onTriggered: function() { player.removeTrackAt(idx) }
            }
        ]
    }

    SongInfo {
        id: songInfoDialog
        theme: queueTrackList.theme
    }

    ListView {
        id: trackList
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        clip: true
        model: player.trackList
        interactive: queueTrackList.dragFromIndex < 0

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: delegateRoot
            width: trackList.width
            height: 56

            property var  root:       queueTrackList
            property bool isDragging: root.dragFromIndex === index

            opacity: isDragging ? 0.5 : 1.0
            scale:   isDragging ? 1.02 : 1.0

            Behavior on opacity { NumberAnimation { duration: 100 } }
            Behavior on scale   { NumberAnimation { duration: 100 } }

            TrackRow {
                anchors.fill: parent
                theme:          queueTrackList.theme
                title:          modelData.title
                artist:         modelData.artist
                album:          modelData.album
                path:           modelData.path
                duration:       modelData.duration
                showAlbum:      true
                showDragHandle: true
                isCurrentTrack: index === player.trackIndex
                isPlaying:      index === player.trackIndex && player.isPlaying
                actions:        queueTrackList.trackActions(
                                    index, modelData.path, modelData.title)

                onTapped: player.jumpToTrack(index)

                onDragHandlePressed: function(globalY) {
                    delegateRoot.root.dragFromIndex    = index
                    delegateRoot.root.dragToIndex      = index
                    delegateRoot.root.dragProxyY       = globalY - trackList.y - 28
                    delegateRoot.root.dragProxyVisible = true
                }

                onDragHandleMoved: function(globalY) {
                    let localY = globalY - trackList.y - queueTrackList.y
                    delegateRoot.root.dragProxyY = localY - 28

                    let listY = localY - 8
                    let newIndex = Math.floor(listY / 60)
                    newIndex = Math.max(0, Math.min(newIndex,
                        player.trackList.length - 1))
                    delegateRoot.root.dragToIndex = newIndex
                }

                onDragHandleReleased: {
                    if (delegateRoot.root.dragFromIndex >= 0 &&
                        delegateRoot.root.dragToIndex >= 0 &&
                        delegateRoot.root.dragFromIndex !== delegateRoot.root.dragToIndex) {
                        player.moveTrack(
                            delegateRoot.root.dragFromIndex,
                            delegateRoot.root.dragToIndex)
                    }
                    delegateRoot.root.dragProxyVisible = false
                    delegateRoot.root.dragFromIndex    = -1
                    delegateRoot.root.dragToIndex      = -1
                }
            }
        }
    }

    // Drag proxy
    Rectangle {
        x: 8
        y: queueTrackList.dragProxyY
        width: trackList.width
        height: 56
        radius: 8
        visible: queueTrackList.dragProxyVisible
        opacity: 0.85
        z: 20

        color: Qt.rgba(
            queueTrackList.theme.accentColor.r,
            queueTrackList.theme.accentColor.g,
            queueTrackList.theme.accentColor.b,
            0.25
        )
        border.color: Qt.rgba(
            queueTrackList.theme.accentColor.r,
            queueTrackList.theme.accentColor.g,
            queueTrackList.theme.accentColor.b,
            0.5
        )
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: {
                let idx = queueTrackList.dragFromIndex
                let list = player.trackList
                if (idx >= 0 && list && idx < list.length)
                    return list[idx].title
                return ""
            }
            font.pixelSize: 12
            color: queueTrackList.theme.primaryText
            elide: Text.ElideRight
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
        }
    }
}