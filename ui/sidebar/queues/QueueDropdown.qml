import QtQuick

Item {
    id: queueDropdown

    required property var theme

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property int    renamingIndex: -1
    property string renameBuffer:  ""

    signal closeRequested

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: queueDropdown.bgColor
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            // ── Header ─────────────────────────────────────────
            Item {
                width: parent.width
                height: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Queues"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: queueDropdown.mutedText
                    leftPadding: 4
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    font.pixelSize: 12
                    color: queueDropdown.mutedText

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: queueDropdown.closeRequested()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // ── Queue list ─────────────────────────────────────
            ListView {
                id: queueList
                width: parent.width
                height: parent.height - 48
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

                    // Cache root reference for use inside nested items
                    property var dropdown: queueDropdown

                    property bool isRenaming: queueDropdown.renamingIndex === index

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Item {
                            width: parent.width - 64
                            height: parent.height

                            // Normal label
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: player.queueNames[index]
                                font.pixelSize: 12
                                color: index === player.activeQueueIndex
                                       ? queueDropdown.accentColor
                                       : queueDropdown.primaryText
                                elide: Text.ElideRight
                                visible: !queueItem.isRenaming
                            }

                            // Inline rename field
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

                        // Spacer
                        Item { width: 8; height: 1 }

                        // Pencil button
                        Item {
                            width: 24
                            height: parent.height

                            Text {
                                text: "✎"
                                font.pixelSize: 13
                                color: queueDropdown.mutedText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !queueItem.isRenaming

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        queueItem.dropdown.renamingIndex = index
                                        queueItem.dropdown.renameBuffer = player.queueNames[index]
                                    }
                                }
                            }
                        }

                        // Spacer
                        Item { width: 8; height: 1 }

                        // Remove button
                        Item {
                            width: 24
                            height: parent.height

                            Text {
                                text: "✕"
                                font.pixelSize: 11
                                color: queueDropdown.mutedText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !queueItem.isRenaming

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: player.closeQueue(index)
                                }
                            }
                        }
                    }

                    // Tap to switch queue
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 52
                        cursorShape: Qt.PointingHandCursor
                        enabled: !queueItem.isRenaming
                        onClicked: {
                            player.switchToQueue(index)
                            queueDropdown.closeRequested()
                        }
                    }
                }
            }
        }
    }
}