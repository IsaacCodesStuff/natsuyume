import QtQuick
import QtQuick.Controls

Item {
    id: queueDropdown

    required property var theme

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property int    renamingIndex: -1
    property string renameBuffer:  ""

    function open()  { popup.open()  }
    function close() { popup.close() }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        height: Math.min(player.queueCount * 52 + 64, 400)
        padding: 0

        background: Rectangle {
            radius: 12
            color: queueDropdown.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
            width: popup.width
            spacing: 4
            topPadding: 8
            bottomPadding: 8
            leftPadding: 8
            rightPadding: 8

            // Header
            Item {
                width: popup.width - 16
                height: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Queues"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: queueDropdown.mutedText
                    leftPadding: 4
                }
            }

            Rectangle {
                width: popup.width - 16
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Queue list
            ListView {
                id: queueList
                width: popup.width - 16
                height: popup.height - 64
                spacing: 4
                clip: false
                model: player.queueCount

                delegate: Rectangle {
                    id: queueItem
                    width: queueList.width
                    height: 44
                    radius: 8
                    color: index === player.activeQueueIndex
                           ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                           : Qt.rgba(1, 1, 1, 0.04)

                    property var dropdown: queueDropdown
                    property bool isRenaming: dropdown.renamingIndex === index

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 0

                        Item {
                            width: parent.width - (index === player.activeQueueIndex && !queueItem.isRenaming ? 96 : 64)
                            height: parent.height

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: player.queueNames[index]
                                font.pixelSize: 12
                                color: index === player.activeQueueIndex
                                       ? queueItem.dropdown.accentColor
                                       : queueItem.dropdown.primaryText
                                elide: Text.ElideRight
                                visible: !queueItem.isRenaming
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 28
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: queueItem.isRenaming

                                TextInput {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: queueItem.dropdown.renameBuffer
                                    font.pixelSize: 12
                                    color: queueItem.dropdown.primaryText
                                    selectByMouse: true
                                    focus: queueItem.isRenaming

                                    onTextChanged: queueItem.dropdown.renameBuffer = text

                                    onAccepted: {
                                        if (queueItem.dropdown.renameBuffer.trim().length > 0)
                                            player.renameQueue(index, queueItem.dropdown.renameBuffer.trim())
                                        queueItem.dropdown.renamingIndex = -1
                                    }

                                    onActiveFocusChanged: {
                                        if (!activeFocus && queueItem.isRenaming) {
                                            if (queueItem.dropdown.renameBuffer.trim().length > 0)
                                                player.renameQueue(index, queueItem.dropdown.renameBuffer.trim())
                                            queueItem.dropdown.renamingIndex = -1
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 8; height: 1 }

                        // Save as playlist button (active queue only)
                        Item {
                            width: 24
                            height: parent.height
                            visible: index === player.activeQueueIndex && !queueItem.isRenaming

                        Text {
                            text: "💾"
                            font.pixelSize: 13
                            color: queueItem.dropdown.mutedText
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                queueDropdown.close()
                                saveAsPlaylistDialog.queueIndex = index
                                saveAsPlaylistDialog.open()
                                }
                            }
                        }

                        Item { width: 8; height: 1 }

                        // Pencil button
                        Item {
                            width: 24
                            height: parent.height

                            Text {
                                text: "✎"
                                font.pixelSize: 13
                                color: queueItem.dropdown.mutedText
                                anchors.centerIn: parent
                                visible: !queueItem.isRenaming
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    queueItem.dropdown.renamingIndex = index
                                    queueItem.dropdown.renameBuffer = player.queueNames[index]
                                }
                            }
                        }

                        Item { width: 8; height: 1 }

                        // Remove button
                        Item {
                            width: 24
                            height: parent.height

                            Text {
                                text: "✕"
                                font.pixelSize: 11
                                color: queueItem.dropdown.mutedText
                                anchors.centerIn: parent
                                visible: !queueItem.isRenaming
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: player.closeQueue(index)
                            }
                        }
                    }

                    // Tap to switch queue
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 64
                        cursorShape: Qt.PointingHandCursor
                        enabled: !queueItem.isRenaming
                        onClicked: {
                            player.switchToQueue(index)
                            queueDropdown.close()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: saveAsPlaylistDialog
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        property int queueIndex: -1

        background: Rectangle {
            radius: 14
            color: queueDropdown.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        onOpened: {
            saveNameField.text = saveAsPlaylistDialog.queueIndex >= 0
                ? player.queueNames[saveAsPlaylistDialog.queueIndex]
                : ""
            saveNameField.forceActiveFocus()
        }

        contentItem: Column {
            width: saveAsPlaylistDialog.width
            spacing: 4
            topPadding: 16
            bottomPadding: 12
            leftPadding: 12
            rightPadding: 12

            Text {
                width: saveAsPlaylistDialog.width - 24
                height: 24
                text: "Save queue as playlist"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: queueDropdown.primaryText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item { width: saveAsPlaylistDialog.width; height: 8 }

            Rectangle {
                width: saveAsPlaylistDialog.width - 24
                height: 40
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                TextField {
                    id: saveNameField
                    anchors.fill: parent
                    anchors.margins: 4
                    font.pixelSize: 13
                    color: queueDropdown.primaryText
                    placeholderText: "Playlist name"
                    placeholderTextColor: queueDropdown.mutedText
                    background: Item {}
                    onAccepted: doSave()
                }
            }

            Item { width: saveAsPlaylistDialog.width; height: 8 }

            Rectangle {
                width: saveAsPlaylistDialog.width - 24
                height: 44
                radius: 8
                color: Qt.rgba(
                    queueDropdown.accentColor.r,
                    queueDropdown.accentColor.g,
                    queueDropdown.accentColor.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: queueDropdown.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doSave()
                }
            }

            Item { width: saveAsPlaylistDialog.width; height: 4 }

            Rectangle {
                width: saveAsPlaylistDialog.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: queueDropdown.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: saveAsPlaylistDialog.close()
                }
            }
        }
    }

    function doSave() {
        let name = saveNameField.text.trim()
        if (name.length === 0) return
        player.saveQueueAsPlaylist(name)
        saveAsPlaylistDialog.close()
    }
}