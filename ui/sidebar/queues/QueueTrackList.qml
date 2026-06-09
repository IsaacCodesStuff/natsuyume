import QtQuick
import "../.."

Item {
    id: queueTrackList

    required property var  theme
    required property bool dimmed

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    signal dismissRequested

    // Drag state
    property int dragFromIndex: -1
    property int dragToIndex:   -1
    property bool  dragProxyVisible: false
    property real  dragProxyY:       0

    function trackActions(idx, title) {
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
                icon: "+",
                disabled: true
            },
            {
                label: "Save queue as playlist",
                icon: "🎵",
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

    // Context menu instance
    ContextMenu {
        id: trackContextMenu
        theme: queueTrackList.theme
    }

    SongInfo {
        id: songInfoDialog
        theme: queueTrackList.theme  // or albumTrackList.theme
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
            height: 48

            property var root: queueTrackList  // cache root reference
            property bool isDragging: root.dragFromIndex === index

            // Visual card
            Rectangle {
                id: card
                width: parent.width
                height: parent.height
                radius: 8
                color: index === player.trackIndex
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
                       : Qt.rgba(1, 1, 1, 0.04)
                opacity: delegateRoot.isDragging ? 0.5 : 1.0
                scale:   delegateRoot.isDragging ? 1.02 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 100 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // Drag handle
                    Text {
                        text: "⠿"
                        font.pixelSize: 16
                        color: queueTrackList.mutedText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16

                        MouseArea {
                            id: dragHandle
                            anchors.fill: parent
                            cursorShape: Qt.SizeVerCursor

                            onPressed: function(mouse) {
                                let mapped = mapToItem(delegateRoot.root, 0, mouse.y)
                                delegateRoot.root.dragFromIndex    = index
                                delegateRoot.root.dragToIndex      = index
                                delegateRoot.root.dragProxyY       = mapped.y - 24
                                delegateRoot.root.dragProxyVisible = true
                            }

                            onPositionChanged: function(mouse) {
                                let mapped = mapToItem(delegateRoot.root, 0, mouse.y)
                                delegateRoot.root.dragProxyY = mapped.y - 24

                                let listY = mapped.y - trackList.y - 8
                                let newIndex = Math.floor(listY / 52)
                                newIndex = Math.max(0, Math.min(newIndex, player.trackList.length - 1))
                                delegateRoot.root.dragToIndex = newIndex
                            }

                            onReleased: {
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

                    // Track thumbnail
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.06)
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            source: {
                                let path = modelData.path
                                if (!path) return ""
                                return "image://trackcovers/" + encodeURIComponent(path)
                            }
                            layer.enabled: true
                            layer.effect: null
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♪"
                            font.pixelSize: 14
                            color: queueTrackList.mutedText
                            visible: thumbImage.status !== Image.Ready
                        }
                    }

                    // Track info
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 92
                        spacing: 2

                        Text {
                            text: modelData.title
                            font.pixelSize: 12
                            font.weight: index === player.trackIndex
                                         ? Font.Medium : Font.Normal
                            color: index === player.trackIndex
                                   ? queueTrackList.accentColor
                                   : queueTrackList.primaryText
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: modelData.artist
                            font.pixelSize: 10
                            color: queueTrackList.mutedText
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Options button
                    Item {
                        width: 32
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "⋮"
                            font.pixelSize: 16
                            color: queueTrackList.mutedText
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                trackContextMenu.title   = modelData.title
                                trackContextMenu.actions = queueTrackList.trackActions(index, modelData.title)
                                trackContextMenu.open()
                            }
                        }
                    }
                }

                // Tap to play — covers card but leaves drag handle alone
                MouseArea {
                    anchors.fill: parent
                    anchors.leftMargin: 26
                    anchors.rightMargin: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player.jumpToTrack(index)
                    onPressAndHold: {
                        trackContextMenu.title = modelData.title
                        trackContextMenu.actions = queueTrackList.trackActions(index, modelData.title)
                        trackContextMenu.open()
                    }
                }
            }
        }
    }

    // Drag proxy — the floating card while dragging
    Rectangle {
        id: dragProxy
        x: 8
        y: queueTrackList.dragProxyY
        width: trackList.width
        height: 48
        radius: 8
        visible: queueTrackList.dragProxyVisible
        opacity: 0.85
        z: 20

        color: Qt.rgba(
            queueTrackList.accentColor.r,
            queueTrackList.accentColor.g,
            queueTrackList.accentColor.b,
            0.25
        )
        border.color: Qt.rgba(
            queueTrackList.accentColor.r,
            queueTrackList.accentColor.g,
            queueTrackList.accentColor.b,
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
            color: queueTrackList.primaryText
            elide: Text.ElideRight
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Dim overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        visible: queueTrackList.dimmed
        opacity: queueTrackList.dimmed ? 1.0 : 0.0
        z: 1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    // Dismiss on outside click
    MouseArea {
        anchors.fill: parent
        enabled: queueTrackList.dimmed
        z: 1
        onClicked: queueTrackList.dismissRequested()
    }
}