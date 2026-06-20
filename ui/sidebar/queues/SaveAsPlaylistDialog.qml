import QtQuick
import QtQuick.Controls

Item {
    id: saveAsPlaylistDialog

    required property var theme

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    function open() { popup.open() }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        background: Rectangle {
            radius: 14
            color: saveAsPlaylistDialog.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        onOpened: {
            saveNameField.text = player.queueCount > 0
                ? player.queueNames[player.activeQueueIndex]
                : ""
            saveNameField.forceActiveFocus()
        }

        contentItem: Column {
            width: popup.width
            spacing: 4
            topPadding: 16
            bottomPadding: 12
            leftPadding: 12
            rightPadding: 12

            Text {
                width: popup.width - 24
                height: 24
                text: "Save queue as playlist"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: saveAsPlaylistDialog.primaryText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item { width: popup.width; height: 8 }

            Rectangle {
                width: popup.width - 24
                height: 40
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                TextField {
                    id: saveNameField
                    anchors.fill: parent
                    anchors.margins: 4
                    font.pixelSize: 13
                    color: saveAsPlaylistDialog.primaryText
                    placeholderText: "Playlist name"
                    placeholderTextColor: saveAsPlaylistDialog.mutedText
                    background: Item {}
                    onAccepted: doSave()
                }
            }

            Item { width: popup.width; height: 8 }

            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8
                color: Qt.rgba(
                    saveAsPlaylistDialog.accentColor.r,
                    saveAsPlaylistDialog.accentColor.g,
                    saveAsPlaylistDialog.accentColor.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: saveAsPlaylistDialog.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doSave()
                }
            }

            Item { width: popup.width; height: 4 }

            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: saveAsPlaylistDialog.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: popup.close()
                }
            }
        }
    }

    function doSave() {
        let name = saveNameField.text.trim()
        if (name.length === 0) return
        player.saveQueueAsPlaylist(name)
        popup.close()
    }
}