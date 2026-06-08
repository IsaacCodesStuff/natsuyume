import QtQuick

Item {
    id: queueTrackList

    required property var  theme
    required property bool dimmed

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    signal dismissRequested

    ListView {
        id: trackList
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        clip: true
        model: player.trackList

        delegate: Rectangle {
            width: trackList.width
            height: 48
            radius: 8
            color: index === player.trackIndex
                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
                   : Qt.rgba(1, 1, 1, 0.04)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: index === player.trackIndex
                          ? (player.isPlaying ? "▶" : "⏸")
                          : ""
                    font.pixelSize: 10
                    color: queueTrackList.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 22
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
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: player.jumpToTrack(index)
            }
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